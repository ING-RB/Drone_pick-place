classdef MATLABCodeGenerator < ...
        matlabshared.mediator.internal.Publisher & ...
        matlabshared.mediator.internal.Subscriber & ...
        matlabshared.transportapp.internal.utilities.ITestable

    %MATLABCODEGENERATOR generates the MATLAB code associated with user
    %interactions with the app, like
    % - Creating a transport
    % - Setting transport properties
    % - Performing a read action
    % - Performing a write action
    % This class is also responsible for sending the generated code to the
    % MATLAB Code Log, and exporting the generated MATLAB code log contents
    % to an MLX File.

    % Copyright 2021-2023 The MathWorks, Inc.

    properties
        % Dictates whether the code is added with indentation, or not.
        %
        % false (default - for legacy behavior) - code is not indented.
        %
        % true - code is indented.
        CodeLinesIndented (1, 1) logical = false
    end

    properties (Access = ?matlabshared.transportapp.internal.utilities.ITestable)
        TransportName (1, 1) string
        TransportSymbol (1, 1) string
        AppName (1, 1) string

        % Handle to the Editor Manager instance
        EditorManager matlabshared.testmeasapps.internal.plaintexteditor.EditorManager = ...
            matlabshared.testmeasapps.internal.plaintexteditor.EditorManager.empty

        % The index value appended to the "data" variable in read APIs in
        % the MATLAB Code Log.
        % E.g. in
        % data1 = read(s, 10, "uint8"), ReadIndex -> 1
        % data5 = read(s, 10, "uint8"), ReadIndex -> 5
        ReadIndex (1, 1) {mustBeNumeric, mustBePositive, mustBeNonzero, mustBeNonempty, mustBeInteger} = 1

        ConstructorComment (1, 1) string
        ConstructorCode (1, 1) string
        ConstructorText (1, 1) string

        % Flag that denotes whether code has been generated for any
        % read/write/property setting event.
        OtherOperations (1, 1) logical = false
    end

    properties (SetObservable, AbortSet)
        % The MATLAB connector generated URL that will be used to render
        % the editor.
        EditorURL (1, 1) string
    end

    properties
        ReadTerminator = """LF"""
        WriteTerminator = """LF"""
    end

    properties (Constant)
        StringTerminators = ["CR", "LF", "CR/LF"]
        CommentLength = 150
    end

    properties(SetAccess = private, Dependent)
        % Flag that says whether editor has been rendered or not.
        EditorReady
    end

    methods (Static)
        function val = getEditorManager(em, clearVal)
            arguments
                em = []
                clearVal (1, 1) logical = false
            end
            persistent editorManager

            if clearVal
                editorManager = [];
            end
            if isempty(editorManager)
                editorManager = em;
            end
            val = editorManager;
        end
    end

    %% Lifetime
    methods
        function obj = MATLABCodeGenerator(mediator, appName, transportName, transportSymbol)
            arguments
                mediator (1, 1) matlabshared.mediator.internal.Mediator
                appName (1, 1) string
                transportName (1, 1) string
                transportSymbol (1, 1) string
            end

            obj@matlabshared.mediator.internal.Publisher(mediator);
            obj@matlabshared.mediator.internal.Subscriber(mediator);

            obj.AppName = appName;
            obj.TransportName = transportName;
            obj.TransportSymbol = transportSymbol;
        end

        function connect(obj, constructorComment, constructorCode, commentLength)
            arguments
                obj
                constructorComment (1, 1) string
                constructorCode (1, 1) string
                commentLength (1, 1) double = 90
            end

            obj.EditorManager = ...
                matlabshared.testmeasapps.internal.plaintexteditor.EditorManager();
            % Get the code log text from Editor Manager
            matlabshared.transportapp.internal.utilities.MATLABCodeGenerator.getEditorManager(obj.EditorManager, true);

            obj.EditorManager.CommentLength = commentLength;

            obj.EditorURL = obj.EditorManager.URL;
            obj.EditorManager.setEditorReadOnly(true);

            obj.addComment(constructorComment);
            obj.addCodeLineTruncatedWithSemicolon(constructorCode);
            obj.addNewLine();

            obj.ConstructorComment = constructorComment;
            obj.ConstructorCode = constructorCode;

            % Save the existing constructor text from the editor.
            obj.ConstructorText = obj.EditorManager.getText();

            obj.OtherOperations = false;
        end

        function disconnect(obj)
            obj.EditorManager = ...
                matlabshared.testmeasapps.internal.plaintexteditor.EditorManager.empty;
            matlabshared.transportapp.internal.utilities.MATLABCodeGenerator.getEditorManager([], true);
        end
    end

    %% Implementing Subscriber Abstract methods
    methods
        function subscribeToMediatorProperties(obj, ~, ~)
            obj.subscribe('Comment', ...
                @(src, event)obj.addComment(event.AffectedObject.Comment));

            obj.subscribe('Code', ...
                @(src, event)obj.addCode(event.AffectedObject.Code));

            obj.subscribe('CodeWithoutSemicolon', ...
                @(src, event)obj.addCodeWithoutSemicolon(event.AffectedObject.CodeWithoutSemicolon));

            obj.subscribe('PropertyNameValue', ...
                @(src, event)obj.addProperty(event.AffectedObject.PropertyNameValue));

            obj.subscribe('TransportDataCodeLog', ...
                @(src, event)obj.setCodeLogReadWriteActions(event.AffectedObject.TransportDataCodeLog));

            obj.subscribe('FlushCommentAndCode', ...
                @(src, event)obj.addFlushCommentAndCode());

            obj.subscribe('ReadTerminator', ...
                @(src, event)obj.addReadTerminatorSet(event.AffectedObject.ReadTerminator));

            obj.subscribe('WriteTerminator', ...
                @(src, event)obj.addWriteTerminatorSet(event.AffectedObject.WriteTerminator));

            obj.subscribe('ExportCodeLog', ...
                @(src, event)obj.exportMATLABScript());

            obj.subscribe('NewLine', ...
                @(src, event)obj.addNewLine());
        end
    end

    %% Subscriber methods
    methods
        function addNewLine(obj)
            obj.EditorManager.addNewLine();
            obj.OtherOperations = true;
        end

        function addCode(obj, code)
            % Add code on a newline.
            arguments
                obj
                code (1, 1) string
            end

            if obj.CodeLinesIndented
                obj.addCodeLineTruncatedWithSemicolon(code);
            else
                obj.addCodeWithSemicolon(code);
            end
        end

        function addComment(obj, str)
            % Add a comment on a new line.
            arguments
                obj
                str (1, 1) string
            end
            obj.EditorManager.addComment(str);
            obj.OtherOperations = true;
        end

        function addCodeLineTruncatedWithSemicolon(obj, code)
            % Add a new line of code. The semi-colon is automatically
            % appended to this.
            % The code line length is limited to CommentCharLength.
            arguments
                obj
                code (1, 1) string
            end
            obj.EditorManager.addCodeLineTruncatedWithSemicolon(code);
            obj.OtherOperations = true;
        end

        function addCodeWithSemicolon(obj, code)
            % Add a new line of code. The semi-colon is automatically
            % appended to this.
            arguments
                obj
                code (1, 1) string
            end
            obj.EditorManager.addCodeWithSemicolon(code);
            obj.OtherOperations = true;
        end

        function addCodeWithoutSemicolon(obj, code)
            % Add a new line of code. The semi-colon is not appended
            % automatically. This can be useful for clearing the interface,
            % like >> clear m
            arguments
                obj
                code (1, 1) string
            end
            obj.EditorManager.addCodeWithoutSemicolon(code);
            obj.OtherOperations = true;
        end

        function addProperty(obj, propertyDetails)
            % Whenever the property setter changes, this function is
            % called. It automatically generates the necessary comment and
            % code associated with setting the transport property.

            arguments
                obj
                propertyDetails (1, 2) cell
            end

            % Get the property name and property value from propertyDetails.
            propertyName = propertyDetails{1};
            validateattributes(propertyName, ["string", "char"], "nonempty");
            propertyValue = obj.formatPropertyValue(propertyDetails{2});

            commentLine = message("transportapp:utilities:PropertySetterComment", ...
                propertyName, ...
                obj.TransportName, ...
                obj.TransportSymbol, ...
                propertyValue).getString;

            codeLine = sprintf("%s.%s = %s;", ...
                obj.TransportSymbol, ...
                propertyName, ...
                propertyValue ...
                );

            obj.OtherOperations = true;
            obj.addCommentAndCode(commentLine, codeLine);
        end

        function addReadTerminatorSet(obj, readTerminator)
            % When the read terminator value is set, automatically generate
            % the comment and code using configureTerminator.

            if ischar(readTerminator) && any(readTerminator == obj.getReadStringTerminatorsHook())
                readTerminator = string(readTerminator);
            end

            obj.ReadTerminator = obj.formatPropertyValue(readTerminator);
            obj.setTerminator("Read");
        end

        function addWriteTerminatorSet(obj, writeTerminator)
            % When the write terminator value is set, automatically
            % generate the comment and code using configureTerminator.

            if ischar(writeTerminator) && any(writeTerminator == obj.StringTerminators)
                writeTerminator = string(writeTerminator);
            end

            obj.WriteTerminator = obj.formatPropertyValue(writeTerminator);
            obj.setTerminator("Write");
        end

        function addFlushCommentAndCode(obj)
            % Generate the comment and code lines for a flush operation.

            commentLine = message("transportapp:utilities:FlushComment", ...
                obj.TransportName, ...
                obj.TransportSymbol).getString;
            codeLine = sprintf("flush(%s)", obj.TransportSymbol);
            obj.OtherOperations = true;
            obj.addCommentAndCode(commentLine, codeLine);
        end

        function setCodeLogReadWriteActions(obj, transportData)
            % Whenever user performs a read or write action,
            % automatically generate the associated comment and code.

            arguments
                obj
                transportData matlabshared.transportapp.internal.utilities.forms.TransportData
            end

            switch transportData.Action
                case "Write"
                    commentLine = message("transportapp:utilities:WriteComment", ...
                        transportData.Value, ...
                        transportData.DataType, ...
                        obj.TransportName, ...
                        obj.TransportSymbol ...
                        ).getString;
                    codeLine = sprintf("write(%s,%s,""%s"");", ...
                        obj.TransportSymbol, ...
                        transportData.Value, ...
                        transportData.DataType);

                case "WriteLine"
                    commentLine = message("transportapp:utilities:WritelineComment", ...
                        transportData.Value, ...
                        obj.TransportName, ...
                        obj.TransportSymbol, ...
                        obj.WriteTerminator ...
                        ).getString;
                    codeLine = sprintf("writeline(%s,%s);", ...
                        obj.TransportSymbol, ...
                        transportData.Value ...
                        );

                case "WriteBinblock"

                    % Check if header field exists - generate the code log
                    % comment and code accordingly.

                    headerExists = matlabshared.transportapp.internal.utilities.TransportDataValidator.binblockHeaderExists(transportData);
                    if headerExists
                        header = transportData.UserData.Header;

                        % For the generated code with custom header, use
                        %
                        % 1. Double quotes if the header contains single
                        % quotes or contains no quotes. e.g.
                        % writebinblock(obj, data, precision, "This is a 'custom' header");
                        %
                        % 2. Single quotes if the header contains double
                        % quotes. e.g.
                        % writebinblock(obj, data, precision, 'This is a "custom" header');
                        quotes = obj.getQuotesForCustomHeaderText(header);

                        % Wrap the header string in quotes (single or
                        % double).
                        header = quotes + header + quotes;

                        commentLine = message("transportapp:utilities:WritebinblockCommentWithCustomHeader", ...
                            transportData.Value, ...
                            transportData.DataType, ...
                            obj.TransportName, ...
                            obj.TransportSymbol, ...
                            header ...
                            ).getString;
                        codeLine = sprintf("writebinblock(%s,%s,""%s"",%s);", ...
                            obj.TransportSymbol, ...
                            transportData.Value, ...
                            transportData.DataType, ...
                            header ...
                            );
                    else
                        commentLine = message("transportapp:utilities:WritebinblockComment", ...
                            transportData.Value, ...
                            transportData.DataType, ...
                            obj.TransportName, ...
                            obj.TransportSymbol ...
                            ).getString;
                        codeLine = sprintf("writebinblock(%s,%s,""%s"");", ...
                            obj.TransportSymbol, ...
                            transportData.Value, ...
                            transportData.DataType ...
                            );
                    end

                case "Read"
                    commentLine = message("transportapp:utilities:ReadComment", ...
                        transportData.Value, ...
                        transportData.DataType, ...
                        obj.TransportName, ...
                        obj.TransportSymbol ...
                        ).getString;
                    codeLine = sprintf("data%d = read(%s,%s,""%s"");", ...
                        obj.ReadIndex, ...
                        obj.TransportSymbol, ...
                        transportData.Value, ...
                        transportData.DataType ...
                        );

                    obj.ReadIndex = obj.ReadIndex + 1;

                case "ReadLine"
                    commentLine = message("transportapp:utilities:ReadlineComment", ...
                        obj.ReadTerminator, ...
                        obj.TransportName, ...
                        obj.TransportSymbol ...
                        ).getString;
                    codeLine = sprintf("data%d = readline(%s);", ...
                        obj.ReadIndex, ...
                        obj.TransportSymbol ...
                        );

                    obj.ReadIndex = obj.ReadIndex + 1;

                case "ReadBinblock"
                    commentLine = message("transportapp:utilities:ReadbinblockComment", ...
                        transportData.DataType, ...
                        obj.TransportName, ...
                        obj.TransportSymbol ...
                        ).getString;
                    codeLine = sprintf("data%d = readbinblock(%s,""%s"");", ...
                        obj.ReadIndex, ...
                        obj.TransportSymbol, ...
                        transportData.DataType...
                        );

                    obj.ReadIndex = obj.ReadIndex + 1;

                case "WriteRead"
                    commentLine = message("transportapp:utilities:WritereadComment", ...
                        obj.TransportSymbol, ...
                        transportData.Value ...
                        ).getString;
                    codeLine = sprintf("data%d = writeread(%s,%s);", ...
                        obj.ReadIndex, ...
                        obj.TransportSymbol, ...
                        transportData.Value...
                        );

                    obj.ReadIndex = obj.ReadIndex + 1;
            end
            obj.addCommentAndCode(commentLine, codeLine);
        end

        function exportScriptBuilder = exportMATLABScript(obj, varargin)
            % Export the generated MATLAB code into a formatted MLX file.

            % The script builder instance to create the constructor code
            % and comment for exporting.
            constructorBuilder = matlabshared.testmeasapps.internal.matlabcodegenerator.ScriptBuilder();

            if obj.CodeLinesIndented
                constructorCode = constructorBuilder.addCodeLineTruncatedWithSemicolon(obj.ConstructorCode);
            else
                constructorCode = constructorBuilder.addCodeLineWithSemiColon(obj.ConstructorCode);
            end

            constructorText = constructorBuilder.addComment(obj.ConstructorComment) + newline + ...
                constructorCode + newline;

            % "Generated By" comment and Section Headers
            generatedBy = ...
                message("transportapp:utilities:AppGeneratorComment", obj.AppName, string(datetime)).getString;
            constructorHeader = ...
                message("transportapp:utilities:ConstructorSectionHeader").getString;
            otherOperationsHeader = ...
                message("transportapp:utilities:OtherOperationsHeader").getString;

            % The script builder instance that will be used to create the
            % final MATLAB script to be exported.
            exportScriptBuilder = ...
                matlabshared.testmeasapps.internal.matlabcodegenerator.ScriptBuilder();

            % Replace the constructor code present in the editor with the
            % newly updated code, replacementText. replacementText contains the
            % additional :"generated by" comments, and section headers. The
            % replacementText replaces the "constructorText" of the editor.

            replacementText = exportScriptBuilder.addComment(generatedBy) + newline + ...
                exportScriptBuilder.addSectionHeader(constructorHeader) + newline + ...
                constructorText;

            % If other read and write operations, or property setting
            % operations, were performed, add the additional header.
            if obj.OtherOperations
                replacementText = replacementText + ...
                    exportScriptBuilder.addSectionHeader(otherOperationsHeader) + ...
                    newline;
            end

            % Get the existing text from the editor.
            currentText = obj.EditorManager.getText();

            % Replace the "constructorText" of the existing editor with the
            % text with additional headers and "generated by" comment,
            % replacementText.
            currentText = replace(currentText, obj.ConstructorText, replacementText);

            exportScriptBuilder.setText(currentText);

            % Add the cleanup section.
            appendDestructorSection(obj, exportScriptBuilder);

            % Finally, export the updated script.
            if isempty(varargin)
                exportScriptBuilder.createMLXFile();
            end

            function appendDestructorSection(obj, scriptBuilder)
                % Append the destructor section of the exported code log.
                % scriptBuilder is a handle class, so the scriptBuilder
                % instance does not need to be returned.

                destructorHeader = message("transportapp:utilities:DestructionSectionHeader").getString;
                destructorComment = message("transportapp:utilities:DestructorMessage", obj.TransportName, obj.TransportSymbol).getString;
                destructorCode = sprintf("clear %s", obj.TransportSymbol);
                scriptBuilder.addSectionHeader(destructorHeader);
                scriptBuilder.addComment(destructorComment);
                scriptBuilder.addCodeLine(destructorCode);
                scriptBuilder.addNewLine();
            end
        end
    end

    %% Hook Functions
    methods (Access = {?matlabshared.transportapp.internal.utilities.MATLABCodeGenerator, ?matlabshared.transportapp.internal.utilities.ITestable})
        function readTerminators  = getReadStringTerminatorsHook(obj)
            % Get valid Read Terminators. Derived classes should override
            % this helper method to support other terminating characters.
            readTerminators = obj.StringTerminators;
        end
    end

    %% Helper Functions
    methods (Access = ?matlabshared.transportapp.internal.utilities.ITestable)

        function quotes = getQuotesForCustomHeaderText(~, headerData)
            % Returns single or double quotes based on the header Data
            % text. Returns single quotes when the data contains double
            % quotes Returns double quotes for all other cases -
            % a. header contains single quotes
            % b. header contains no quotes

            if contains(headerData, """")
                quotes = "'";
            else
                quotes = """";
            end
        end

        function addCommentAndCode(obj, commentLine, codeLine)
            % Add the associated comment and code using the
            % GenerateScriptUtil instance.

            arguments
                obj
                commentLine (1, 1) string
                codeLine (1, 1) string
            end

            obj.addComment(commentLine);
            obj.addCode(codeLine);
            obj.addNewLine();
        end

        function propertyValue = formatPropertyValue(~, propertyValue)
            % The property value can be of any type. But, for displaying
            % the code, the property value needs to be a string.
            % Furthermore, for string property values like "little-endian"
            % and "big-endian" for ByteOrder need to have the associated
            % double quotes ("") around the property name in the generated
            % code.

            if ~isstring(propertyValue) && ~ischar(propertyValue)
                propertyValue = string(propertyValue);
            else
                propertyValue = """" + string(propertyValue) + """";
            end
        end

        function setTerminator(obj, type)
            % Contains common comment/code logic for setting the read and
            % write terminators.

            arguments
                obj
                type (1, 1) string {mustBeMember(type, ["Write", "Read"])}
            end
            terminatorType = type + "Terminator";

            switch terminatorType
                case "ReadTerminator"
                    thisTerminator = obj.ReadTerminator;
                    thisTerminatorType = "read";

                    otherTerminator = obj.WriteTerminator;
                    otherTerminatorType = "write";

                case "WriteTerminator"
                    thisTerminator = obj.WriteTerminator;
                    thisTerminatorType = "write";

                    otherTerminator = obj.ReadTerminator;
                    otherTerminatorType = "read";
            end

            [commentLine, codeLine] = parseTerminator(obj, thisTerminator, otherTerminator, ...
                thisTerminatorType, otherTerminatorType);
            obj.OtherOperations = true;
            obj.addCommentAndCode(commentLine, codeLine);

            function [commentLine, codeLine] = parseTerminator(obj, thisTerminator, otherTerminator, thisTerminatorType, otherTerminatorType)

                % If both terminators are equal e.g. if both are double and
                % equal to 10, or both are string and equal to "CR".
                if string(class(thisTerminator)) == string(class(otherTerminator)) && ...
                        thisTerminator == otherTerminator

                    commentLine = message("transportapp:utilities:SameTerminatorSetterComment", ...
                        obj.TransportName, ...
                        obj.TransportSymbol, ...
                        thisTerminator).getString;
                    codeLine = sprintf("configureTerminator(%s,%s);", ...
                        obj.TransportSymbol, ...
                        thisTerminator);

                else
                    % Both terminators are different
                    commentLine = message("transportapp:utilities:TerminatorSetterComment", ...
                        thisTerminatorType, ...
                        obj.TransportName, ...
                        obj.TransportSymbol, ...
                        thisTerminator ...
                        ).getString;

                    lastLine = message("transportapp:utilities:TerminatorLastLine", ...
                        otherTerminatorType, ...
                        otherTerminator).getString;

                    commentLine = commentLine + " " + lastLine;
                    codeLine = sprintf("configureTerminator(%s,%s,%s);", ...
                        obj.TransportSymbol, ...
                        obj.ReadTerminator, ...
                        obj.WriteTerminator ...
                        );
                end
            end
        end
    end

    % Getters and Setters
    methods
        function val = get.EditorReady(obj)
            val = obj.EditorManager.EditorReady;
        end
    end
end
