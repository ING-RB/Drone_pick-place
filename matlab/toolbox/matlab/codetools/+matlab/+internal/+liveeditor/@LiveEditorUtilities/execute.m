function executionTime = execute(editorId, fileName, persistOutput, isSynchronousDrawnowRequired)
    % EXECUTE Executes the rich document. For internal use only.
    
    % editorId - The editor Id of the RTC instance to execute.
    % fileName - The full file path of the file to be run.
    % persistOutput - If true, server side outputs will not be cleaned up. This includes interactive figures and variables
    % isSynchronousDrawnowRequired - Determines whether a synchronous drawnow be used.
    %
    % The prerequisites for using this function are the following:
    % The editorId must correspond to an open Live Editor client.
    % The file in the live editor must correspond to the file path provided.
    % The live editor instance must be saved, that is, not dirty.
    % The file must be a Live Script file.
    % This function should not be run from within another live evaluation.
    % For best results, the file should also be on the path.
    % 
    % Copyright 2014-2024 The MathWorks, Inc.

    arguments
        editorId (1, :) char {}
        fileName char {mustBeLiveScript}
        persistOutput (1, 1) logical = false
        isSynchronousDrawnowRequired (1, 1) logical = true
    end
    
    import matlab.internal.liveeditor.LiveEditorUtilities
    executionTime = LiveEditorUtilities.doExecute(editorId, fileName, persistOutput, isSynchronousDrawnowRequired);
end

function mustBeLiveScript(filepath)
    if ~matlab.desktop.editor.EditorUtils.isLiveCodeFile(filepath)
        errorId = 'matlab:internal:liveeditor:execute:mustBeLiveScript';
        messageText = 'Input file must be a live script file (.mlx or .m live script)';
        throwAsCaller(MException(errorId, messageText))
    end
end
