classdef (Abstract) ReturnsTabularData < handle
% Base class for datastores whose preview, read, and readall functions 
% can return tables or timetables.

% Copyright 2019 The MathWorks, Inc.

    properties(Dependent)
        %OUTPUTTYPE Output data type to use when reading from the datastore,
        %specified as either "table" (default), or "timetable".
        %   OutputType selects the data type returned from the preview,
        %   read, and readall functions:
        %    - If "OutputType" is "table", the data returned is a table.
        %    - If "OutputType" is "timetable", the data returned is a timetable.
        OutputType
        
        %ROWTIMES Name of a time variable from the input data file.
        %   Specified as a character vector or a string scalar, this property
        %   selects the variable to use as the row times vector when "OutputType"
        %   is "timetable". By default, the first datetime or duration variable
        %   in the data is used.
        RowTimes
    end
    
    properties(Abstract)
       %VARIABLENAMES Names of variables 
       VariableNames
       
       %SELECTEDVARIABLENAMES Names of variables of interest
       SelectedVariableNames
    end
    
    properties(Access = private)
        %PRIVATEOUTPUTTYPE OutputType to use when reading from the 
        %   datastore. Either 'table' or 'timetable'
        PrivateOutputType = "table"   % OutputType of read call
        
        %OUTPUTTYPEINITIALIZED Logical to indicate if the OutputType and
        %   RowTimes properties have been initialized. 
        OutputTypeInitialized = false
    end
    
    properties(SetAccess = private, GetAccess = protected)
        %TIMEVARIABLEINDEX Index of the time variable used as row times.
        TimeVariableIndex = []
    end

    properties(Abstract, SetAccess = private, GetAccess = protected)
        %SELECTEDVARIABLENAMESIDX Logical Indices of SelectedVariableNames.
        SelectedVariableNamesIdx
    end
    
    methods(Abstract, Access = protected)
        %GETVARIABLETYPES Returns the output types of the variables.
        varTypes = getVariableTypes(ds)
    end
    
    methods(Access = protected)
        function [data] = convertReadData(ds, data) 
        %CONVERTREADDATA Converts the data read into a
        %   timetable if the OutputType is set to 'timetable'. If the
        %   OutputType is set to 'table', the data is returned unchanged. 
            if strcmpi(ds.OutputType, 'timetable') && istable(data)
                timeVar = ds.VariableNames{ds.TimeVariableIndex};
                data = table2timetable(data, 'RowTimes', timeVar);
            end
        end

        function initOutputTypeAndRowTimes(ds, outputType, rowTimes, usingDefaults)
        % INITOUTPUTTYPEANDROWTIMES Initializes the OutputType and RowTimes
        %   properties. usingDefaults is a cell array that indicates if the
        %   default values of OutputType or RowTimes should be used.
            inferTimeVar = ismember('RowTimes', usingDefaults);
            validateOutputType(ds, outputType, inferTimeVar);
            validateRowTimes(ds, rowTimes, inferTimeVar);
            ds.OutputTypeInitialized = true;
        end
        
        function tf = resetOutputTypeAndRowTime(ds, timeVarIdx)
        %RESETOUTPUTTYPEANDROWTIME Attempts to reset the OutputType to
        %   'timetable' if timeVarIdx is a scalar integer. If the variable
        %   indicated by timeVarIdx is not a time variable or not selected,
        %   the OutputType is left as 'table' and false is returned. If the
        %   OutputType was reset to 'timetable', true is returned. If 
        %   timeVarIdx is the empty double array, the OutputType is not 
        %   modified. This function should only be called after the
        %   datastore has been re-initialized.
            tf = true;
            if isempty(timeVarIdx)
                return;
            end
            try
                ds.RowTimes = timeVarIdx;
            catch
                tf = false;
            end 
        end

        function checkRowTimeSelected(ds)
        %CHECKROWTIMES Checks if the RowTimes variable is still a selected
        %   variable. If not, an error is thrown.
            if ds.OutputType == "timetable"
                ds.validateRowTimesSelected(ds.TimeVariableIndex);
            end
        end

        function checkRowTimeType(ds)
        %CHECKROWTIMETYPE Checks if the RowTimes variable is still a
        %   datetime or duration variable. If not, an error is thrown.
            if ds.OutputType == "timetable"
                ds.validateRowTimeType(ds.TimeVariableIndex);
            end
        end

        function loadOutputTypeAndRowTimes(ds, varargin)
        %LOADOUTPUTTYPEANDROWTIMES Initializes PrivateOutputType,
        %   TimeVariableIndex and OutputTypeInitialized properties of a
        %   datastore loaded from a MAT file. If the datastore was loaded
        %   in as an object, only OutputTypeInitialized needs to be
        %   initialized to true. If the datastore was saved as a struct,
        %   all three properties need to be initialized.
            if nargin == 1 % PrivateOutputType and TimeVariableIndex already initialized
                ds.OutputTypeInitialized = true;
            elseif nargin == 3
                ds.PrivateOutputType = varargin{1}; % OutputType
                ds.TimeVariableIndex = varargin{2}; % TimeVariableIndex
                ds.OutputTypeInitialized = true;
           else
               assert(false);
           end
        end
    end

    methods(Access = private)
        function validateOutputType(ds, outputType, inferTimeVar)
        %VALIDATEOUTPUTTYPE Validates and sets PrivateOutputType.
        %   inferTimeVar indicates if the OutputType should be set to
        %   'timetable' if 'auto' was supplied during construction. 
            allowedOpts = ["table", "timetable"];
            errID = "MATLAB:datastoreio:outputtype:invalidOutputType";
            if ~ds.OutputTypeInitialized
                allowedOpts = ["auto" allowedOpts];
                errID = "MATLAB:datastoreio:outputtype:invalidOutputTypeConstructor";
            end
            outputType = convertCharsToStrings(outputType);
            if ~isscalar(outputType) || ~isstring(outputType) || ~any(strcmp(outputType, allowedOpts))
                error(message(errID));
            end
            
            % outputType can only be "auto" during construction
            if outputType == "auto"
                if inferTimeVar
                    outputType = "table";
                else
                    outputType = "timetable";
                end    
            end

            prevOutputType = ds.PrivateOutputType;
            ds.PrivateOutputType = outputType;
            if ds.OutputTypeInitialized
                if prevOutputType == "table" && outputType == "timetable"
                    % table -> timetable transition requires inferring the
                    % RowTimes variable from the variable types
                    try
                        validateRowTimes(ds, "", true);
                    catch ME
                        ds.PrivateOutputType = "table";
                        throwAsCaller(ME);
                    end
                elseif prevOutputType == "timetable" && outputType == "table"
                    ds.TimeVariableIndex = [];
                end
            end
        end

        function validateRowTimes(ds, rowTimes, inferTimeVar)
        %VALIDATEROWTIMES Validates and sets the RowTimes property.
        %   inferTimeVar indicates if the first selected
        %   time variable should be set as the RowTimes.
            if ~ds.OutputTypeInitialized
                isTable = ds.validateInputCombination(inferTimeVar);
                if isTable
                    ds.TimeVariableIndex = [];
                    return;
                end
            end
            if inferTimeVar
                % finds the first selected datetime or duration to use as
                % the RowTimes variable.
                allowedTypes = ["datetime", "duration"];
                varTypes = ds.getVariableTypes();
                sVarTypes = varTypes(ds.SelectedVariableNamesIdx);
                isAllowedType = contains(sVarTypes, allowedTypes);
                allTimeVarIdx = ds.SelectedVariableNamesIdx(isAllowedType);
                if isempty(allTimeVarIdx)
                    error(message("MATLAB:datastoreio:outputtype:noTimeVariableFound"));
                end
                rowTimes = allTimeVarIdx(1);
            else
                rowTimes = validateScalarStringOrNumber(rowTimes);
                % checks that the variable name or index refers to a
                % selected datetime or duration variable
                if ~isnumeric(rowTimes)
                    [~, rowTimes] = ismember(rowTimes, ds.VariableNames);
                end
                ds.validateRowTimesSelected(rowTimes);
                ds.validateRowTimeType(rowTimes);
            end
            ds.TimeVariableIndex = rowTimes;
            ds.PrivateOutputType = "timetable";
        end

        function validateRowTimeType(ds, idx)
        %VALIDATEROWTIMETYPE Validates that the RowTime variable referred
        %   to by idx is a datetime or duration variable. This function
        %   does not check if the variable is selected.
            allowedTypes = {'datetime', 'duration'};
            varTypes = ds.getVariableTypes();
            if isempty(idx) || ~ismember(varTypes{idx}, allowedTypes)
                error(message("MATLAB:datastoreio:outputtype:invalidRowTimeType",...
                    ds.VariableNames{idx}));
            end
        end

        function idx = validateRowTimesSelected(ds, idx)
        %VALIDATEROWTIMESSELECTED Validates that the Row Time variable
        %   referred to by idx is a selected variable.        
            if isempty(idx) || ~ismember(idx, ds.SelectedVariableNamesIdx)
                error(message("MATLAB:datastoreio:outputtype:variableNotSelected"));
            end
        end

        function isTable = validateInputCombination(ds, inferTimeVar)
        %VALIDATEINPUTCOMBINATION Validates that a value for RowTimes is
        %   not passed to the constructor when the OutputType is 
        %   specified as 'table'.
            isTable = ds.PrivateOutputType == "table";
            if isTable
                if ~inferTimeVar
                    error(message("MATLAB:datastoreio:outputtype:invalidOutputTypeCombination"));
                end
            end
        end
    end

    methods
        function set.OutputType(ds, outputType)
            try
                assert(ds.OutputTypeInitialized, "Assertion failed: " + ...
                "Use initOutputTypeAndRowTimes to initialize the OutputType");
                validateOutputType(ds, outputType, false);
            catch ME
                throw(ME);
            end
        end
        
        function set.RowTimes(ds, rowTimes)
            try
                assert(ds.OutputTypeInitialized, "Assertion failed: " + ...
                "Use initOutputTypeAndRowTimes to initialize the RowTimes");
                validateRowTimes(ds, rowTimes, false);
            catch ME
                throw(ME);
            end
        end
        
        function outputType = get.OutputType(ds)
            outputType = convertStringsToChars(ds.PrivateOutputType);
        end
        
        function rowTimes = get.RowTimes(ds)
            if isempty(ds.TimeVariableIndex)
                rowTimes = ds.TimeVariableIndex;
            else
                rowTimes = ds.VariableNames{ds.TimeVariableIndex};
            end
        end
    end
end

function val = validateScalarStringOrNumber(val)
% Validates that val is a scalar string, char array, or double.

    import matlab.internal.datatypes.isScalarInt;

    errID = "MATLAB:datastoreio:outputtype:invalidRowTimesInput";
    val = convertCharsToStrings(val);
    if isnumeric(val)
        if ~isScalarInt(val, 1)
            error(message(errID));
        end
    elseif ~isstring(val) || ~isscalar(val)
        error(message(errID))
    end
end
