classdef (Hidden, Sealed) JavaEditorDocument < matlab.desktop.editor.DocumentInterface
%matlab.desktop.editor.JavaEditorDocument Access document in Java based Editor.

%   Copyright 2008-2019 The MathWorks, Inc.

    properties (SetAccess = private, Dependent = true)
        Filename;
        Opened;
        Language;
    end

    properties (SetAccess = public, Dependent = true)
        Text;
        Selection;
    end

    properties (SetAccess = private, Dependent = true)
        SelectedText;
        Modified;
        ExtendedSelection;
        ExtendedSelectedText;
    end

    properties (SetAccess = public, Dependent = true)
        Editable;
    end

    properties (SetAccess = private, Hidden = true)
        %JavaEditor - Corresponding Java Editor object.
        JavaEditor;
    end

    properties (SetAccess = private, Hidden = true, Dependent = true)
        %LanguageObject - Java object representing programming language of Document.
        LanguageObject;
    end

    methods (Access = private, Hidden = true)
        %JavaEditorDocument - Constructor for JavaEditorDocument class.
        %   OBJ = JavaEditorDocument(JAVAEDITOR)
        function obj = JavaEditorDocument(JavaEditor)
            assert(~isempty(JavaEditor), ...
                   message('MATLAB:Editor:Document:EmptyEditor'));
            obj.JavaEditor = JavaEditor;
        end
    end

    %% Static constructors
    %These should only be called from matlab.desktop.editor functions
    methods (Static, Hidden)
        function obj = findEditor(fname)
        %findEditor Return Document instance for matching file name.
            assert(nargin >= 1 && ~isempty(fname), ...
                   message('MATLAB:Editor:Document:NoFilename'));

            jea = matlab.desktop.editor.EditorUtils.getJavaEditorApplication;

            if isAbsolutePath(fname)
                fileStorageLocation = matlab.desktop.editor.EditorUtils.fileNameToStorageLocation(fname);
                je = jea.findEditor(fileStorageLocation);
                if isempty(je)
                    obj = createEmptyReturnValue;
                else
                    obj = matlab.desktop.editor.JavaEditorDocument(je);
                end
            else
                % This indicates that fname is a relative path.
                obj = matchname(fname);
                if isempty(obj)
                    obj = createEmptyReturnValue;
                end
            end
        end

        function obj = openEditor(filename)
        %openEditor Attempt to open named file in Editor.
            import com.mathworks.mde.editor.EditorUtils
            obj = openEditorViaFunction(filename, @(file)openUsingOpenFileInAppropriateEditor(file), false);
        end

        function obj = openEditorForExistingFile(filename)
        %openEditorForExistingFile Open named file in Editor.
            jea = matlab.desktop.editor.EditorUtils.getJavaEditorApplication;
            obj = openEditorViaFunction(filename, @(file)jea.openEditorForExistingFile(file), true);
        end
    end

    %% Static accessor methods
    % matlab.desktop.editor uses these methods to obtain information
    % about existing documents. Because the return type is a Document
    % object, these methods must access the constructor.
    methods (Static, Hidden)
        function objs = getAllOpenEditors
        %getAllOpenEditors Return list of all open Documents.
            jea = matlab.desktop.editor.EditorUtils.getJavaEditorApplication;
            jEditors = jea.getOpenEditors;
            editors = matlab.desktop.editor.EditorUtils.javaCollectionToArray(jEditors);
            if numel(editors) == 0
                objs = createEmptyReturnValue;
            else
                objs = matlab.desktop.editor.JavaEditorDocument.empty(0,length(editors));
                for i=1:length(editors)
                    objs(i) = matlab.desktop.editor.JavaEditorDocument(editors{i});
                end
            end
        end

        function obj = getActiveEditor
        %getActiveEditor Return Document object for active MATLAB Editor.
            jea = matlab.desktop.editor.EditorUtils.getJavaEditorApplication;
            je = jea.getActiveEditor;
            if isempty(je)
                obj = createEmptyReturnValue;
            else
                obj = matlab.desktop.editor.JavaEditorDocument(je);
            end
        end

        function obj = new(bufferText)
        %NEW Create new document containing the specified text and return Document
        %object, which references that untitled object.
            jea = matlab.desktop.editor.EditorUtils.getJavaEditorApplication;
            javaEditor = jea.newEditor(bufferText);
            obj = matlab.desktop.editor.JavaEditorDocument(javaEditor);
        end
    end

    %% Public instance methods
    methods
        function save(obj)
        %save Save Document text to disk.
            assertOpen(obj);
            for i=1:numel(obj)
                errorMessage = processMessageWithFilename(obj(i).JavaEditor.saveAndReturnError);
                assert(isempty(errorMessage), 'MATLAB:Editor:Document:SaveFailed', errorMessage);
            end
        end

        function saveAs(obj, filename)
        %saveAs Save Document text to disk using specified file name.
            assertScalar(obj);
            assertOpen(obj)
            errorMessage = processMessageWithFilename(...
                obj.JavaEditor.saveAsAndReturnError(filename));
            assert(isempty(errorMessage), 'MATLAB:Editor:Document:SaveAsFailed', errorMessage);
        end

        function goToLine(obj, line)
        %goToLine Move cursor to specified line in Editor document.
            assertScalar(obj);
            assertLessEqualInt32Max(line, 'LINENUMBER');
            assertOpen(obj);

            obj.JavaEditor.goToLine(line, true);
        end

        function goToPositionInLine(obj, line, position)
        %goToPositionInLine Move to specified position within line.
            assertScalar(obj);
            assertLessEqualInt32Max(line, 'LINE');
            assertLessEqualInt32Max(position, 'POSITION');
            assertOpen(obj);

            obj.JavaEditor.goToLine(line, position);
        end

        function goToFunction(obj, functionName)
        %goToFunction Move to function in MATLAB program.
            assertScalar(obj);
            if isa(obj.LanguageObject, 'com.mathworks.widgets.text.mcode.MLanguage')
                text = obj.Text;
                tree = mtree(text);
                functions = Fname(tree);
                [isFunction, fcnIndex] = ismember(functionName, strings(functions),'legacy');
                if isFunction
                    functionIndices = functions.indices;
                    nodeIndex = functionIndices(fcnIndex);
                    fcnLine = lineno( functions.select(nodeIndex) );
                    goToLine(obj, fcnLine);
                end
            end
        end

        function smartIndentContents(obj)
        %smartIndentContents Apply smart indenting to code.
            for i=1:numel(obj)
                obj(i).JavaEditor.smartIndentContents;
            end
        end

        function close(obj)
        %close Close document in Editor.
            for i=1:numel(obj)
                obj(i).JavaEditor.close;
            end
        end

        function closeNoPrompt(obj)
        %closeNoPrompt Close document in Editor, discarding unsaved changes.
            for i=1:numel(obj)
                obj(i).JavaEditor.closeNoPrompt;
            end
        end

        function reload(obj)
        %RELOAD Revert to saved version of Editor document.
            assertOpen(obj);
            for i=1:numel(obj)
                errorMessage = processMessageWithFilename(...
                    obj(i).JavaEditor.reloadAndReturnError());
                assert(isempty(errorMessage), 'MATLAB:Editor:Document:ReloadFailed', errorMessage);
            end
        end

        function appendText(obj, textToAppend)
        %appendText Append text to document in Editor.
            assertScalar(obj);
            assertOpen(obj);
            assertEditable(obj);
            obj.JavaEditor.appendText(textToAppend);
        end

        function set.Text(obj, textToSet)
        %set.Text Set the text in the Document buffer.
            assertOpen(obj);
            assertEditable(obj);
            obj.JavaEditor.setSelection(0, obj.JavaEditor.getLength)
            obj.JavaEditor.insertTextAtCaret(textToSet);
        end

        function makeActive(obj)
        %makeActive Make document active in Editor.
            assertScalar(obj);
            obj.JavaEditor.bringToFront;
        end

        function newObjs = setdiff(newObjsList, originalObjList)
        %setdiff Compare lists of Editor Documents.
            newObjs = createEmptyReturnValue;
            for i = 1:numel(newObjsList)
                currentNewEditor = newObjsList(i);
                if ~ismember(currentNewEditor, originalObjList,'legacy')
                    newObjs(end+1) = currentNewEditor; %#ok<AGROW>
                end
            end
        end

        function filename = get.Filename(obj)
            try
                if ~obj.JavaEditor.isBuffer
                    storageLocation = obj.JavaEditor.getStorageLocation;
                    filename = char(storageLocation.getFile);
                else
                    filename = char(obj.JavaEditor.getShortName);
                end
            catch ex %#ok<NASGU>
                filename = '';
            end
        end

        function text = get.Text(obj)
            assertOpen(obj);
            text = char(obj.JavaEditor.getText);
        end

        function selection = get.Selection(obj)
            assertOpen(obj);
            javaTextPane = obj.JavaEditor.getComponent.getEditorView.getSyntaxTextPane;
            [start_line, start_position_in_line] = ...
                matlab.desktop.editor.indexToPositionInLine(obj, javaTextPane.getSelectionStart + 1);
            [end_line, end_position_in_line] = ...
                matlab.desktop.editor.indexToPositionInLine(obj, javaTextPane.getSelectionEnd + 1);
            selection = [start_line, start_position_in_line, ...
                         end_line, end_position_in_line];
        end

        function set.Selection(obj, position)
            assertOpen(obj);
            assert(isnumeric(position) && length(position) == 4, ...
                   message('MATLAB:Editor:Document:InvalidSelection'));

            startPos = matlab.desktop.editor.positionInLineToIndex(...
                obj, position(1), position(2)) -1;
            endPos = matlab.desktop.editor.positionInLineToIndex(...
                obj, position(3), position(4)) -1;

            obj.JavaEditor.setSelection(startPos, endPos);
        end

        function text = get.SelectedText(obj)
            assertOpen(obj);
            text = char(obj.JavaEditor.getSelection);
        end

        function extendedSelection = get.ExtendedSelection(obj)
            extendedSelection = obj.Selection;
        end

        function extendedSelectedText = get.ExtendedSelectedText(obj)
            extendedSelectedText = cellstr(obj.SelectedText);
        end

        function editable = get.Editable(obj)
            assertOpen(obj);
            editable = obj.JavaEditor.isEditable;
        end

        function set.Editable(obj, editable)
            assertOpen(obj);
            obj.JavaEditor.setEditable(editable);
        end

        function lang = get.Language(obj)
            assertOpen(obj);
            lang = char(obj.LanguageObject.getName);
        end

        function langObj = get.LanguageObject(obj)
            assertOpen(obj);
            langObj = obj.JavaEditor.getLanguage;
        end

        function insertTextAtPositionInLine(obj, text, line, position)
        %insertTextAtPositionInLine Insert text in Editor document at position specified.
            assertScalar(obj);
            assertEditable(obj);
            index = matlab.desktop.editor.positionInLineToIndex(obj, ...
                                                              line, position);
            obj.JavaEditor.setCaretPosition(index - 1);
            obj.JavaEditor.insertTextAtCaret(text);
        end

        function isopen = get.Opened(obj)
            isopen = logical(obj.JavaEditor.isOpen);
        end

        function bool = get.Modified(obj)
            assertOpen(obj);
            bool = obj.JavaEditor.isDirty;
        end

        function bool = eq(obj1, obj2)
        %eq Overloads the == operator to compare two Document objects.
            n1 = numel(obj1);
            n2 = numel(obj2);

            assert(n1 == 1 || n2 == 1 || any(size(obj1) == size(obj2)), ...
                   message('MATLAB:Editor:Document:InvalidMatrixDimensions'));

            % Make sure that at least one object is not empty.
            if isempty(obj1) || isempty(obj2)
                bool = false;
            else

                % Loop over the larger array.
                if n2 > n1
                    bool = loopEq(obj2, obj1);
                else
                    bool = loopEq(obj1, obj2);
                end
            end


            function bool = loopEq(obj1, obj2)
                bool = false(size(obj1));
                num2 = numel(obj2);
                for i=1:numel(obj1)
                    if num2 > 1
                        je2 = obj2(i).JavaEditor;
                    else
                        je2 = obj2.JavaEditor;
                    end
                    bool(i) = obj1(i).JavaEditor == je2;
                end
            end

        end

        function bool = isequal(obj1, obj2)
        % Test two (possibly arrays of) Documents for equality.
            bool = isequal(size(obj1),size(obj2)) && all(eq(obj1, obj2));
        end
    end

    methods (Hidden)
        function [line, position] = indexToPositionInLine(obj, index)
            returnArray = obj.JavaEditor.positionToLineAndColumn(index);
            line = double(returnArray(1));
            position = double(returnArray(2));
        end

        function index = positionInLineToIndex(obj, line, position)
            index = obj.JavaEditor.lineAndColumnToPosition(line, position) + 1;
        end
    end
