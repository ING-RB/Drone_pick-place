classdef (Hidden) DocumentUtils
%DOCUMENTUTILS Static utility methods for
%matlab.desktop.editor.Document class
%
%   This function is unsupported and might change or be removed without
%   notice in a future version.

% These are utility functions to be used by
% matlab.desktop.editor.Document class functions and are not meant to
% be called by users directly.

% Copyright 2019-2022 The MathWorks, Inc.
    methods (Access = private)
        function obj = DocumentUtils
            obj = [];
        end
    end

    %% Static constructors
    % matlab.desktop.editor.Document uses these methods route the
    % action to appropriate subclass.
    methods (Static, Hidden)
        function obj = findEditor(filename)
            obj = performAction('findEditor', filename);
        end

        function obj = openEditor(filename)
            if useConnectorEditorService()
                obj = matlab.desktop.editor.internal.openFileUsingConnectorEditorService(filename);
                return;
            end
            obj = matlab.desktop.editor.(getEditorDocumentClassNameForFile(filename)).openEditor(filename);
        end

        function obj = openEditorForExistingFile(filename, options)
            arguments
                filename {mustBeTextScalar}
                options.Visible(1,1) matlab.lang.OnOffSwitchState = matlab.lang.OnOffSwitchState.on
                options.ReuseWebWindow matlab.internal.cef.webwindow {mustBeScalarOrEmpty} = matlab.internal.cef.webwindow.empty
            end
            if ~options.Visible
                obj = matlab.desktop.editor.HeadlessEditorDocument.openEditorForExistingFile(filename, options.ReuseWebWindow);
                return;
            end
            if ~isempty(options.ReuseWebWindow) 
                warning(message('MATLAB:Editor:Document:IgnoringReuseWebWindow'));
            end
            if useConnectorEditorService()
                obj = matlab.desktop.editor.internal.openFileUsingConnectorEditorService(filename);
                return;
            end
            obj = matlab.desktop.editor.(getEditorDocumentClassNameForFile(filename)).openEditorForExistingFile(filename);
        end
    end

    %% Static accessor methods
    % matlab.desktop.editor.Document uses these methods route the
    % action to appropriate subclass.
    methods (Static, Hidden)
        function [rtcEditors, javaEditors] = getAllOpenEditors
            if useJavaScriptBackEnd()
                rtcEditors = matlab.desktop.editor.MotwEditorDocument.getAllOpenEditors;
                javaEditors = [];
            else
                rtcEditors = matlab.desktop.editor.RtcEditorDocument.getAllOpenEditors;
                javaEditors = matlab.desktop.editor.JavaEditorDocument.getAllOpenEditors;
            end
        end

        function obj = getActiveEditor
            obj = performAction('getActiveEditor');
        end

        function obj = new(bufferText, options)
            arguments
                bufferText {mustBeText}
                options.Visible(1,1) matlab.lang.OnOffSwitchState = matlab.lang.OnOffSwitchState.on
                options.ReuseWebWindow matlab.internal.cef.webwindow {mustBeScalarOrEmpty} = matlab.internal.cef.webwindow.empty
            end
            if ~options.Visible
                obj = matlab.desktop.editor.HeadlessEditorDocument.new(bufferText, options.ReuseWebWindow);
                return;
            end
            if ~isempty(options.ReuseWebWindow) 
                warning(message('MATLAB:Editor:Document:IgnoringReuseWebWindow'));
            end
            if useConnectorEditorService()
                obj = matlab.desktop.editor.internal.openFileUsingConnectorEditorService();
                return;
            end
            obj = matlab.desktop.editor.(getEditorDocumentClassName(@isPlainCodeInLiveEditorSupported)).new(bufferText);
        end
    end
end

function tf = isPlainCodeInLiveEditorSupported
    tf = matlab.desktop.editor.EditorUtils.isPlainCodeInLiveEditorSupported;
end

function tf = useConnectorEditorService
    tf = matlab.desktop.editor.internal.useConnectorEditorService;
end

function tf = useJavaScriptBackEnd
    tf = matlab.desktop.editor.internal.useJavaScriptBackEnd;
end

function className = getEditorDocumentClassName(isRtcEditorSupportedFunction)
    if useJavaScriptBackEnd()
        className = 'MotwEditorDocument';
        return;
    end
    if isRtcEditorSupportedFunction()
        className = 'RtcEditorDocument';
    else
        className = 'JavaEditorDocument';
    end
end

function className = getEditorDocumentClassNameForFile(filename)
    import matlab.desktop.editor.EditorUtils.isFileSupportedInLiveEditor;
    func = @() isFileSupportedInLiveEditor(filename);
    className = getEditorDocumentClassName(func);
end

function obj = performAction(action, varargin)
    if useJavaScriptBackEnd()
        obj = matlab.desktop.editor.MotwEditorDocument.(action)(varargin{:});
    else
        obj = matlab.desktop.editor.RtcEditorDocument.(action)(varargin{:});
        if isempty(obj)
            obj = matlab.desktop.editor.JavaEditorDocument.(action)(varargin{:});
        end
    end
end
