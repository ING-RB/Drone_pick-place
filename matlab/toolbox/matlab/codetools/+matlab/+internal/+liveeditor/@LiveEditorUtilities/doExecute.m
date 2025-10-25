function executionTime = doExecute(editorId, fileName, persistOutput, isSynchronousDrawnowRequired)
    % DOEXECUTE Implementation part of execute API. For internal use only.
    
    % editorId - The editor Id of the RTC instance to execute.
    % fileName - The full file path of the file to be run.
    % persistOutput - If true, server side outputs will not be cleaned up. This includes interactive figures and variables
    % isSynchronousDrawnowRequired - Determines whether a synchronous drawnow be used.
    %
    % The prerequisites for using this function are the following:
    % The editorId must correspond to an open Live Editor client.
    % The file in the live editor must correspond to the file path provided.
    % The live editor instance must be saved, that is, not dirty.
    % The file must be a live script file.
    % This function should not be run from within another live evaluation.
    % For best results, the file should also be on the path.
    % 
    % Copyright 2024 The MathWorks, Inc.

    arguments
        editorId (1, :) char {}
        fileName char {mustBeAbsolutePath, mustBeFile}
        persistOutput (1, 1) logical = false
        isSynchronousDrawnowRequired (1, 1) logical = true
    end

    import matlab.internal.editor.*

    mustBeAllowedToRun();

    if (nargin < 3 || ~persistOutput) &&  ~matlab.internal.editor.FigureManager.useEmbeddedFigures
        cleanupObj = onCleanup(@() matlab.internal.editor.EvaluationOutputsService.cleanup(editorId));
    end

    %Generate a random 15 a-z character string to act as a unique random id
    uuid = char(matlab.internal.editor.RandGeneratorUtilities.RandomGenerator.randi([97 122], 1,15));

    sectionData = matlab.internal.editor.getSectionData(editorId);

    [~, ~, ext] = fileparts(fileName);
    if strcmpi(ext, '.mlx')
        fileModel = matlab.internal.livecode.FileModel.fromFile(fileName);
        fullFileText = fileModel.Code;
    else
        % Is Rich m
        % g3432344: Replace with Document API Text getter once it supports Rich M
        fullFileText = fileread(fileName);
    end


    if matlab.graphics.interaction.internal.isWebGraphicsDisabled
        % Turn off web graphics examples
        cleanupHandle = disableAnimationForPublishing(); %#ok<NASGU>
    end

    startLine = 1;
    endLine = numel(find(fullFileText == newline)) + 1;

    % Attach listeners to the figure manager to determine if all figures have been snapshoted
    % The drawnow below will synchronize web figures, but not GUIs.
    observer = matlab.internal.liveeditor.FigureManagerObserver();
    figureManager = matlab.internal.editor.FigureManager.getInstance();

    snapshotStartedListener = event.listener(figureManager,'FigureSnapshotStart',@(~,ed) observer.increment(ed));
    cleanupListener(1) = onCleanup(@()delete(snapshotStartedListener));

    snapshotEndedListener = event.listener(figureManager,'FigureSnapshotEnd',@(~,ed) observer.decrement(ed));
    cleanupListener(2) = onCleanup(@()delete(snapshotEndedListener));

    % Notify the client that we are about to run the file
    import matlab.internal.editor.EvaluationOutputsService

    dataToPublish = struct("requestId", uuid, "requestType", "Unrequested");
    message.publish(['/embeddedOutputs/serverStartingUnrequestedEvaluation/', editorId], dataToPublish);

    % Enable drawnow logging
    % The can be used when investigating example failures
    enableDrawnowLogging = ~isempty(getenv('ENABLE_MLX_EXAMPLES_DRAWNOW_LOGGING'));
    if enableDrawnowLogging
        st = feature('DrawnowTimeoutLogging'); 
        feature('DrawnowTimeoutLogging',true);
        cleanupObjDrawnowLogging = onCleanup(@() feature('DrawnowTimeoutLogging',st));
    end

    startTime = tic;
    builtin('_liveCodeExecutionPortal', 'matlab.internal.editor.EvaluationOutputsService.evalRegions', editorId, uuid, startLine, endLine, fullFileText, false, true, fileName, -1, '', sectionData);
    executionTime = toc(startTime);

    % In 2 minutes, change the status to true so we get out of the waitfor
    % We are using a timer object to update the status of the observer to true so that it doesn't wait forever
    timerFcn = @(~,~)(stopObserver(observer));
    timerObj = timer('StartDelay', 2*60, 'TimerFcn', timerFcn ,'ExecutionMode', 'singleShot');
    cleanObj = onCleanup(@()cleanupTimer(timerObj));

    % Wait for all figures to have been snapshoted
    start(timerObj);
    if observer.FiguresOnServer > 0
        waitfor(observer, 'Status', true)
        if observer.FiguresOnServer>0 && matlab.graphics.interaction.internal.isPublishingTest
            % Record the time so that it can be compared with the completion time
            % for drawnow (see below)
            fprintf('Timed out in waitfor at %s with %d figures outstanding', datestr(now), observer.FiguresOnServer);

            % Report the properties of all unsnapshotted figures
            observer.log;
        end
    end

    % Timer could have been cleaned up by some user code (e.g. timerfind)
    if isvalid(timerObj)
        stop(timerObj);
    end

    if isSynchronousDrawnowRequired
        drawnowForLiveEditorPublishing(editorId)
    end

    % Throw an error if it timed out and there are figures that haven't been snapshotted
    if observer.FiguresOnServer > 0
        if matlab.graphics.interaction.internal.isPublishingTest
            fprintf('drawnowForLiveEditorPublishing completed at %s\n',datestr(now));
        end
        if enableDrawnowLogging
            matlab.graphics.internal.logger('history', 'DrawnowTimeout');
        end
        error('matlab:internal:liveeditor:execute', 'The %i figure(s) did not finish snapshoting on the server.', observer.FiguresOnServer);
    end
