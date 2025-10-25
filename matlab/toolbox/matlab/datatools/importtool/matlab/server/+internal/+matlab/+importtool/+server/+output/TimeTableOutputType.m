% This class is unsupported and might change or be removed without
% notice in a future version.

% This class is represents a timeable Output Data Type from Import.

% Copyright 2019-2023 The MathWorks, Inc.

classdef TimeTableOutputType < internal.matlab.importtool.server.output.OutputTypeAdapter
    
    properties
        RowTimesColumn string = strings(0);
        RowTimesType string = "column";  % default value
        RowTimesValue = [];
        RowTimesUnits string = strings(0);
        RowTimesStart = [];
        RowTimesStartType string = strings(0);
        ImportAsTimeTable logical = true;
    end
    
    properties(Constant)
        % Default for timetable output is a timestep of 1 second
        DEFAULT_TYPE = "timestep";
        DEFAULT_UNITS = "seconds";
        DEFAULT_VALUE = 1;
        DEFAULT_START = "00:00:00";
        DEFAULT_START_TYPE = "duration";
    end
    
    methods
        function [vars, varNames] = convertFromImportedData(this, tbl)
            if this.ImportAsTimeTable
                % No-op. Input is already a timetable.
                vars = tbl;
                varNames = [];
            else
                % Need to convert from table to timetable using the specified
                % row times settings
                additionalArgs = this.getTimetableArgs();
                vars = table2timetable(tbl, additionalArgs{:});
                varNames = [];
            end
        end
        
        function [code, varsToClear] = getCodeToConvertFromImportedData(this, varName, ~)
            varsToClear = "";
            if this.ImportAsTimeTable
                % No code necessary.  varName is already a timetable.
                code = "";
            else
                % Need to convert from table to timetable using the specified
                % row times setting
                additionalArgs = this.getTimetableArgsForCodGen();
                code = varName + " = table2timetable(" + varName + ", " + additionalArgs + ")";
                if ~this.showLastOutput
                    code = code + ";";
                end
            end
        end
        
        function code = getFunctionHeaderCode(~)
            % Returns the table header line for the function
            code = internal.matlab.importtool.server.ImportUtils.getImportToolMsgFromTag("Codgen_TimeTableHeader");
        end
        
        % Returns the function handle of the function used to perform the
        % import.
        function fcnHandle = getImportFunction(this)
            if this.ImportAsTimeTable
                % Imports using readtimetable
                fcnHandle = @readtimetable;
            else
                % Import as table, and convert afterwards
                fcnHandle = @readtable;
            end
        end
        
        % Returns the name of the function used to perform the import.
        function fcnHandleName = getImportFunctionName(this)
            if this.ImportAsTimeTable
                % Imports using readtimetable
                fcnHandleName = "readtimetable";
            else
                % Import as table, and convert afterwards
                fcnHandleName = "readtable";
            end
        end
        
        function b = requiresOutputConversion(this)
            % Requires no output conversion from timetable if we are importing
            % as timetable, otherwise need to convert
            b = ~this.ImportAsTimeTable;
        end
        
        function initOutputArgsFromProperties(this, viewModel)
            % Initialize the row times arguments for output from the view
            % model's properties
            this.RowTimesType = viewModel.getTableModelProperty("RowTimesType");
            switch this.RowTimesType
                case "column"
                    this.setupRowTimesColumn(viewModel);
                    
                case "timestep"
                    this.RowTimesValue = viewModel.getTableModelProperty("RowTimesValue");
                    this.RowTimesUnits = viewModel.getTableModelProperty("RowTimesUnits");
                    
                case "samplerate"
                    this.RowTimesValue = viewModel.getTableModelProperty("RowTimesValue");
                    this.RowTimesUnits = "";
                    
                otherwise
                    % Try to find a datetime or duration column to use
                    this.setupRowTimesColumn(viewModel);
                    
            end
            
            if ~isequal(this.RowTimesType, "column")
                % Save the row times start and start type
                this.RowTimesStartType = viewModel.getTableModelProperty("RowTimesStartType");
                this.RowTimesStart = viewModel.getTableModelProperty("RowTimesStart");
                
                % If the row times type is not column, then we need to handle
                % discontinuous selection in import.  The problem is that when
                % there are multiple ranges to import, there may be multiple
                % calls to readtimetable made... which means that if we are
                % specifying a timestep or sample rate, then multiple calls will
                % result in the wrong output.  When we are in this situation, we
                % need to read in as table, and convert to timetable afterwards.
                if ~viewModel.SupportsMultiDataRange
                    this.ImportAsTimeTable = ~contains(viewModel.getTableModelProperty("excelSelection"), ",");
                end
            end
        end
        
        function c = getAdditionalArgsForImportFcn(this)
            if ~this.ImportAsTimeTable
                % None if we are not importing as timetable
                c = {};
            else
                c = this.getTimetableArgs();
            end
        end
        
        function s = getAdditionalArgsForCodeGen(this)
            if ~this.ImportAsTimeTable
                % None if we are not importing as timetable
                s = strings(0);
            else
                s = this.getTimetableArgsForCodGen();
            end
        end
        
        function s = getOutputTypeInitializerForCodeGen(this)
            if ~this.ImportAsTimeTable
                s = "table";
            else
                s = "timetable";
            end
        end

        function b = isTabular(~)
            b = true;
        end
    end
    
    methods(Access = private)
        function rowTimesCol = getFirstDTDurationColumn(~, viewModel)
            % Returns the name of the first datetime or duration column found.
            % If there are none, returns "".
            dtDurationCols = find(cellfun(@(s) s == "datetime" || s == "duration", ...
                viewModel.ColumnClasses));
            colNames = viewModel.getCurrentColumnVarNames();
            if ~isempty(dtDurationCols)
                % Get the name of the first datetime or duration column
                rowTimesCol = colNames{dtDurationCols(1)};
            else
                rowTimesCol = "";
            end
        end
        
        function b = isDTDurationColumn(~, viewModel, rowTimesCol)
            % Returns true if the specified column name is a datetime or
            % duratino column, and false otherwise.
            b = false;
            dtDurationCols = find(cellfun(@(s) s == "datetime" || s == "duration", ...
                viewModel.ColumnClasses));
            colNames = viewModel.getCurrentColumnVarNames();
            
            % narrow the search for a matching name by just looking at datetime
            % or duration columns
            for idx = 1:length(dtDurationCols)
                headerName = colNames{dtDurationCols(idx)};
                if strcmp(headerName, rowTimesCol)
                    b = true;
                    break;
                end
            end
        end
        
        function setupRowTimesColumn(this, viewModel)
            % Called to set the row times column property.  If the view model
            % has a RowTimesColumn already set, then use it if it is still set
            % to be a duration or datetime column.  Otherwise, try to find the
            % first datetime or duration column to use.
            rowTimesCol = viewModel.getTableModelProperty("RowTimesColumn");
            if  strlength(rowTimesCol) == 0 || ~this.isDTDurationColumn(viewModel, rowTimesCol)
                rowTimesCol = this.getFirstDTDurationColumn(viewModel);
            end
            
            % If we found a datetime or duration column, set the RowTimesType to
            % column.  Otherwise leave it empty, and the default will be used
            % insetad.
            if strlength(rowTimesCol) == 0
                this.RowTimesType = "";
            else
                this.RowTimesType = "column";
            end
            this.RowTimesColumn = rowTimesCol;
        end
        
        function c = getTimetableArgs(this)
            switch this.RowTimesType
                case "column"
                    if ~isempty(this.RowTimesColumn)
                        c = {'RowTimes', char(this.RowTimesColumn)};
                    else
                        c = {};
                    end
                    
                case "timestep"
                    % The RowTimesUnits is a function name to call to generate
                    % the appropriate Time Step.  For example, "seconds", or
                    % "calweeks".
                    fcn = str2func(this.RowTimesUnits);
                    c = {'TimeStep', fcn(this.RowTimesValue)};
                    
                case "samplerate"
                    % Use the specified Sample Rate value
                    c = {'SampleRate', this.RowTimesValue};
                    
                otherwise
                    % Default to a timestep of 1 second
                    fcn = str2func(this.DEFAULT_UNITS);
                    c = {'TimeStep', fcn(this.DEFAULT_VALUE)};
            end
            
            if ~isequal(this.RowTimesType, "column")
                % Check to see if the Start Time needs to be included
                if this.RowTimesStartType == "duration"
                    dr = duration(this.RowTimesStart);
                    if ~isequal(dr, 0)
                        % Don't specify the Start Time if it is a duration of 0
                        % (since this is the default)
                        c{3} = 'StartTime';
                        c{4} = dr;
                    end
                elseif this.RowTimesStartType == "datetime"
                    % Always need to specify Start Time if it is a datetime (there
                    % isn't really a default datetime value)
                    c{3} = 'StartTime';
                    c{4} = datetime(this.RowTimesStart);
                end
            end
        end
        
        function s = getTimetableArgsForCodGen(this)
            switch this.RowTimesType
                case "column"
                    if ~isempty(this.RowTimesColumn)
                        s = """RowTimes"", """ + this.RowTimesColumn + """";
                    else
                        s = strings(0);
                    end
                    
                case "timestep"
                    % Generate the Time Step using the RowTimesUnits, which will
                    % be the appropriate function call to make, for example
                    % "seconds" or "calweeks".
                    s = """TimeStep"", " + this.RowTimesUnits + "(" + this.RowTimesValue + ")";
                    
                case "samplerate"
                    % Generate the Sample Rate with the specified value
                    s = """SampleRate"", " + this.RowTimesValue;
                    
                otherwise
                    % Default to a timestep of 1 second
                    s = """TimeStep"", " + this.DEFAULT_UNITS + "(" + this.DEFAULT_VALUE + ")";
            end
            
            if ~isequal(this.RowTimesType, "column")
                % Check to see if the Start Time needs to be included
                if this.RowTimesStartType == "duration"
                    dr = duration(this.RowTimesStart);
                    if ~isequal(dr, 0)
                        % Don't specify the Start Time if it is a duration of 0
                        % (since this is the default)
                        s = s + ", ""StartTime"", duration(""" + string(dr) + """)";
                    end
                elseif this.RowTimesStartType == "datetime"
                    % Always need to specify Start Time if it is a datetime (there
                    % isn't really a default datetime value)
                    s = s + ", ""StartTime"", datetime(""" + this.RowTimesStart + """)";
                end
            end
        end
    end
end
