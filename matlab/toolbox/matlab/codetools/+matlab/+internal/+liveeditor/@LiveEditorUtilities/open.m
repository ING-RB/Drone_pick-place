function [javaRichDocument, cleanupObj, webWindow] = open(fileName, reuse,...
                                                          timeout, webWindow)
% OPEN - Opens a MATLAB Code file and returns a headless rich document

%   Copyright 2014-2024 The MathWorks, Inc.

% If there is no resuse flag defined, then set the default to false
    if nargin < 2
        reuse = false;
    end

    if nargin < 3
        timeout = [];
    end

    if nargin < 4
        webWindow = [];
    end

    import matlab.internal.liveeditor.LiveEditorUtilities
    fileName = LiveEditorUtilities.resolveFileName(fileName);

    jFile = java.io.File(fileName);
    if ~exists(jFile)
        error('matlab:internal:liveeditor:open', 'The file "%s" must exist.', fileName);
    end

    % Make sure the connector is working
    if ~connector.isRunning
        connector.ensureServiceOn();
    end

    % Make sure the Java connector is working
    if ~com.mathworks.matlabserver.connector.api.Connector.isRunning
        com.mathworks.matlabserver.connector.api.Connector.ensureServiceOn;
    end

    [javaRichDocument, cleanupObj, webWindow] = openUsingCEF(fileName, reuse, timeout, webWindow);
end

function [javaRichDocument, cleanupObj, webWindow] = openUsingCEF(fileName, reuse, timeout, webWindow)

% lock this function to prevent clear classes to clear the presisent variable
    mlock

    persistent reuseObjects
    import matlab.internal.liveeditor.LiveEditorUtilities

    if reuse
        if ~isempty(reuseObjects)
            % Check for missing or invalid webwindow
            if ~isempty(reuseObjects.webWindow) && ...
                    (~reuseObjects.webWindow.isvalid() || ...
                     ~reuseObjects.webWindow.isWindowValid())

                if ~isempty(reuseObjects.javaRichDocument)
                    % dispose(reuseObjects.javaRichDocument);
                    reuseObjects.javaRichDocument = [];
                end

                delete(reuseObjects.webWindow);
                reuseObjects.webWindow = [];

                % Cache valid input webwindow
                if ~isempty(webWindow) && ...
                        webWindow.isvalid() && ...
                        webWindow.isWindowValid()
                    reuseObjects.webWindow = webWindow;
                end
            end

            if ~isempty(reuseObjects.webWindow)
                % Use cached webwindow
                webWindow = reuseObjects.webWindow;
                if ~isempty(reuseObjects.javaRichDocument)
                    % Use cached document
                    javaRichDocument = reuseObjects.javaRichDocument;
                else
                    % Create and cache new document, use cached webwindow
                    [javaRichDocument, webWindow] = ...
                        LiveEditorUtilities.createDocument(timeout,webWindow);
                end
            else
                % No cached webwindow
                if ~isempty(reuseObjects.javaRichDocument)
                    % Use cached document, create and cache new webwindow
                    javaRichDocument = reuseObjects.javaRichDocument;
                    webpath = char(javaRichDocument.getWebPath());
                    url = connector.getUrl(webpath);
                    webWindow = matlab.internal.cef.webwindow(url);
                    % Use a wider webwindow to prevent figures from shrinking when running the script
                    % and remove horizontal scrollbar from the elements like live tasks.
                    webWindow.Position = [0 0 1300 768];
                else
                    % Create and cache new webwindow and document
                    [javaRichDocument, webWindow] = ...
                        LiveEditorUtilities.createDocument(timeout);
                end
            end
        else
            % Nothing cached, create new webwindow and document, without caching
            % If webWindow is empty, the webWindow will be created in createDocument
            % If it isn't empty, then it will be used and returned
            [javaRichDocument, webWindow] = ...
                LiveEditorUtilities.createDocument(timeout,webWindow);
        end
        reuseObjects.javaRichDocument = javaRichDocument;
        reuseObjects.webWindow = webWindow;

        % Return an empty cleanup so that these objects are not destroyed
        cleanupObj = [];
    else
        % Do not reuse
        [javaRichDocument, webWindow] = LiveEditorUtilities.createDocument(timeout);
        cleanupObj.javaRichDocumentCleanup = onCleanup(@() dispose(javaRichDocument));
        cleanupObj.webWindowCleanup = onCleanup(@() delete(webWindow));
    end

    % g2387426 - Printing an error when MATLAB window exits. If a JS timeout
    % occured, check if this message got printed in the logs. If it did,
    % webwindow has probably crashed.
    webWindow.MATLABWindowExitedCallback = @(event, data) onMATLABWindowExit(data);

    file = java.io.File(fileName);

    isMLX = com.mathworks.services.mlx.MlxFileUtils.isMlxFile(file.getAbsolutePath());

    % Load the content
    if isMLX
        opcPackage = com.mathworks.services.mlx.MlxFileUtils.read(file);
    else
        opcPackage = com.mathworks.publishparser.PublishParser.convertMToRichScript(file);
    end

    content = com.mathworks.mde.liveeditor.widget.rtc.RichDocumentBackingStore.convertToMap(opcPackage);

    % java heap errors occasionally occur without this hack
    t = tic;
    while getPercentHeapFree() < 10
        if toc(t) > 30
            error(['low free heap: ' num2str(getPercentHeapFree()) '%'])
        end
        java.lang.System.gc(); % ask java to free some memory
        matlab.internal.yield; % process callbacks and yield this thread
    end

    try
        javaRichDocument.setContentAsync(content);
        pollForReadyDocument(javaRichDocument);
    catch err
        % Display error in publishing environment
        if ~isempty(getenv('IS_PUBLISHING')) 
            disp(err.getReport());
        end

        % Handle time out exception by creating diagnostics.
        handleTimeOutException(webWindow);

        % Clean up the document and the browser object. When the caller retries, a new webWindow and
        % richDocument will be created.
        webWindow.delete();
        javaRichDocument.dispose();
        if reuse
            reuseObjects = [];
        end
        rethrow(err);
    end

end

function handleTimeOutException(webWindow)
% Handle the Timeout Exception.

    timeout = 60; % 1 minute

    % g1927724 - Running a simple JS command before calling into
    % MessageService to see if JS command can be executed.
    webWindow.executeJS('console.log("Executing JS command")', timeout);

    % Log: Determine the current message service state. This also allows us
    % to know whether the browser is disconnected.
    result = webWindow.executeJS('require(["mw-messageservice/MessageService"], function (MS) {ms = MS.messageService});ms._currentState', timeout);
    warning('matlab:internal:liveeditor:timeoutreportingmessageservicestate', ['The current message service state: ' result]);

    % Log: Any JS error that have occurred
    result = webWindow.executeJS('window.lastError', timeout);
    if ~isempty(result)
        warning('matlab:internal:liveeditor:timeoutreportinglasterror', ['The last JS error: ' result]);
    end
end

function percentHeapFree = getPercentHeapFree()
    runtime = java.lang.Runtime.getRuntime();
    percentHeapFree = runtime.freeMemory() * 100 / runtime.totalMemory();
end

function onMATLABWindowExit(exitStatus)
    error('matlab:internal:liveeditor:open', ['MATLAB window exited unexpectedly while opening document with exit status of ' num2str(exitStatus)]);
end

function pollForReadyDocument(javaDocument)
% Poll for 90 seconds. - this matches what was previously done
% in the synchronous setContent
    for i = 1:9000
        if javaDocument.isLoaded()
            return;
        end
        pause(0.01);
    end
    error('Timeout error when loading document.');
end
