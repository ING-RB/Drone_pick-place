classdef (Hidden) LiveEditorUtilities
    % LiveEditorUtilities - utilities for Live Editor
    % Copyright 2016-2024 The MathWorks, Inc.
    
    methods (Static)
        executionTime = execute(editorId, fileName, persistOutput)
        executionTime = doExecute(editorId, fileName, persistOuptut)
        [javaRichDocument, cleanupObj, browserObj] = open(fileName, reuse, timeout, webwindow)
        [javaRichDocument, cleanupObj, executionTime] = openAndExecute(fileName)
        fileName = resolveFileName(fileName)
        save(javaRichDocument, fileName)
        saveas(javaRichDocument, fileName, varargin)
        [javaRichDocument, webWindow] = createDocument(timeout,webwindow)
        [output, error] = generateRichDocumentId()
    end
end