end

function assertScalar(obj)
% assertScalar Check that Document is scalar.
    matlab.desktop.editor.EditorUtils.assertScalar(obj);
end


function assertOpen(obj)
% assertOpen Check that Document is open.
    matlab.desktop.editor.EditorUtils.assertOpen(obj, 'DOCUMENT');
end

function assertEditable(obj)
% assertEditable Check that Document is editable.
    assert(all([obj.Editable]), message('MATLAB:Editor:Document:Uneditable'));
end

function assertLessEqualInt32Max(input, variablename)
% assertLessEqualInt32Max Check that input number is not greater than maximum of 32-bit integer.
    matlab.desktop.editor.EditorUtils.assertLessEqualInt32Max(input, variablename);
end

function match = matchname(fname)
%MATCHNAME Return first open Document with file name containing fname.

    match = '';
    editors = matlab.desktop.editor.JavaEditorDocument.getAllOpenEditors;

    partialMatchedEditors = {};
    for i = 1:length(editors)

        currentname = editors(i).Filename;
        [~, currentFileName, currentFileExt] = fileparts(currentname);

        % If filename with extension matched, (e.g. C:\myFile.m with myFile.m),
        % then return it
        if ~isempty(currentname) && isequal([currentFileName currentFileExt], fname)
            match = editors(i);
            return
        end

        % If filename without extension matched, (e.g. C:\myFile.m with myFile),
        % then return it
        if ~isempty(currentname) && isequal(currentFileName, fname)
            match = editors(i);
            return
        end

        % If the part of the filename matches the current filename,
        % then collect the list of partially matched editors
        if ~isempty(currentname) && contains(currentname, fname)
            partialMatchedEditors{end+1} = editors(i); %#ok<AGROW>
        end
    end

    % Return the first item in partially matched editor list
    if ~isempty(partialMatchedEditors)
        match = partialMatchedEditors{1};
    end

