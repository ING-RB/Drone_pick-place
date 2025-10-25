classdef (Abstract, AllowedSubclasses = {?matlab.desktop.editor.Document, ?matlab.desktop.editor.JavaEditorDocument, ?matlab.desktop.editor.RtcEditorDocument, ?matlab.desktop.editor.MotwEditorDocument, ?matlab.desktop.editor.HeadlessEditorDocument}, Hidden) DocumentInterface < handle
%matlab.desktop.editor.DocumentInterface Interface for document editors.

%   Copyright 2019-2022 The MathWorks, Inc.

    properties (Abstract, SetAccess = private, Dependent = true)
        %Filename - Full path of file associated with Document object.
        Filename;
        %Opened - Indicate whether Document is open.
        Opened;
        %Language - Programming language associated with Document object.
        Language;
    end

    properties (Abstract, SetAccess = public, Dependent = true)
        %Text - String array of the Document buffer contents.
        Text;
        %Selection - Start and end positions of selection in document.
        Selection;
    end

    properties (Abstract, SetAccess = private, Dependent = true)
        %SelectedText - Text currently selected in Document instance.
        SelectedText;
        %Modified - Whether the Document instance contains unsaved changes.
        Modified;
    end

    properties (Abstract, SetAccess = public, Dependent = true)
        %Editable -  Make buffer editable or uneditable.
        Editable;
    end

    events (Hidden = true, NotifyAccess = protected)
        %ContentDirtied - Notifies listeners after the unsaved changes are added to the Document instance.
        ContentDirtied
        %ContentSaved - Notifies listeners after the unsaved changes, in the Document instance, are saved or reverted.
        ContentSaved
    end


    %% Public instance methods
    methods (Abstract)
        save(obj)
        %save Save Document text to disk.

        saveAs(obj, filename)
        %saveAs Save Document text to disk using specified file name.

        goToLine(obj, line)
        %goToLine Move cursor to specified line in Editor document.

        goToPositionInLine(obj, line, position)
        %goToPositionInLine Move to specified position within line.

        goToFunction(obj, functionName)
        %goToFunction Move to function in MATLAB program.

        smartIndentContents(obj)
        %smartIndentContents Apply smart indenting to code.

        close(obj)
        %close Close document in Editor.

        closeNoPrompt(obj)
        %closeNoPrompt Close document in Editor, discarding unsaved changes.

        reload(obj)
        %RELOAD Revert to saved version of Editor document.

        appendText(obj, textToAppend)
        %appendText Append text to document in Editor.

        makeActive(obj)
        %makeActive Make document active in Editor.

        newObjs = setdiff(newObjsList, originalObjList)
        %setdiff Compare lists of Editor Documents.

        insertTextAtPositionInLine(obj, text, line, position)
        %insertTextAtPositionInLine Insert text in Editor document at position specified.
    end
end
