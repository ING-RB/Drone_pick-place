classdef TextCodeGenerator < internal.matlab.importtool.server.TabularCodeGenerator
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % This class is the code generator class for Text Import.
    
    % Copyright 2018-2024 The MathWorks, Inc.

    properties
        isFixedWidth = false;
    end
    
    methods
        function this = TextCodeGenerator(showLastOutput)
            arguments
                showLastOutput (1,1) logical = false
            end

            % Creates a TextCodeGenerator instance.  
            this.showLastOutput = showLastOutput;
            this.SupportsPreserveDTFormat = true;
        end

        function [code, codeDescription] = generateScript(this, imopts, NameValueArgs)
            % Generate the script code.  If this.ShortCircuitCode is set, there
            % will be an attempt to generate code which is a single line of
            % readtable or readtimetable.  But if ShortCircuitCode is not set,
            % or if there are too many differences to the output, then the full
            % generated code which includes the import options creation will be
            % generated.

            arguments
                this
                imopts
                NameValueArgs.ArbitraryVarNames {mustBeNumericOrLogical} = false;
                NameValueArgs.DataLines {mustBeA(NameValueArgs.DataLines, ["string", "char", "cell"])} = strings(0);
                NameValueArgs.DefaultTextType {mustBeMember(NameValueArgs.DefaultTextType, ["string", "char"])} = "string";
                NameValueArgs.Filename {mustBeA(NameValueArgs.Filename, ["string", "char", "cell"])} = "";
                NameValueArgs.InitialSelection double = [];
                NameValueArgs.NumRows double = [];
                NameValueArgs.OriginalOpts = [];
                NameValueArgs.OutputType {mustBeA(NameValueArgs.OutputType, "internal.matlab.importtool.server.output.OutputType")} = internal.matlab.importtool.server.output.TableOutputType;
                NameValueArgs.VarName {mustBeA(NameValueArgs.VarName, ["string", "char", "cell"])} = "";
            end

            if isempty(NameValueArgs.DataLines)
                NameValueArgs.DataLines = {imopts.DataLines};
            end

            code = [];
            codeDescription = struct("containsImportOptions", true);

            % Try to short-circuit code generation if ShortCircuitCode, and both
            % the original detected importOptions and current importOptions are
            % delimited text, and the output is table or timetable.
            if this.eligibleForShortCircuit(NameValueArgs, imopts, "matlab.io.text.DelimitedTextImportOptions")
                code = this.generateShortCircuitCode(NameValueArgs, imopts);
            end

            if isempty(code)
                % Either ShortCircuitCode is not set, or we were unable to
                % short-circuit the code generation, so do the full code
                % generation using importOptions
                opts = NameValueArgs.OutputType.updateImportOptionsForOutputType(imopts);
                code = generateScriptFromArgs(this, opts, NameValueArgs);
            else
                codeDescription.containsImportOptions = false;
            end
        end                
        
        function code = generateFunction(this, imopts, NameValueArgs)
            arguments
                this
                imopts
                NameValueArgs.ArbitraryVarNames {mustBeNumericOrLogical} = false;
                NameValueArgs.DataLines {mustBeA(NameValueArgs.DataLines, ["string", "char", "cell"])} = strings(0);
                NameValueArgs.DefaultTextType {mustBeMember(NameValueArgs.DefaultTextType, ["string", "char"])} = "string";
                NameValueArgs.Filename {mustBeA(NameValueArgs.Filename, ["string", "char", "cell"])} = "";
                NameValueArgs.FunctionName {mustBeText} = strings(0);
                NameValueArgs.InitialSelection double = [];
                NameValueArgs.NumRows double = [];
                NameValueArgs.OriginalOpts = [];
                NameValueArgs.OutputType {mustBeA(NameValueArgs.OutputType, "internal.matlab.importtool.server.output.OutputType")} = internal.matlab.importtool.server.output.TableOutputType;
                NameValueArgs.VarName {mustBeA(NameValueArgs.VarName, ["string", "char", "cell"])} = "";
            end

            % Generate the function code.  This will always contain creation of
            % an importOptions object.
            if isempty(NameValueArgs.DataLines)
                NameValueArgs.DataLines = {imopts.DataLines};
            end
            
            opts = NameValueArgs.OutputType.updateImportOptionsForOutputType(imopts);
            code = generateFunctionFromArgs(this, opts, NameValueArgs);
        end

        function code = generateShortCircuitCode(this, args, imopts)
            % Try to geneate code using just a single readtable or readtimetable
            % line.  This can be done if the original import options we get from
            % detectImportOptions are equivalent to the import options being
            % used currently for the code generation operation.

            % Check the differences between the original detected import
            % options, and the current importOptions.
            diffs = internal.matlab.importtool.server.TextCodeGenerator.isequalOpts(args.OriginalOpts, imopts);

            % start building up the line of code
            if isa(args.OutputType, "internal.matlab.importtool.server.output.TableOutputType")
                fcn = "readtable";
            else
                fcn = "readtimetable";
            end
            code = args.VarName + " = " + fcn + "(""" + args.Filename + """";

            % Specify the text type if any text data is being imported
            if any(strcmp(imopts.VariableTypes, "string"))
                codeEnd = ", ""TextType"", ""string"")";
            else
                codeEnd = ")";
            end

            if ~this.showLastOutput
                codeEnd = codeEnd + ";";
            end

            codeArgs = "";
            shortCircuit = false;

            if isempty(diffs)
                shortCircuit = true;
            end

            % Handle timetable options for defaulting to either the specified
            % column, or the default timestep of 1 second step.
            if isa(args.OutputType, "internal.matlab.importtool.server.output.TimeTableOutputType")
                if args.OutputType.RowTimesType == "column"
                    codeArgs = codeArgs + ", ""RowTimes"", """ + args.OutputType.RowTimesColumn + """";
                elseif args.OutputType.RowTimesType == "timestep" && ...
                        args.OutputType.RowTimesValue == 1 && ...
                        args.OutputType.RowTimesUnits == "seconds"
                    % Support default timestep
                    codeArgs = codeArgs + ", ""TimeStep"", seconds(1)";
                else
                    shortCircuit = false;
                end
            end

            if shortCircuit && isempty(diffs)
                code = "% " + gs("Codgen_TextScriptHeader") + newline + code + codeArgs + codeEnd;
                code = split(code, newline);
            else
                code = strings(0);
            end
        end
    end
    
    methods(Access = private)
        function generateScriptHeader(~, codepub, filename)
            % Generate the script Header
            codepub.bufferCode("importtool", "%% " + gs("Codgen_TextScriptHeader"));
            codepub.bufferCode("importtool", "% " + gs("Codgen_TextScriptHeader2"));
            codepub.bufferCode("importtool", "%")
            
            % The header includes the filename and sheetname
            codepub.bufferCode("importtool", "%    " + gs("Codgen_FileNameHeader", filename));
            codepub.bufferCode("importtool", "%")
            
            % Generate the auto-generated line with the date
            codepub.bufferCode("importtool", "% " + gs("Codgen_AutoGenHeader", char(datetime('now'))) + newline);
        end
        
        function generateFunctionHeader(this, codepub, functionname, imopts, args, startRow, endRow, outputType)
            % Generate function header
            if isa(args.OutputType, 'internal.matlab.importtool.server.output.ColumnVectorOutputType')
                if ~isscalar(imopts.SelectedVariableNames)
                    outputVarName = "[" + strjoin(imopts.SelectedVariableNames, ", ") + "]";
                else
                    outputVarName = imopts.SelectedVariableNames;
                end
            else
                outputVarName = args.VarName;
            end
            
            codepub.bufferCode("importtool", "function " + outputVarName + " = " + ...
                functionname + "(filename, dataLines)");
            codepub.bufferCode("importtool", "    %" + gs("Codgen_TextFuncHeader", upper(functionname)));
            commentBegin = "    %  ";
            
            % Generate help on calling the function with one arg (filename)
            s = upper(outputVarName) + " = " + gs("Codgen_TextFuncFileArg", upper(functionname)) + ...
                "  " + args.OutputType.getFunctionHeaderCode();
            s = this.splitStringToLength(s, 70);
            s = commentBegin + s;
            codepub.bufferCode("importtool", s);
            codepub.bufferCode("importtool", commentBegin);           

            % Generate help on calling the function with all args (filename,
            % start row and end row)
            s = upper(outputVarName) + " = " + gs("Codgen_TextFuncAllArgs", upper(functionname));
            s = this.splitStringToLength(s, 70);
            s = commentBegin + s;
            codepub.bufferCode("importtool", s);
            codepub.bufferCode("importtool", commentBegin);
            
            % Generate example on how to call the function
            codepub.bufferCode("importtool", commentBegin + gs("Codgen_FuncExample"));
            codepub.bufferCode("importtool", commentBegin + outputVarName + " = " + ...
                functionname + "(""" + args.Filename + """, [" + ...
                num2str(startRow) + ", " + num2str(endRow) + "]);");
            codepub.bufferCode("importtool", commentBegin);
            
            this.generateSeeAlsoAndDate(codepub, commentBegin, outputType);
        end
        
        function generateFunctionInputHandling(~, codepub, startRow, endRow)
            % Generate function input handling section
            codepub.bufferCode("importtool", "%% " + gs("Codgen_FuncInputHandling"));
            codepub.bufferCode("importtool", "");
           
            % If both start row and end row are not provided, use the values
            % selected when the function was generated
            codepub.bufferCode("importtool", "% " + gs("Codgen_TextFuncInputHandlingRows"));
            codepub.bufferCode("importtool", "if nargin < 2");
            codepub.bufferCode("importtool", "dataLines = [" + num2str(startRow) + ", " +  num2str(endRow) + "];");
            codepub.bufferCode("importtool", "end");
            codepub.bufferCode("importtool", "");
        end
        
        function generateDataLines(this, codepub, dataLines)
            % Generate the DataLines lines of code
            if this.functionGeneration
                codepub.bufferCode("importtool", this.opts + ".DataLines = dataLines;");
            elseif isscalar(dataLines)
                codepub.bufferCode("importtool", this.opts + ".DataLines = [" + ...
                    dataLines{1}(1) + ", " + dataLines{1}(end) + "];")
            else
                % handle multiple ranges
                buf = this.opts + ".DataLines = [";
                for idx = 1:length(dataLines)
                    buf = buf + dataLines{idx}(1) + ", " + dataLines{idx}(end);
                    
                    if idx < length(dataLines)
                        buf = buf + "; ";
                    end
                end
                codepub.bufferCode("importtool", buf + "];");
            end
        end
        
        function generateDelimiter(this, codepub, delimiter)
            arguments
                this
                codepub internal.matlab.datatoolsservices.CodePublishingService
                delimiter cell
            end
            
            % Generate code for the delimiter(s)
            if ~isempty(delimiter)
                delimiterStr = internal.matlab.importtool.server.TextCodeGenerator.getDelimiterStr(delimiter);
                codepub.bufferCode("importtool", this.opts + ".Delimiter = " + delimiterStr + ";");
            end
        end
        
        function generateFixedWidthVarWidths(this, codepub, varWidths)
            % Generate code for the variable widths
            if isscalar(varWidths)
                codepub.bufferCode("importtool", this.opts + ...
                    ".VariableWidths = " + varWidths + ";");
            else
                varWidths = strjoin(string(varWidths), ", ");
                codepub.bufferCode("importtool", this.opts + ...
                    ".VariableWidths = [" + varWidths + "];");
            end
        end
        
        function columnVarTypes = generateConstructorAndOptions(this, codepub, imopts, args)

            % Generates the initial import options object
            codepub.bufferCode("importtool", "%% " + gs("Codgen_SetupImportOptions"));
            
            cols = find(ismember(imopts.VariableNames, imopts.SelectedVariableNames));

            % Assign the variable types for the selected columns to
            % that which is specified by the client
            varTypes = repmat(string(args.DefaultTextType), 1, length(imopts.VariableNames));
            varTypes(cols) = imopts.VariableTypes(cols);
            columnVarTypes = varTypes;
            imopts.VariableTypes = varTypes;
            
            % Add in the file encoding, if it is set in the import options
            if isempty(imopts.Encoding)
                encodingStr = "";
            else
                encodingStr = ", ""Encoding"", """ + imopts.Encoding + """";
            end
            
            if this.isFixedWidth
                % Generate the Fixed Width object constructor, data lines and
                % variable widths code
                codepub.bufferCode("importtool", this.opts + " = fixedWidthImportOptions" + ...
                    "(""NumVariables"", " + length(columnVarTypes) + encodingStr + ");");

                codepub.bufferCode("importtool", newline + "% " + gs("Codgen_RangeWidths"));
                this.generateDataLines(codepub, args.DataLines);
                this.generateFixedWidthVarWidths(codepub, imopts.VariableWidths);
            else
                % Generate the Delimited import object constructor, data lines
                % and delimiter code
                codepub.bufferCode("importtool", this.opts + " = delimitedTextImportOptions" + ...
                    "(""NumVariables"", " + length(columnVarTypes) + encodingStr + ");");
                
                codepub.bufferCode("importtool", newline + "% " + gs("Codgen_RangeDelimiter"));
                this.generateDataLines(codepub, args.DataLines);
                this.generateDelimiter(codepub, imopts.Delimiter);
            end
            
            codepub.bufferCode("importtool", newline + "% " + gs("Codgen_ColNamesTypes"));
            this.generatePreserveVariableNames(codepub, imopts);
            this.generateVariableNames(codepub, imopts);
            
            % Generate the code for the Variable Types and associated settings,
            % like the datetime format for example
            this.generateVariableTypesCode(codepub, imopts); 
        end
                
        function v = getTrimNonNumeric(~, varopt)
            if isprop(varopt, "TrimNonNumeric")
                v = varopt.TrimNonNumeric;
            else
                v = false;
            end
        end
        
        function generateReadtableCode(this, codepub, filename, varName, outputType)
            % Generate the Readtable (or read* function) code.           
            codepub.bufferCode("importtool", newline + "% " + gs("Codgen_ImportData"));

            % Get the read* function name and generate the code using it
            fcnName = outputType.getImportFunctionName();
            additionalArgs = outputType.getAdditionalArgsForCodeGen();
            
            codeStr = "" + varName + " = " + fcnName + "(" + filename + ", " + this.opts;
            if isempty(additionalArgs)
                codeStr = codeStr + ")";
            else
                codeStr = codeStr + ", " + additionalArgs + ")";
            end

            if this.showLastOutput && ~outputType.requiresOutputConversion()
                % If we want to show the last output, leave off the
                % semi-colon from the call which is performing the import.
                % For example:  t = readtable(filename, opts)
                codepub.bufferCode("importtool",  codeStr + newline)
            else
                codepub.bufferCode("importtool",  codeStr + ";" + newline)
            end
        end
        
        function code = generateScriptFromArgs(this, imopts, args)
            % Get an instance of the CodePublishing Service
            codepub = internal.matlab.datatoolsservices.CodePublishingService.getInstance;
            
            % Remove any code that may be there already.
            codepub.discardCode("importtool");
            
            % Generate the header
            this.generateScriptHeader(codepub, args.Filename);
            
            this.isFixedWidth = isa(imopts, "matlab.io.text.FixedWidthImportOptions");

            % Update the outputType with the current showLastOutput setting.
            args.OutputType.showLastOutput = this.showLastOutput;
            args.Filename = """" + args.Filename + """";
            generateCode(this, codepub, imopts, args);
            
            % Generate code which clears the local variables
            this.clearVariables(codepub);
            
            % Get the code from the CodePublishing Service
            code = codepub.getCode('importtool');
        end

        function code = generateFunctionFromArgs(this, imopts, args)
            % Get an instance of the CodePublishing Service
            codepub = internal.matlab.datatoolsservices.CodePublishingService.getInstance;
            
            % Remove any code that may be there already.
            codepub.discardCode("importtool");
            
            startRow = args.DataLines{1}(1);
            endRow = args.DataLines{1}(end);

            % Set function generation mode to true
            this.functionGeneration = true;
            
            % Determine function name
            if isempty(args.FunctionName)
                % Use the function name importfile, adding a suffix index to
                % make it unique, if necessary.
                baseFileName = "importfile";
                fname = baseFileName;
                if exist(fname + ".m", 'file') == 2
                    idx = 1;
                    fname = baseFileName + num2str(idx);
                    while exist(fname + ".m", 'file') == 2
                        idx = idx + 1;
                        fname = baseFileName + num2str(idx);
                    end
                end
            else
                % Use the user-supplied function name (but run through
                % makeValidName to assure we have something valid)
                fname = matlab.lang.makeValidName(args.FunctionName);
            end
            
            this.isFixedWidth = isa(imopts, "matlab.io.text.FixedWidthImportOptions");

            % Generate the header
            this.generateFunctionHeader(codepub, fname, imopts, args, startRow, endRow, args.OutputType);

            % If the last row of the selection is the same as the initial
            % selection's last row, or if the last row is Inf, or there are
            % multiple ranges, then generate the default last row as Inf.
            % Otherwise, the user has selected a range of the file (like rows
            % 5-8 in a 10 row file).  In this case, generate the end row the
            % same as the user's selection.
            if isempty(args.InitialSelection) || endRow == args.InitialSelection(3) || ...
                    isinf(endRow) || ~isscalar(args.DataLines)
                endRow = Inf;
            end
            this.generateFunctionInputHandling(codepub, startRow, endRow);

            args.Filename = "filename";
            generateCode(this, codepub, imopts, args);            
            % End the function
            codepub.bufferCode("importtool", "end");

            % Get the code from the CodePublishing Service
            code = codepub.getCode('importtool');
        end
        
        function generateCode(this, codepub, imopts, args)

            % Save variables to clear.  At the very least, the variable 'opts'
            % will be generated, as this is used for the Import Options object.
            if isempty(args.VarName) || (iscell(args.VarName) && isscalar(args.VarName) && isempty(args.VarName{1}))
                args.VarName = matlab.lang.makeUniqueStrings("tbl", imopts.VariableNames);
                this.opts = this.getUniqueVarName(this.opts, [args.VarName, imopts.VariableNames]);
            else
                this.opts = this.getUniqueVarName(this.opts, args.VarName);
            end

            % Generate the initial Import Options Object and options
            imopts.VariableTypes = this.generateConstructorAndOptions(codepub, imopts, args);
            
            % Keep track of the column data types
            doubleColumns = cellfun(@(x) x == "double", imopts.VariableTypes);

            % Generate file level and setvaropts properties
            this.generateFileLevelProperties(codepub, imopts, doubleColumns, false);
            this.generateSetVarOptsCode(codepub, imopts, imopts.VariableTypes);

            % Generate the readtable code
            this.generateReadtableCode(codepub, args.Filename, args.VarName, args.OutputType);

            % Convert the table to the appropriate output data type
            this.convertToOutputType(codepub, args.VarName, args.OutputType, imopts);
        end
    end
    
    methods(Access = protected)
        function commentAdded = generateSetVarOptsCode(this, codepub, imopts, columnVarTypes)
            commentAdded = generateSetVarOptsCode@internal.matlab.importtool.server.TabularCodeGenerator(this, codepub, imopts, columnVarTypes);
            
            dblColumns = cellfun(@(x) x == "double", columnVarTypes);
            if any(dblColumns)
                % Only generate code for TrimNonNumeric for those columns
                % which have it set.  (Setting this for every double
                % column, although will produce correct result, is overkill
                % for the generatated code)
                trimNonNumericCols = arrayfun(@this.getTrimNonNumeric, imopts.VariableOptions);
                if any(trimNonNumericCols)
                    commentAdded = this.addSetVarOptsHeaderComment(codepub, commentAdded);
                    trimNonNumericColsStr = getColumnsAsText(this, trimNonNumericCols, imopts.VariableNames);
                    codepub.bufferCode("importtool", this.opts + " = setvaropts(" + ...
                        this.opts + ", " + trimNonNumericColsStr + ", ""TrimNonNumeric"", true);")
                end
                
                % Decimal separator only needs to be specified if it is
                % off-default.  The Import Tool currently only lets the
                % user choose this on a global level, so just check one of
                % the VariableOptions.
                dblColOptions = imopts.VariableOptions(dblColumns);
                dblColumnsStr = getColumnsAsText(this, dblColumns, imopts.VariableNames);
                if ~isempty(dblColOptions(1).DecimalSeparator) && ...
                        ~isequal(dblColOptions(1).DecimalSeparator, ".")
                    commentAdded = this.addSetVarOptsHeaderComment(codepub, commentAdded);
                    codepub.bufferCode("importtool", this.opts + " = setvaropts(" + ...
                        this.opts + ", " + dblColumnsStr + ", ""DecimalSeparator"", """ + ...
                        dblColOptions(1).DecimalSeparator + """);");
                end
                
                % Set the ThousandsSeparator for any columns where the
                % TrimNonNumeric setting is set.  The rationale is that the
                % TrimNonNumeric will be set for any column not originally
                % detected as numeric.  Because it was not detected as
                % numeric, it can contain any content, so we should add in
                % the ThousandsSeparator just in case.  Also set the thousands
                % separator for numeric columns where the separator was detected
                % previously
                allThousandsSep = unique(string({dblColOptions(:).ThousandsSeparator}));
                allThousandsSep(allThousandsSep == "") = [];
                
                if ~isempty(allThousandsSep)
                    commentAdded = this.addSetVarOptsHeaderComment(codepub, commentAdded);
                    if any(trimNonNumericCols)
                        codepub.bufferCode("importtool", this.opts + " = setvaropts(" + ...
                            this.opts + ", " + trimNonNumericColsStr + ", ""ThousandsSeparator"", """ + ...
                            allThousandsSep(1) + """);");
                    else
                        codepub.bufferCode("importtool", this.opts + " = setvaropts(" + ...
                            this.opts + ", " + dblColumnsStr + ", ""ThousandsSeparator"", """ + ...
                            allThousandsSep(1) + """);");
                    end
                end
            end
        end
        
        function commentAdded = generateFileLevelProperties(this, codepub, imopts, doubleColumns, addTreatAsMissing)
            commentAdded = generateFileLevelProperties@internal.matlab.importtool.server.TabularCodeGenerator(this, codepub, imopts, doubleColumns, addTreatAsMissing);
            
            commentAdded = this.addFileLevelPropertiesComment(codepub, commentAdded);
            codepub.bufferCode("importtool", this.opts + ".ExtraColumnsRule = ""ignore"";");
            codepub.bufferCode("importtool", this.opts + ".EmptyLineRule = ""read"";");
            
            if ~this.isFixedWidth
                % Generate delimited text specific settings
                
                % Set the Consecutive Delimiters Rules if it is off-default
                if ~isempty(imopts.ConsecutiveDelimitersRule) && ...
                        ~isequal(imopts.ConsecutiveDelimitersRule, "split")
                    codepub.bufferCode("importtool", this.opts + ".ConsecutiveDelimitersRule = """ + ...
                        imopts.ConsecutiveDelimitersRule + """;");
                end
                
                if isequal(imopts.Delimiter, {' '})
                    % Set LeadingDelimitersRule to 'ignore' for when space is the
                    % delimiter.  ('keep' is the default when constructing an
                    % options object like is done in the generated code)
                    codepub.bufferCode("importtool", this.opts + ...
                        ".LeadingDelimitersRule = ""ignore"";");
                end
            end
        end
    end

    methods(Static)
        function b = isequalOpts(opts1, opts2)
            % Compares a subset of the properties of two
            % DelimitedTextImportOptions objects to check for differences.
            % Returns a string array containing the properties which differ.
            % Only a subset is compared because the import infrastructure only
            % sets certain properties, so we don't want to flag differences in
            % properties like WhitespaceRule, which won't be set.
            propsToCheck = ["Delimiter", "ConsecutiveDelimitersRule", "MissingRule", "ImportErrorRule", "DataLines", "VariableNames", "SelectedVariableNames", "VariableTypes"];
            notEqualProps = cellfun(@(fld) ~isequal(opts1.(fld), opts2.(fld)), propsToCheck);
            b = propsToCheck(notEqualProps);
            if ~any(strcmp(b, "VariableTypes"))
                % If the types are the same, look for difference in
                % type-specific properties.  Currently, we only look for
                % TrimNonNumric.
                numericTypes = strcmp(opts1.VariableTypes, "double");
                if any(numericTypes)
                    trim1 = opts1.VariableOptions(numericTypes);
                    trim2 = opts2.VariableOptions(numericTypes);
                    if ~isequal([trim1.TrimNonNumeric], [trim2.TrimNonNumeric])
                        b = [b "TrimNonNumeric"];
                    end
                end
            end
        end

        function delimiterStr = getDelimiterStr(delimiter)
            % Returns the delimiter text string to use in the generated code,
            % given the current delimiter

            % Handle delimiter which is a double-quote
            quoteIdx = cellfun(@(d) strcmp(d, '"'), delimiter);
            if any(quoteIdx)
                delimiter{quoteIdx} = '""';
            end

            if isscalar(delimiter)
                delimiterStr = """" + delimiter + """";
            else
                delimiterStr = strjoin(delimiter, """, """);
                delimiterStr = "[""" + delimiterStr + """]";
            end
        end
    end
end

function s = gs(msg, varargin)
    % Convenience function to get a string from the Import Tool message catalog.
    % This is just to have a short name in the code, so the code is more
    % readable.
    s = internal.matlab.importtool.server.ImportUtils.getImportToolMsgFromTag(msg, varargin{:});
end