end

function emptyDocs = createEmptyReturnValue
% createEmptyReturnValue Return 1x0 empty Document array.
    emptyDocs = matlab.desktop.editor.JavaEditorDocument.empty(1,0);
end

function F = fileNameToJavaFile(filename)
%fileNameToJavaFile Convert string file name to java.io.File object.
    F = java.io.File(filename);
end

function tf = isAbsolutePath(filename)
%isAbsolutePath Test if specified file name is absolute.
    javaFile = fileNameToJavaFile(filename);
    tf = javaMethod('isAbsolute', javaFile);
end

function message = processMessageWithFilename(javaMessage)
%processMessageWithFilename Convert single backslash to double backslash.
%For use with the error function.
    message = regexprep(char(javaMessage), '\', '\\\');
end

function javaEditor = openUsingOpenFileInAppropriateEditor(javaFile)
%openUsingOpenFileInAppropriateEditor Helper method for using the
%EditorUtils.openFileInAppropriateEditor java method to open a file and
%return the Editor instance for the file if one exists since
%openFileInAppropriateEditor does not return an editor interface.
    import com.mathworks.mde.editor.EditorUtils
    EditorUtils.openFileInAppropriateEditor(javaFile);
    javaEditor = EditorUtils.getEditorForFile(javaFile);
end

function obj = openEditorViaFunction(filename, openMethod, mustExist)
%openEditorViaFunction Helper method for openEditor and openEditorForExistingFile.
    assert(isAbsolutePath(filename), ...
           message('MATLAB:Editor:Document:PartialPath', filename));

    javaFile = fileNameToJavaFile(filename);

    if (mustExist && ~javaFile.exists)
        % Calling the open method throws an exception, but we just want to
        % return an empty Document array.
        javaEditor = [];
    else
        javaEditor = openMethod(javaFile);
    end
    if isempty(javaEditor)
        obj = createEmptyReturnValue;
    else
        obj = matlab.desktop.editor.JavaEditorDocument(javaEditor);
    end
end
