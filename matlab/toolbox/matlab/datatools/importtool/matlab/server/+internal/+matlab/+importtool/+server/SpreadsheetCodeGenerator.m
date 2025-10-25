classdef SpreadsheetCodeGenerator < internal.matlab.importtool.server.TabularCodeGenerator
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % This class is the code generator class for Spreadsheet Import.
    
    % Copyright 2018-2024 The MathWorks, Inc.
    
    properties
        UseExcelDefault = "false";
    end

    properties(Access = private)
        % Name of the variable in the code which represents the index of the last row of data in the
        % data range
        lastRowDataVar string;
    end
    
    methods
        function this = SpreadsheetCodeGenerator(showLastOutput)
            arguments
                showLastOutput (1,1) logical = false
            end

            % Creates a SpreadsheetCodeGenerator instance.  
            this.showLastOutput = showLastOutput;
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
                NameValueArgs.DefaultTextType {mustBeMember(NameValueArgs.DefaultTextType, ["string", "char"])} = "string";
                NameValueArgs.Filename {mustBeA(NameValueArgs.Filename, ["string", "char", "cell"])} = "";
                NameValueArgs.InitialSelection {mustBeA(NameValueArgs.InitialSelection, "double")} = [];
                NameValueArgs.InitialSheet {mustBeTextScalar} = "";
                NameValueArgs.NumRows double = [];
                NameValueArgs.OriginalOpts = [];
                NameValueArgs.OutputType {mustBeA(NameValueArgs.OutputType, "internal.matlab.importtool.server.output.OutputType")} = internal.matlab.importtool.server.output.TableOutputType;
                NameValueArgs.Range {mustBeA(NameValueArgs.Range, ["double", "string", "char", "cell"])} = strings(0);
                NameValueArgs.VarName {mustBeA(NameValueArgs.VarName, ["string", "char", "cell"])} = "";
            end

            if isempty(NameValueArgs.Range)
                NameValueArgs.Range = imopts.DataRange;
            end
            this.initUseExcelDefault(NameValueArgs);
            
            code = [];
            codeDescription = struct("containsImportOptions", true);

            % Try to short-circuit code generation if ShortCircuitCode, and both
            % the original detected importOptions and current importOptions are
            % spreadsheet options, and the output is table or timetable.
            if this.eligibleForShortCircuit(NameValueArgs, imopts, "matlab.io.spreadsheet.SpreadsheetImportOptions")
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
            % Generate the function code.  This will always contain creation of
            % an importOptions object.

            arguments
                this
                imopts
                NameValueArgs.ArbitraryVarNames {mustBeNumericOrLogical} = false;
                NameValueArgs.DefaultTextType {mustBeMember(NameValueArgs.DefaultTextType, ["string", "char"])} = "string";
                NameValueArgs.Filename {mustBeA(NameValueArgs.Filename, ["string", "char", "cell"])} = "";
                NameValueArgs.FunctionName {mustBeText} = strings(0);
                NameValueArgs.InitialSelection double = [];
                NameValueArgs.InitialSheet {mustBeTextScalar} = "";
                NameValueArgs.NumRows double = [];
                NameValueArgs.OriginalOpts = [];
                NameValueArgs.OutputType {mustBeA(NameValueArgs.OutputType, "internal.matlab.importtool.server.output.OutputType")} = internal.matlab.importtool.server.output.TableOutputType;
                NameValueArgs.Range {mustBeA(NameValueArgs.Range, ["double", "string", "char", "cell"])} = strings(0);
                NameValueArgs.VarName {mustBeA(NameValueArgs.VarName, ["string", "char", "cell"])} = "";
            end
            
            if isempty(NameValueArgs.Range)
                NameValueArgs.Range = imopts.DataRange;
            end
            this.initUseExcelDefault(NameValueArgs);
            
            opts = NameValueArgs.OutputType.updateImportOptionsForOutputType(imopts);
            code = generateFunctionFromArgs(this, opts, NameValueArgs);
        end

        function code = generateShortCircuitCode(this, args, imopts)
            % Try to generate code using just a single readtable or readtimetable
            % line.  This can be done if the original import options we get from
            % detectImportOptions are equivalent to the import options being
            % used currently for the code generation operation.

            % Check the differences between the original detected import
            % options, and the current importOptions.

            diffs = internal.matlab.importtool.server.SpreadsheetCodeGenerator.isequalOpts(args.OriginalOpts, imopts);

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

            % Handle some differences in DataRange, particularly in that
            % detectImportOptions sets just the first cell ("A1" for example),
            % while the range for the current import will be fully specified
            % ("A1:D100", for example)
            if any(strcmp(diffs, "DataRange")) && (isStringScalar(args.Range) || ischar(args.Range))
                diffs(strcmp(diffs, "DataRange")) = [];
                if isempty(strfind(args.OriginalOpts.DataRange, ":"))
                    % detectImportOptions may only fill in the start cell, see
                    % if this selection is the same as the initial one
                    % determined by the Import Tool
                    [startRow, startCol] = internal.matlab.importtool.server.ImportUtils.excelRangeToMatlab(args.OriginalOpts.DataRange);
                    initialRange = internal.matlab.importtool.server.ImportUtils.toExcelRange(startRow, args.InitialSelection(3), startCol, args.InitialSelection(4));
                    if strcmp(imopts.DataRange, initialRange)
                        shortCircuit = true;
                    end
                end
            end

            % Add in the sheet if it isn't the first (default) sheet
            if ~strcmp(args.InitialSheet, imopts.Sheet)
                shortCircuit = true;
                codeArgs = codeArgs + ", ""Sheet"", """ + imopts.Sheet + """";
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
                code = "% " + gs("Codgen_ScriptHeader") + newline + code + codeArgs + codeEnd;
                code = split(code, newline);
            else
                code = strings(0);
            end
        end
    end
    
    methods(Access = private)
        function generateScriptHeader(~, codepub, filename, sheetname)
            % Generate the script Header
            codepub.bufferCode("importtool", "%% " + gs("Codgen_ScriptHeader"));
            codepub.bufferCode("importtool", "% " + gs("Codgen_ScriptHeader2"));
            codepub.bufferCode("importtool", "%")
            
            % The header includes the filename and sheetname
            codepub.bufferCode("importtool", "%    " + gs("Codgen_WorkbookHeader", filename));
            codepub.bufferCode("importtool", "%    " + gs("Codgen_WorksheetHeader", sheetname));
            codepub.bufferCode("importtool", "%")
            
            % Generate the auto-generated line with the date
            codepub.bufferCode("importtool", "% " + gs("Codgen_AutoGenHeader", char(datetime('now'))) + newline);
        end
        
        function generateFunctionHeader(this, codepub, functionname, imopts, args, startRow, endRow, outputType)
            % Generate function header
            if isa(args.OutputType, 'internal.matlab.importtool.server.output.ColumnVectorOutputType')
                outputVarName = "[" + strjoin(imopts.SelectedVariableNames, ", ") + "]";
            else
                outputVarName = args.VarName;
            end
            
            codepub.bufferCode("importtool", "function " + outputVarName + " = " + ...
                functionname + "(workbookFile, sheetName, dataLines)");
            codepub.bufferCode("importtool", "    %" + gs("Codgen_FuncHeader", upper(functionname)));
            commentBegin = "    %  ";
            
            % Generate help on calling the function with one arg (filename)
            s = upper(outputVarName) + " = " + gs("Codgen_FuncFileArg", upper(functionname)) + ...
                "  " + args.OutputType.getFunctionHeaderCode();
            s = this.splitStringToLength(s, 70);
            s = commentBegin + s;
            codepub.bufferCode("importtool", s);
            codepub.bufferCode("importtool", commentBegin);
            
            % Generate help on calling the function with two args (filename and
            % sheet)
            s = upper(outputVarName) + " = " + gs("Codgen_FuncFileSheetArg", upper(functionname));
            s = this.splitStringToLength(s, 70);
            s = commentBegin + s;
            codepub.bufferCode("importtool", s);
            codepub.bufferCode("importtool", commentBegin);
            
            % Generate help on calling the function with all args (filename,
            % sheetname, start row and end row)
            s = upper(outputVarName) + " = " + gs("Codgen_FuncAllArgs", upper(functionname));
            s = this.splitStringToLength(s, 70);
            s = commentBegin + s;
            codepub.bufferCode("importtool", s);
            codepub.bufferCode("importtool", commentBegin);
            
            % Generate example on how to call the function
            codepub.bufferCode("importtool", commentBegin + gs("Codgen_FuncExample"));
            codepub.bufferCode("importtool", commentBegin + outputVarName + " = " + ...
                functionname + "(""" + args.Filename + """, """ + imopts.Sheet + """, [" + ...
                num2str(startRow) + ", " + num2str(endRow) + "]);");
            codepub.bufferCode("importtool", commentBegin);
            
            this.generateSeeAlsoAndDate(codepub, commentBegin, outputType);
        end
        
        function generateFunctionInputHandling(this, codepub, sheetVarName, defaultSheetName, startRow, endRow, args)
            % Generate function input handling section
            codepub.bufferCode("importtool", "%% " + gs("Codgen_FuncInputHandling"));
            codepub.bufferCode("importtool", "");
            codepub.bufferCode("importtool", "% " + gs("Codgen_FuncInputHandlingSheet", defaultSheetName));
            
            % If no sheetname is provided, use 1
            codepub.bufferCode("importtool", "if nargin == 1 || isempty(" + sheetVarName + ")");
            codepub.bufferCode("importtool", sheetVarName + " = """ + defaultSheetName + """;");
            codepub.bufferCode("importtool", "end");
            codepub.bufferCode("importtool", "");
            
            % If both start row and end row are not provided, use the values selected when the
            % function was generated.  This is in an if statement to track if the dataLines contains
            % the last row of data.  (When it contains the last row, the range can be specified
            % without the end portion, for example just "A3").
            this.lastRowDataVar = this.getUniqueVarName("lastRowOfDataIdx", args.VarName);
            codepub.bufferCode("importtool", "% " + gs("Codgen_FuncInputHandlingRows"));
            codepub.bufferCode("importtool", this.lastRowDataVar + " = 0;");
            codepub.bufferCode("importtool", "if nargin <= 2");
            codepub.bufferCode("importtool", "dataLines = [" + num2str(startRow) + ", " + num2str(endRow) + "];");
            codepub.bufferCode("importtool", this.lastRowDataVar + " = 1;");
            codepub.bufferCode("importtool", "elseif dataLines(end,2) >= " + endRow);
            codepub.bufferCode("importtool", this.lastRowDataVar + " = size(dataLines, 1);");
            codepub.bufferCode("importtool", "end");
            codepub.bufferCode("importtool", "");
        end
        
        function generateSheetAndRange(this, codepub, sheetname, range)            
            % Import with the specified data range.
            [dataRange, isSingleRange] = this.getRangeInfoFromRanges(range);

            if ~isSingleRange && ~this.functionGeneration
                % Generate the SheetName only.  The data range will be in a loop
                % later on.
                codepub.bufferCode("importtool", newline + "% " + gs("Codgen_Sheet"));
                codepub.bufferCode("importtool", this.opts + ".Sheet = " + sheetname + ";")
            else
                % Generate the SheetName and DataRange lines of code
                codepub.bufferCode("importtool", newline + "% " + gs("Codgen_SheetRange"));
                codepub.bufferCode("importtool", this.opts + ".Sheet = " + sheetname + ";")
                
                if this.functionGeneration
                    % Setup the DataRange for the function.  This is in an if statement to track if
                    % the dataLines contains the last row of data.  (When it contains the last row,
                    % the range can be specified without the end portion, for example just "A3").
                    [this.functionRange, firstCol] = this.getFunctionRangeFromDataRange(dataRange);
                    codepub.bufferCode("importtool", "if " + this.lastRowDataVar + " == 1")
                    codepub.bufferCode("importtool", this.opts + ".DataRange = """ + firstCol + """ + dataLines(1, 1);");
                    codepub.bufferCode("importtool", "else")
                    codepub.bufferCode("importtool", this.opts + ".DataRange = " + this.functionRange + ";")
                    codepub.bufferCode("importtool", "end")
                else
                    codepub.bufferCode("importtool", this.opts + ".DataRange = """ + dataRange + """;")
                end
            end
        end

        function [fcnRange, firstCol, lastCol] = getFunctionRangeFromDataRange(~, dataRange)
            % Returns the function range to use, given a data range.  Function
            % generation uses the same columns as the dataRange, but uses
            % variable names for the start and end rows of the range.  For
            % example, given the range:  "B4:D10"
            % Returns:  "B" + startRow(1) + ":D" + endRow(1)
            ranges = split(dataRange(1), ":");
            firstCol = char(ranges(1));
            lastCol = char(ranges(2));
            
            firstCol = firstCol(isstrprop(firstCol, 'alpha'));
            lastCol = lastCol(isstrprop(lastCol, 'alpha'));
            
            fcnRange = """" + firstCol + """ + dataLines(1, 1) + "":" + ...
                lastCol + """ + dataLines(1, 2)";
        end
        
        function columnVarTypes = generateInitialSpreadsheetOptions(this, codepub, imopts, args)
            % Generates the initial SpreadsheetImportOptions object, specifying
            % the sheet name and variable names.
            codepub.bufferCode("importtool", "%% " + gs("Codgen_SetupImportOptions"));
            
            codepub.bufferCode("importtool", this.opts + " = spreadsheetImportOptions(""NumVariables"", " + length(imopts.VariableTypes) + ");");
            
            this.generateSheetAndRange(codepub, args.Sheet, args.Range)
            
            codepub.bufferCode("importtool", newline + "% " + gs("Codgen_ColNamesTypes"));
            this.generatePreserveVariableNames(codepub, imopts);
            this.generateVariableNames(codepub, imopts);
            
            % Import using the specified data types
            this.generateVariableTypesCode(codepub, imopts);
            
            columnVarTypes = imopts.VariableTypes;
        end

        function generateReadtableCode(this, codepub, filename, varName, range, outputType)
            % Generate the Readtable code.  Specify UseExcel false for better
            % performance.           
            [ranges, isSingleRange] = this.getRangeInfoFromRanges(range);
            
            % Range is a char like: 'A4:C100', or a cell array with a single
            % value in it.
            codepub.bufferCode("importtool", newline + "% " + gs("Codgen_ImportData"));
            
            % Get the read* function name and generate the code using it
            fcnName = outputType.getImportFunctionName();
            additionalArgs = outputType.getAdditionalArgsForCodeGen();

            if isSingleRange || this.functionGeneration || isscalar(ranges)
                codeStr = "" + varName + " = " + fcnName + "(" + filename + ", " + ...
                    this.opts + ", ""UseExcel"", " + this.UseExcelDefault;
                if isempty(additionalArgs)
                    codeStr = codeStr + ")";
                else
                    codeStr = codeStr + ", " + additionalArgs + ")";
                end

                if this.showLastOutput && ~outputType.requiresOutputConversion()
                    % If we want to show the last output, leave off the
                    % semi-colon from the call to readtable.  For example:
                    % t = readtable(filename, opts)
                    codepub.bufferCode("importtool",  codeStr + newline)
                else
                    codepub.bufferCode("importtool",  codeStr + ";" + newline)
                end
            end
            
            if (~ischar(ranges) && length(ranges) > 1) || this.functionGeneration
                % For numerous ranges, use a loop:  
                % ranges = ["A6:C7", "A9:C10"];
                % for r = 1:length(ranges)
                %     i.DataRange = ranges(r);
                %     tb = readtable("sample.xlsx", i, "UseExcel", false);
                %     s = [s; tb]; %#ok<AGROW>
                % end
                %
                % Also if this is function generation (and the range is an
                % expression), also use a loop:
                % for r = 2:length(startRow)
                %     opts.DataRange = "A" + startRow(r) + ":J" + endRow(r);
                %     tb = readtable(workbookFile, opts, "UseExcel", false);
                %     htvdata = [htvdata; tb]; %#ok<AGROW>
                % end

                rangesVar = this.getUniqueVarName("ranges", varName);
                if ~this.functionGeneration
                    defaultOutputType = outputType.getOutputTypeInitializerForCodeGen;
                    codepub.bufferCode("importtool", "" + varName + " = " + defaultOutputType + ";");
                    codepub.bufferCode("importtool", rangesVar + " = [""" + strjoin(ranges, """, """) + """];");
                end
                tbVar = this.getUniqueVarName("tb", varName);
                rIdxVar = this.getUniqueVarName("idx", varName);
                if this.functionGeneration
                    codepub.bufferCode("importtool", "for " + rIdxVar + " = 2:size(dataLines, 1)");
                    
                    % this.functionRange will be something like:
                    % "B" + startRow(1) + ":D" + endRow(1)
                    % So we need to replace the '1' with the loop index variable
                    codepub.bufferCode("importtool", "if " + rIdxVar + " == " + this.lastRowDataVar)
                    codepub.bufferCode("importtool", this.opts + ".DataRange = " + replace(extractBefore(this.functionRange, " + """), "(1", "(" + rIdxVar) + ";");
                    codepub.bufferCode("importtool", "else");
                    codepub.bufferCode("importtool", this.opts + ".DataRange = " + ...
                        replace(replace(this.functionRange, "1", rIdxVar), rIdxVar + ", " + rIdxVar, rIdxVar + ", 1") + ";");
                    codepub.bufferCode("importtool", "end");
                else
                    codepub.bufferCode("importtool", "for " + rIdxVar + " = 1:length(" + rangesVar + ")");
                    codepub.bufferCode("importtool", this.opts + ".DataRange = " + rangesVar + "(" + rIdxVar + ");");
                end
                
                codeStr = tbVar + " = " + fcnName + "(" + ...
                    filename + ", " + this.opts + ", ""UseExcel"", " + ...
                    this.UseExcelDefault;
                
                if isempty(additionalArgs)
                    codeStr = codeStr + ");";
                else
                    codeStr = codeStr + ", " + additionalArgs + ");";
                end
                
                codepub.bufferCode("importtool", codeStr);
                codepub.bufferCode("importtool", "" + varName + " = [" + varName + "; " + tbVar + "]; %#ok<AGROW>");
                codepub.bufferCode("importtool", "end" + newline);
            end
        end

        function initUseExcelDefault(this, args)
            % Excel formats of xlsb and ods require the use of Excel, so any
            % interactions with I/O functions should set "UseExcel" to true.
            % (The default is false for better performance and consistent
            % cross-platform support)
            [~, ~, extension] = fileparts(args.Filename);
            import internal.matlab.importtool.server.ImportUtils;
            if ImportUtils.requiresExcelForImport(extension)
                this.UseExcelDefault = "true";
            else
                this.UseExcelDefault = "false";
            end
        end
        
        function code = generateScriptFromArgs(this, imopts, args)
            % Get an instance of the CodePublishing Service
            codepub = internal.matlab.datatoolsservices.CodePublishingService.getInstance;
            
            % Remove any code that may be there already.
            codepub.discardCode("importtool");
            
            % Generate the header
            this.generateScriptHeader(codepub, args.Filename, imopts.Sheet);

            % Update the outputType with the current showLastOutput setting.
            args.OutputType.showLastOutput = this.showLastOutput;
            
            args.Filename = """" + args.Filename + """";
            args.Sheet = """" + imopts.Sheet + """";
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
            
            if iscell(args.Range)
                if iscell(args.Range{1})
                    rangeForVals = args.Range{1}{1};
                else
                    rangeForVals = args.Range{1};
                end
            else
                rangeForVals = args.Range;
            end
            rows = internal.matlab.importtool.server.ImportUtils.excelRangeToMatlab(rangeForVals);
            startRow = rows(1);
            endRow = rows(end);
            
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
            
            % Generate the header.  Use Inf as the end range if the end row is the same
            % as the initial selection (which is to the end of the file)
            if isempty(args.InitialSelection) || endRow == args.InitialSelection(3) || ...
                    isinf(endRow)
                endRow = Inf;
            end
            this.generateFunctionHeader(codepub, fname, imopts, args, startRow, endRow, args.OutputType);
            defaultSheetName = imopts.Sheet;
            imopts.Sheet = "sheetName";
            this.generateFunctionInputHandling(codepub, imopts.Sheet, defaultSheetName, startRow, endRow, args);
            
            args.Filename = "workbookFile";
            args.Sheet = imopts.Sheet;
            generateCode(this, codepub, imopts, args);            
            
            % End the function
            codepub.bufferCode("importtool", "end");

            % Get the code from the CodePublishing Service
            code = codepub.getCode('importtool');
        end
        
        function generateCode(this, codepub, imopts, args)

            % Save variables to clear.  At the very least, the variable 'opts'
            % will be generated, as this is used for the Spreadsheet Import
            % Options object.
            if isempty(args.VarName) || (iscell(args.VarName) && isscalar(args.VarName) && isempty(args.VarName{1}))
                args.VarName = matlab.lang.makeUniqueStrings("tbl", imopts.VariableNames);
                this.opts = this.getUniqueVarName(this.opts, [args.VarName, imopts.VariableNames]);
            else
                this.opts = this.getUniqueVarName(this.opts, args.VarName);
            end
            
            % Generate the initial Spreadsheet Options Object
            varTypes = this.generateInitialSpreadsheetOptions(codepub, imopts, args);
            
            % Keep track of the column data types
            doubleColumns = cellfun(@(x) x == "double", varTypes);

            % Generate file level and setvaropts properties
            this.generateFileLevelProperties(codepub, imopts, doubleColumns, true);
            this.generateSetVarOptsCode(codepub, imopts, imopts.VariableTypes);

            % Generate the readtable code
            this.generateReadtableCode(codepub, args.Filename, args.VarName, args.Range, args.OutputType);
            
            % Convert the table to the appropriate output data type
            this.convertToOutputType(codepub, args.VarName, args.OutputType, imopts);
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
            propsToCheck = ["Sheet", "MissingRule", "ImportErrorRule", "DataRange", "VariableNames", "SelectedVariableNames", "VariableTypes"];
            notEqualProps = cellfun(@(fld) ~isequal(opts1.(fld), opts2.(fld)), propsToCheck);
            b = propsToCheck(notEqualProps);
        end
    end
end

function s = gs(msg, varargin)
    % Convenience function to get a string from the Import Tool message catalog.
    % This is just to have a short name in the code, so the code is more
    % readable.
    s = internal.matlab.importtool.server.ImportUtils.getImportToolMsgFromTag(msg, varargin{:});
end
