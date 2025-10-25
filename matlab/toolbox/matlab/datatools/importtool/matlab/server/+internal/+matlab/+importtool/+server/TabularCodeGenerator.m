classdef (Abstract) TabularCodeGenerator < handle
    
    % This class is unsupported and might change or be removed without notice in
    % a future version.
    
    % This class is the common Code Generator class, used for Text and spreadsheet
    % Import
    
    % Copyright 2018-2025 The MathWorks, Inc.
    
    properties(Access = protected)
        % If true, the last line of code which produces an output will not have
        % a semi-colon on it, so that its output will be displayed when the code
        % is executed.
        showLastOutput logical = false;
        
        % Name of the SpreadsheetOptionsObject variable in the code
        opts string = "opts";
        
        % The variables that are currently in use, and need to be cleared at the
        % end of a script.
        varsToClear string = string.empty;
        
        % Whether the code generation taking place is in function mode or not
        functionGeneration logical = false;
        
        % The functionRange to use in the generated code, if generating
        % functions
        functionRange string = string.empty;
        
        AddFillValue logical = false;
        FillValue double = NaN;
        AddTreatAsMissing logical = false;
        SupportsPreserveDTFormat logical = false;
    end

    properties
        % If true, at attempt will be made to generate code which is a single
        % readtable/readtimetable line.
        ShortCircuitCode (1,1) logical = false;
    end
    
    methods(Access = protected)
        function s = splitStringToLength(this, str, len)
            % Utility function to split a string to a given length.  This is
            % needed to format the comments appropriately.
            idx = find(strlength(str) > len);
            for f = idx'
                for k = len:-1:1
                    if str{f}(k) == " "
                        str{f}(k) = newline;
                        break;
                    end
                end
            end
            s = split(join(str, newline), newline);
            
            if any(strlength(s) > len) && k ~= 1
                s = splitStringToLength(this, s, len);
            end
        end
        
        function colsAsText = getColumnsAsText(this, cols, varNames)
            % Returns the variable names for the specified columns, as text.
            % Brackets will be added if there is more than one element in cols.
            % For example, cols = [2,3], varNames = ["Var1", "Var2", "Var3"]
            % Returns:  "["Var2", "Var3"]"
            varNames = varNames(cols);
            
            % use getResolvedVarNames to resolve any special characters in the
            % variable names.
            colsAsText = this.getResolvedVarNames(varNames);
            colsAsText = strjoin(colsAsText, ", ");
            if length(varNames) > 1
                colsAsText = "[" + colsAsText + "]";
            end
        end
        
        function generateVariableTypesCode(this, codepub, imopts)
            % Generates code for setting the variable types along with the
            % associated variable options in import options
            columnVarTypes = imopts.VariableTypes;
            if isscalar(columnVarTypes)
                codepub.bufferCode("importtool", this.opts + ".VariableTypes = """ + columnVarTypes + """;")
            else
                codepub.bufferCode("importtool", this.opts + ".VariableTypes = [""" + strjoin(columnVarTypes, '", "') + """];")
            end
        end
        
        function commentAdded = generateFileLevelProperties(this, codepub, imopts, doubleColumns, addTreatAsMissing)
            % Setup rules in import options.  Some of the rules result in
            % setting the ImportErrorRule or MissingRule in the Spreadsheet
            % Import Options object.            
            defaultVal = "fill";
            commentAdded = false;
            
            importErrorRule = imopts.ImportErrorRule;
            missingRule = imopts.MissingRule;
            if any(doubleColumns)
                dblColOptions = imopts.VariableOptions(doubleColumns);
                fillValue = dblColOptions(1).FillValue;
            else
                fillValue = nan;
            end
            
            if ~isempty(importErrorRule) && importErrorRule ~= defaultVal
                commentAdded = this.addFileLevelPropertiesComment(codepub, commentAdded);
                codepub.bufferCode("importtool", this.opts + ".ImportErrorRule = """ + importErrorRule + """;");
            end
            if ~isempty(missingRule) && missingRule ~= defaultVal
                commentAdded = this.addFileLevelPropertiesComment(codepub, commentAdded);
                codepub.bufferCode("importtool", this.opts + ".MissingRule = """ + missingRule + """;");
            end
            
            if addTreatAsMissing
                % TreatAsMissing isn't necessary in all cases
                if ((~isempty(missingRule) && missingRule ~= defaultVal) || ...
                        (~isempty(importErrorRule) && importErrorRule ~= defaultVal)) ...
                        && any(doubleColumns)
                    this.AddTreatAsMissing = true;
                end
            end
            
            if ~isempty(fillValue) && ~isnan(fillValue) 
                this.AddFillValue = true;
                this.FillValue = fillValue;
            end
        end
        
        function commentAdded = addFileLevelPropertiesComment(~, codepub, commentAdded)
            % Add in the header comment for the rules, if it hasn't been added
            % previously
            if ~commentAdded
                codepub.bufferCode("importtool", newline + "% " + gs("Codgen_SetupRules"));
                commentAdded = true;
            end
        end
        
        function  convertToOutputType(this, codepub, varName, outputType, imopts)           
            % Convert the table to the specified output data type, for example
            % to numeric array or column vectors.
            if outputType.requiresOutputConversion
                codepub.bufferCode("importtool", "%% " + gs("Codgen_ConvertToOutput"));
            
                [code, vc] = outputType.getCodeToConvertFromImportedData(varName, imopts); 
                if code ~= ""
                    codepub.bufferCode("importtool", code);
                    this.varsToClear = [this.varsToClear vc];
                end
            end
        end
        
        function clearVariables(this, codepub)
            % Clear local variables
            codepub.bufferCode("importtool",  newline + "%% " + gs("Codgen_ClearVars"));
            vars = unique(this.varsToClear);
            vars(vars == "") = [];
            codepub.bufferCode("importtool", "clear " + strjoin(vars));
        end
        
        function [dataRange, isSingleRange] = getRangeInfoFromRanges(~, range)
            % Return the ranges as a string array.  range can be a cell array,
            % where multiple row ranges will be like: {'A3:G4', 'A6:G7'}, and
            % multiple column ranges will be like: {{'C3:D5', 'F3:F5'}}.
            % Combined multiple rows and column ranges will be something like:  
            % {{'C3:D5', 'F3:F5'}, {'C7:D8', 'F7:F8'}}.
            %
            % range can also be a char or string, in which case it is a single
            % range.
            dataRange = strings(0);
            isSingleRange = true;
            
            if iscell(range)
                for rowBlockRange = 1:length(range)
                    if iscell(range{rowBlockRange})
                        if isscalar(range{rowBlockRange})
                            % Handle multiple row ranges
                            dataRange(end+1) = range{rowBlockRange}{1}; %#ok<*AGROW>
                        else
                            % Handle multiple column ranges
                            firstRange = range{rowBlockRange}{1};
                            lastRange = range{rowBlockRange}{end};
                            [dataRangeRows, dataRangeCols] = internal.matlab.importtool.server.ImportUtils.excelRangeToMatlab(firstRange);
                            if dataRangeCols(1) ~= 1
                                % Readjust the range to start at A1
                                firstRange = internal.matlab.importtool.server.ImportUtils.toExcelRange(...
                                    dataRangeRows(1), dataRangeRows(end), 1, dataRangeCols(end));
                            end
                            dataRange(end+1) = extractBefore(firstRange, ":") + ":" + extractAfter(lastRange, ":");
                        end
                    else
                        dataRange(end+1) = range{rowBlockRange};
                    end
                end
            else
                % Range is a single char or string
                rowBlockRange = 1;
                dataRange = string(range);
            end
            
            if rowBlockRange > 1
                isSingleRange = false;
            end
        end
        
        function varName = getUniqueVarName(this, startVarName, currVarNames)
            % Make sure that the variable name we're using for indexing isn't
            % already in use
            varName = matlab.lang.makeUniqueStrings(startVarName, currVarNames);
            this.varsToClear = [this.varsToClear, varName];
        end
        
        function varNames = getResolvedVarNames(~, currVarNames)
            % Returns a string array of how to represent each of the variable
            % names in the currVarNames.  For example, ["A", "B\nC"] will return
            % ["A", "B" + newline + "C"]
            varNames = string(currVarNames);
            
            import internal.matlab.datatoolsservices.FormatDataUtils;
            for idx = 1:length(varNames)
                v = varNames(idx);  
                
                % Since we use only the third output, we can just pass in a
                % table variable ("t"), which is unused.  Also pass in NaN as
                % the index, since this is also unused.
                [~, ~, varNames(idx)] = FormatDataUtils.generateVariableNameAssignmentString(...
                    string(v), "t", NaN);
            end
        end
        
        function generatePreserveVariableNames(this, codepub, imopts)
            % Add in the 'PreserveVariableNames' option in the Import Options
            % object, if supported & the property is non-default (true).
            if imopts.PreserveVariableNames
                codepub.bufferCode("importtool", this.opts + ".PreserveVariableNames = true;");
            end
        end
        
        function generateVariableNames(this, codepub, imopts)
            % Generate the code for 'VariableNames' and 'SelectedVariableNames'
            varNames = this.getResolvedVarNames(imopts.VariableNames);
            if length(varNames) > 1
                variableNames = strjoin(varNames, ", ");
                codepub.bufferCode("importtool", this.opts + ".VariableNames = [" + variableNames + "];");
            else
                codepub.bufferCode("importtool", this.opts + ".VariableNames = " + varNames + ";");
            end
            
            if ~isequal(imopts.VariableNames, imopts.SelectedVariableNames)
                % Only set the 'SelectedVariableNames' property if there is a
                % difference between the full set of VariableNames and the
                % SelectedVariableNames.
                selVarNames = this.getResolvedVarNames(imopts.SelectedVariableNames);
                if length(selVarNames) > 1
                    selectedVariableNames = strjoin(selVarNames, ", ");
                    codepub.bufferCode("importtool", this.opts + ...
                        ".SelectedVariableNames = [" + selectedVariableNames + "];");
                else
                    codepub.bufferCode("importtool", this.opts + ...
                        ".SelectedVariableNames = " + selVarNames + ";");
                end
            end
        end
        
        function commentAdded = generateSetVarOptsCode(this, codepub, imopts, columnVarTypes)
            commentAdded = false;
            
            % Handle text columns -- we need to specify the WhitespaceRule as
            % preserve to match legacy behavior.
            textColumns = cellfun(@(x) x == "string" || x == "char", columnVarTypes);
            if any(textColumns)
                commentAdded = this.addSetVarOptsHeaderComment(codepub, commentAdded);
                textColumnsStr = getColumnsAsText(this, textColumns, imopts.VariableNames);
                codepub.bufferCode("importtool", this.opts + " = setvaropts(" + ...
                    this.opts + ", " + textColumnsStr + ", ""WhitespaceRule"", ""preserve"");");
            end
            
            % Also set the EmptyFieldRule -- this also helps to match legacy
            % behavior (regarding missing vs "" strings), as well as to help
            % with the exclusion rules (setting this forces the rules to be
            % ignored on text/categorical columns).
            textCatColumns = cellfun(@(x) x == "string" || x == "char" || x == "categorical", columnVarTypes);
            if any(textCatColumns)
                commentAdded = this.addSetVarOptsHeaderComment(codepub, commentAdded);
                textCatColumnsStr = getColumnsAsText(this, textCatColumns, imopts.VariableNames);
                codepub.bufferCode("importtool", this.opts + " = setvaropts(" + this.opts + ", " + ...
                    textCatColumnsStr + ", ""EmptyFieldRule"", ""auto"");");
            end
            
            optionColumns = cellfun(@(x) x == "datetime" || x == "duration", ...
                columnVarTypes);
            for column = find(optionColumns)
                fmt = imopts.VariableOptions(column).InputFormat;
                if ~isempty(fmt) && fmt ~= "default"
                    commentAdded = this.addSetVarOptsHeaderComment(codepub, commentAdded);
                    colStr = getColumnsAsText(this, column, imopts.VariableNames);
                    codeStr = this.opts + " = setvaropts(" + this.opts + ", " + ...
                        colStr + ", ""InputFormat"", """ + ...
                        imopts.VariableOptions(column).InputFormat + """";
                    if this.SupportsPreserveDTFormat && strcmp(columnVarTypes{column}, "datetime")
                        % Don't set the DatetimeFormat for durations
                        codeStr = codeStr + ", ""DatetimeFormat"", ""preserveinput""";
                    end
                    codeStr = codeStr + ");";
                    codepub.bufferCode("importtool", codeStr);
                end
            end

            dblColumns = cellfun(@(x) x == "double", columnVarTypes);
            if any(dblColumns)
                doubleColumnsStr = getColumnsAsText(this, dblColumns, imopts.VariableNames);
                
                if this.AddFillValue
                    commentAdded = this.addSetVarOptsHeaderComment(codepub, commentAdded);
                    codepub.bufferCode("importtool", this.opts + " = setvaropts(" + this.opts + ", " + ...
                        doubleColumnsStr + ", ""FillValue"", " + this.FillValue + ");");
                end

                if this.AddTreatAsMissing 
                    commentAdded = this.addSetVarOptsHeaderComment(codepub, commentAdded);
                    codepub.bufferCode("importtool", this.opts + " = setvaropts(" + this.opts + ", " + ...
                        doubleColumnsStr + ", ""TreatAsMissing"", '');");
                end
            end
        end
        
        function commentAdded = addSetVarOptsHeaderComment(~, codepub, commentAdded)
            % Add in the header comment for the rules, if it hasn't been added
            % previously
            if ~commentAdded
                codepub.bufferCode("importtool", newline + "% " + gs("Codgen_SetupVariableProperties"));
                commentAdded = true;
            end
        end
        
        function generateSeeAlsoAndDate(~, codepub, commentBegin, outputType)
            % Generate 'See Also' line
            codepub.bufferCode("importtool", commentBegin + ...
                gs("Codgen_FuncSeeAlso", upper(outputType.getImportFunctionName())));
            codepub.bufferCode("importtool", commentBegin);
            
            % Generate the auto-generated line with the date
            codepub.bufferCode("importtool", "% " + gs("Codgen_AutoGenHeader", char(datetime('now'))) + newline);
        end

        function b = eligibleForShortCircuit(this, args, imopts, optionsClass)
            % Returns true if the code being generated is eligible for
            % short circuiting, based on the arguments and import options.

            % Checks if the Import Options are the same class, that the
            % output type is table or timetable, and that the import
            % doesn't include arbitrary variable names.  (Depending on
            % where it is used, having arbitrary variable names can trigger
            % warnings to be displayed, which in the case of the Live
            % Editor, are difficult to address).
            b = this.ShortCircuitCode && ...
                ~isempty(args.OriginalOpts) && isa(imopts, optionsClass) && ...
                isa(args.OriginalOpts, optionsClass) && ...
                (isa(args.OutputType, "internal.matlab.importtool.server.output.TableOutputType") || ...
                isa(args.OutputType, "internal.matlab.importtool.server.output.TimeTableOutputType")) && ...
                ~args.ArbitraryVarNames;

        end
    end
    
    methods(Access = public, Static)
        function openCodeInEditor(c)
            % Open the given code in the Editor
            if ~ischar(c)
                c = char(strjoin(c, newline));
            end
            if nargout('matlab.desktop.editor.newDocument') > 0
                editorDoc = matlab.desktop.editor.newDocument(c);

                % Move the cursor to the start of the file, as the call to indent scrolls
                % to where the cursor is.  (It is at the end of the file after creating
                % the newDocument() above).
                editorDoc.goToPositionInLine(1,1);
                editorDoc.smartIndentContents();
            else
                matlab.desktop.editor.newDocument(c);
            end
        end
        
        function openCodeInLiveEditor(c)
            % Open the given code in the Live Editor
            if ~ischar(c)
                c = char(strjoin(c, newline));
            end
            matlab.internal.liveeditor.openAsLiveCode(c)
        end                
    end
end

function s = gs(msg, varargin)
    % Convenience function to get a string from the Import Tool message catalog.
    % This is just to have a short name in the code, so the code is more
    % readable.
    s = internal.matlab.importtool.server.ImportUtils.getImportToolMsgFromTag(msg, varargin{:});
end