end

function cleanupAnimationForPublishing = disableAnimationForPublishing
    % Turn off animation for publishing
    settingsObj = settings;
    settingsObj.matlab.editor.AllowFigureAnimation.TemporaryValue = 0;

    cleanupAnimationForPublishing = onCleanup(@()settingsObj.matlab.editor.AllowFigureAnimation.clearTemporaryValue);
end

function drawnowForLiveEditorPublishing(editorId)
    % preserve Live Editor's 6 minute timeout
    prevDrawnowTimeout = feature('DrawnowTimeoutSeconds', 60*6);
    cleanupDrawnowTimeout = onCleanup(@()feature('DrawnowTimeoutSeconds', prevDrawnowTimeout));

    % enable drawnow synchronization
    import matlab.internal.editor.FigureManager
    FigureManager.setDrawnowSyncEnabled(editorId, true);
    cleanupDrawnowSyncEnabled = onCleanup(@()FigureManager.setDrawnowSyncEnabled(editorId, false));

    % synchronous drawnow
    drawnow
end

function stopObserver(observer)
    % Update the observer status
    observer.Status = true;
end

function cleanupTimer(timerObj)
    % Normal timer operation stops the timer before deleting it.
    stop(timerObj);
    wait(timerObj);
    delete(timerObj);
end

function mustBeAllowedToRun()
    if ~matlab.internal.editor.EvaluationManager.isLiveScriptExecutionAllowed()
        errorId = 'matlab:internal:liveeditor:execute:executionNotAllowed';
        messageText = 'Nested Live Editor execution is not supported.';
        throwAsCaller(MException(errorId, messageText))
    end
end

function mustBeAbsolutePath(filepath)
    pathPart = fileparts(filepath);
    if isempty(pathPart)
        errorId = 'matlab:internal:liveeditor:execute:mustBeAbsolutePath';
        messageText = 'Input file path should be an absolute file path.';
        throwAsCaller(MException(errorId, messageText))
    end
end
