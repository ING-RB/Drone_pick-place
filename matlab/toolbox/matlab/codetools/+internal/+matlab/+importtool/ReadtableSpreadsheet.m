% This class is unsupported and might change or be removed without
% notice in a future version.

% Copyright 2018-2019 The MathWorks, Inc.

% This class is used for Spreadsheet Import through the Import Tool.

classdef ReadtableSpreadsheet < internal.matlab.importtool.AbstractSpreadsheet
    
    properties (Hidden)
        DataModel;
        Workbook;
    end
    
    methods
        function this = ReadtableSpreadsheet()
            % Constructor
            this.HasFile = false;
        end
        
        function delete(this)
            if ~isempty(this.DataModel)
                delete(this.DataModel);
            end
            this.HasFile = false;
        end
        
        function Open(this, filename)
            % Called to open the specified file
            if nargin < 2 || isempty(filename)
                error(message('MATLAB:codetools:FilenameMustBeSpecified'));
            end
            if ~ischar(filename)
                error(message('MATLAB:codetools:FilenameMustBeAString'));
            end
            if any(strfind(filename, '*'))
                error(message('MATLAB:codetools:FilenameMustNotContainAsterisk'));
            end
            
            this.FileName = filename;
            this.HasFile = true;
            
            % Any errors getting the extension or creating the workbook will
            % ultimately cause the import to fail.  Let these error now, and the
            % error will be reported back to the client
            fmt = matlab.io.spreadsheet.internal.getExtension(filename);
            this.Workbook = matlab.io.spreadsheet.internal.createWorkbook(fmt, filename, false);
        end
        
        function columnNames = getDefaultColumnNames(this, sheetname, row, avoidShadow)
            % Returns the default column names for the specified sheet and
            % header row number.  avoidShadow specifies whether to allow Matlab
            % functions as column names, for example.
            this.initDataModel(sheetname);
            varNames = evalin('caller', 'who');
            this.DataModel.resetStoredNames();
            columnNames = this.DataModel.getDefaultColumnNames(row, avoidShadow, varNames);
            
            % Convert to cellstr for JMI
            columnNames = cellstr(columnNames);
        end
        
        function [aMessage, sheetNames, format] = GetInfo(this)
            % Returns the sheetNames for the current file, and its file format.
            if ~this.HasFile
                error(message('MATLAB:codetools:NoFileOpen'));
            end

            aMessage = 'Microsoft Excel Spreadsheet';
            sheetNames = this.getSheetNames();
            format = this.Workbook.Format();
        end
        
        function sheets = getSheetNames(this)
            % Returns the sheet names for the given file.  Only sheets which are
            % determined to have data on them will be returned (so empty sheets
            % or sheets with only charts on them will be excluded)
            worksheets = this.Workbook.SheetNames;
            indexes = true(1, length(worksheets));
            sheetNames = cell(1, length(worksheets));
            for i = 1:length(worksheets)
                if ismissing(worksheets(i))
                    % Missing sheetnames will be empty sheets or charts
                    indexes(i) = false;
                else
                    sheet = this.Workbook.getSheet(worksheets{i});
                    if isprop(sheet, 'Type')
                        % Valid sheets will have a 'Type' property.  
                        sheetNames{i} = sheet.Name;
                        
                        if isempty(sheet.usedRange)
                            % But if there is no valid usedRange, flag it as
                            % having no data
                            indexes(i) = false;
                        end
                    end
                end
            end
            
            sheets = sheetNames(indexes);
        end
        
        function initDataModel(this, sheetname)
            % Called to initialize the SpreadsheetDataModel for the given sheet
            % name.
            if ~isempty(this.DataModel)
                if isequal(this.DataModel.SheetName, sheetname)
                    return;
                end
                delete(this.DataModel);
            end
            
            % The Workbook has already been created.  Pass it to the DataModel
            % so it doesn't have to create one too, which is time consuming.
            this.DataModel = internal.matlab.importtool.SpreadsheetDataModel(...
                this.FileName, sheetname, [], this.Workbook);
            this.DataModel.ValidMatlabVarNames = true;
            this.DataModel.UseLegacyVariableNames = true;
        end
        
        function dims = GetSheetDimensions(this, sheetname)
            % Returns a 4-tuple [startRow, rowCount, startColumn, columnCount]
            this.initDataModel(sheetname);
            dims = this.DataModel.getSheetDimensions();
        end
        
        function init(this, sheetname)
            % Initialize the WorksheetStructure cache.  The AbstractSpreadsheet
            % class queries this structture cache for expected values, like the
            % header row, numeric columns, initial selection, etc...
            this.initDataModel(sheetname);
            if ~isempty(this.WorksheetStructure) && isfield(this.WorksheetStructure, ...
                    this.generateVariableName(sheetname))
                return
            end
            
            nm = this.generateVariableName(sheetname);
            dataPos = this.DataModel.getSheetDimensions();
            dims = [dataPos(2) dataPos(4)];
            
            try
                this.WorksheetStructure.(nm).HeaderRow = this.DataModel.getHeaderRow();
                this.WorksheetStructure.(nm).NumericContainerColumns = this.DataModel.getNumericColumns();
                
                % Initialize mixed containers to false
                this.WorksheetStructure.(nm).MixedContainerColumns = ...
                    false(size(this.WorksheetStructure.(nm).NumericContainerColumns));
                
                this.WorksheetStructure.(nm).InitialSelection = this.DataModel.getInitialSelection();
                this.WorksheetStructure.(nm).CategoricalContainerColumns = this.DataModel.getCategoricalColumns();
                this.WorksheetStructure.(nm).dateFormats = this.DataModel.getDateFormats();
                
            catch me %#ok<NASGU>
                % If something went wrong, just select to the end of the sheet
                this.WorksheetStructure.(nm).InitialSelection = dataPos;
                this.WorksheetStructure.(nm).HeaderRow = 1;
                this.WorksheetStructure.(nm).NumericContainerColumns = true(1, dims(2));
                this.WorksheetStructure.(nm).MixedContainerColumns = false(1, dims(2));
                this.WorksheetStructure.(nm).CategoricalContainerColumns = false(1, dims(2));
                this.WorksheetStructure.(nm).dateFormats = repmat({''}, 1, dims(2));
            end
        end
        
        function Close(~)
        end
        
        function [data, raw, dateData] = Read(this, sheetname, range, ~, asDatetime)
            % Called to read data from the spreadsheet.  Returns the numeric
            % array data, the raw cell array of the text of the data, and the
            % dateData for the specified range.
            if ~this.HasFile
                error(message('MATLAB:codetools:NoFileOpen'));
            end
            this.initDataModel(sheetname);

            if nargin <= 3
                asDatetime = false;
            end
            [data, raw, dateData] = this.DataModel.getDataFromExcelRange(range, asDatetime);
            raw = raw(:);
        end
        
        function [varNames,varSizes] = ImportData(this, varNames, allocationFcn, ...
                sheetname, range, rules, columnTargetTypes, columnVarNames)
            % Called to import the data from the given sheet name and range to
            % the specified variable names (varNames).
            this.initDataModel(sheetname);
            
            function x = convertToString(x)
                % Used for cell array to assure the correct output type
                if ischar(x)
                    x = string(x);
                end
            end
                    
            try
                [colTypes, outputType, rules] = internal.matlab.importtool.AbstractSpreadsheet.getCodeGenInputsFromJava(...
                    columnTargetTypes, allocationFcn, rules);

                [opts, dataRanges] = this.DataModel.getImportOptions(...
                    "Range", range, ...
                    "ColumnVarTypes", colTypes, ...
                    "ColumnVarNames", columnVarNames, ...
                    "Rules", rules); 
                
                [varNames, vars] = this.DataModel.ImportData(opts, ...
                    "VarNames", varNames, ...
                    "OutputType", outputType, ...
                    "Range", dataRanges);
                
                if isa(outputType, "internal.matlab.importtool.server.output.CellArrayOutputType") && ...
                    internal.matlab.importtool.server.ImportUtils.getSetTextType == "string"
                    vars{1} = cellfun(@convertToString, vars{1}, "UniformOutput", false);
                end

                % Assign the imported data to workspace variables
                varSizes = cell(length(varNames),1);
                for k = 1:length(varNames)
                    varValue = vars{k};
                    assignin(this.DstWorkspace, varNames{k}, vars{k});
                    varSizes{k,1} = size(varValue);
                end
                
                % Use cellstr for JMI
                varNames = cellstr(varNames);
            catch me
                internal.matlab.importtool.AbstractSpreadsheet.manageImportErrors(me);
            end
        end
        
        
        function status = GenerateScript(this, varNames, allocationFcn, sheetname, ...
                range, rules, columnTargetTypes, columnVarNames)
            status = '';
            
            % Called to generate the script for the given import parameters
            this.initDataModel(sheetname);

            try
                [colTypes, outputType, rules] = internal.matlab.importtool.AbstractSpreadsheet.getCodeGenInputsFromJava(...
                    columnTargetTypes, allocationFcn, rules);

                % Create the SpreadsheetCodeGenerator and generate the script
                scg = internal.matlab.importtool.server.SpreadsheetCodeGenerator;
                
                [opts, dataRanges] = this.DataModel.getImportOptions(...
                    "Range", range, ...
                    "ColumnVarNames", columnVarNames, ...
                    "ColumnVarTypes", colTypes, ...
                    "Rules", rules);
                
                % Generate code
                c = scg.generateScript(opts, ...
                    "Filename", this.FileName, ...
                    "OutputType", outputType, ...
                    "VarName", varNames, ...
                    "Range", dataRanges, ...
                    "DefaultTextType", internal.matlab.importtool.server.ImportUtils.getSetTextType);

                scg.openCodeInEditor(c);
            catch me
                status = me.message;
            end
        end
        
        function status = GenerateFunction(this, varNames, allocationFcn, sheetname, ...
                range, rules, columnTargetTypes, columnVarNames)
            status = '';
            
            % Called to generate the function for the given import parameters
            this.initDataModel(sheetname);

            try
                [colTypes, outputType, rules] = internal.matlab.importtool.AbstractSpreadsheet.getCodeGenInputsFromJava(...
                    columnTargetTypes, allocationFcn, rules);

                % Create the SpreadsheetCodeGenerator and generate the function.
                % The last argument is the function name -- specifying empty
                % allows the codegenerator to generate the function name.
                scg = internal.matlab.importtool.server.SpreadsheetCodeGenerator;

                [opts, dataRanges] = this.DataModel.getImportOptions(...
                    "Range", range, ...
                    "ColumnVarNames", columnVarNames, ...
                    "ColumnVarTypes", colTypes, ...
                    "Rules", rules);
                
                % Generate code
                c = scg.generateFunction(opts, ...
                    "Filename", this.FileName, ...
                    "OutputType", outputType, ...
                    "VarName", varNames, ...
                    "Range", dataRanges, ...
                    "DefaultTextType", internal.matlab.importtool.server.ImportUtils.getSetTextType);

                scg.openCodeInEditor(c);
            catch me
                status = me.message;
            end
        end
        
        function status = GenerateLiveScript(this, varNames, allocationFcn, sheetname, ...
                range, rules, columnTargetTypes, columnVarNames)
            status = '';
            
            % Called to generate the script for the given import parameters.
            % The script is then opened in the Live Editor.
            this.initDataModel(sheetname);

            try
                [colTypes, outputType, rules] = internal.matlab.importtool.AbstractSpreadsheet.getCodeGenInputsFromJava(...
                    columnTargetTypes, allocationFcn, rules);

                % Create the SpreadsheetCodeGenerator and generate the script
                scg = internal.matlab.importtool.server.SpreadsheetCodeGenerator(true);
                
                [opts, dataRanges] = this.DataModel.getImportOptions(...
                    "Range", range, ...
                    "ColumnVarNames", columnVarNames, ...
                    "ColumnVarTypes", colTypes, ...
                    "Rules", rules);
                
                % Generate code
                c = scg.generateScript(opts, ...
                    "Filename", this.FileName, ...
                    "OutputType", outputType, ...
                    "VarName", varNames, ...
                    "Range", dataRanges, ...
                    "DefaultTextType", internal.matlab.importtool.server.ImportUtils.getSetTextType);
                
                scg.openCodeInLiveEditor(c);
            catch me
                status = me.message;
            end
        end
    end    
end



