classdef SpreadsheetInputs < matlab.io.internal.FunctionInterface &...
        matlab.io.internal.functions.AcceptsSheetNameOrNumber
    %SHAREDSPREADSHEETINPUTS Inputs common to detection, and ImportOptions
    %properties.
    
%   Copyright 2018 The MathWorks, Inc.

    properties (Parameter)
        %DATARANGE where to find the data in a spreadsheet file
        %   The DATARANGE is where the data values are found.
        %
        %   Can be any of the following Ranges:
        %
        %                 cell: The starting cell for the data. The total
        %                       range will extend to the last empty row or
        %                       until reaching the footer Range, and will
        %                       contain 1 column for each variable.
        %
        %                range: The exact range to read. The number of
        %                       columns must match the number of variables.
        %                       Data will only be read from the rows
        %                       specified. Empty cells will be imported as
        %                       missing cells.
        %
        %            row-range: Selection of rows to read. The data will be
        %                       read from the first non-empty column and
        %                       one column for each variable.
        %
        %         column-range: Selection of columns to read. There must be
        %                       the same number of columns as import
        %                       variables. The first record will be read
        %                       from the first non-empty row.
        %
        %         number-index: The first row which contains data. Data
        %                       will be read until the end of the file, or
        %                       the footer Range.
        %
        %    set of row-ranges: A set of row-ranges to read expressed as a
        %                       cell array or string array of row-ranges.
        %                       The data will be read from each row-range
        %                       and vertically concatenated. Example:
        %                       {'1:4';'7:12'} or ["3:10";"15:20"]
        %
        % set of row-intervals: A set of row-intervals to read. Same as
        %                       "set of row-ranges" except specified as a
        %                       numeric array of intervals. Example:
        %                       [1,2;5,8]
        %
        %                empty: No data will be read.
        %
        %   See also matlab.io.spreadsheet.SpreadsheetImportOptions
        DataRange          = 'A1';
        
        %VARIABLEUNITSRANGE Range of Variable Units in the spreadsheet
        %   VARIABLEUNITSRANGE can contain only 1 row or column, or be empty.
        %
        %   Can be any of the following Ranges:
        %           cell: The starting cell for the units. The range will extend to
        %                 contain 1 column for each variable.
        %
        %          range: The exact range to read. The number of columns must match
        %                 the number of variables and contain only one row.
        %
        %      row-range: Selection of rows to read. Must be a single row.
        %
        %   number-index: The row which contains units.
        %
        %          empty: Indicates there are no units.
        %
        %   See also matlab.io.spreadsheet.SpreadsheetImportOptions
        %   matlab.io.spreadsheet.SpreadsheetImportOptions/DataRange
        VariableUnitsRange         = '';
        
        %VARIABLENAMESRANGE Range of Variable names in the spreadsheet
        %   VARIABLENAMESRANGE can contain only 1 row or column, or be empty.
        %
        %   Can be any of the following Ranges:
        %           cell: The starting cell for the variable names. The range will
        %                 extend to contain 1 column for each variable.
        %
        %          range: The exact range to read. The number of columns must match
        %                 the number of variables and contain only one row.
        %
        %      row-range: Must be a single row.
        %
        %   number-index: The row which contains variable names.
        %
        %          empty: Indicates there are no variable names.
        %
        %   See also matlab.io.spreadsheet.SpreadsheetImportOptions
        %   matlab.io.spreadsheet.SpreadsheetImportOptions/DataRange
        VariableNamesRange = '';
        
        %VARIABLEDESCRIPTIONSRANGE Range of variable descriptions in the spreadsheet
        %   VARIABLEDESCRIPTIONSRANGE Where variable descriptions are found.
        %   Variable descriptions must have the same number of columns as
        %   variables.
        %
        %   Can be any of the following Ranges:
        %          range: The exact range to read. The number of columns must match
        %                 the number of variables.
        %
        %      row-range: Must be a single row.
        %
        %          empty: Indicates there are no variable descriptions.
        %
        %   See also matlab.io.spreadsheet.SpreadsheetImportOptions
        %   matlab.io.spreadsheet.SpreadsheetImportOptions/DataRange
        VariableDescriptionsRange = '';
        
        %ROWNAMESRANGE Range of row names in the spreadsheet
        %   ROWNAMESRANGE can contain only 1 column or row, or be empty.
        %
        %   Can be any of the following Ranges:
        %           cell: The starting cell for the row names. A row name will be
        %                 read for each data row.
        %
        %          range: The exact range to read. The number of rows must match
        %                 the number of datarows and contain only one column.
        %
        %   column-range: Must be a single column.
        %
        %   number-index: The column which contains row names.
        %
        %          empty: Indicates there are no row names.
        %
        %   See also matlab.io.spreadsheet.SpreadsheetImportOptions
        %   matlab.io.spreadsheet.SpreadsheetImportOptions/DataRange
        RowNamesRange      = '';
        
    end
    
    methods % get/set
        function obj = set.DataRange(obj,rhs)
        try
            obj.DataRange = obj.validateDataRange(rhs);
        catch ME
            throwAsCaller(ME);
        end
        end
        
        function obj = set.VariableNamesRange(obj,rhs)
        try
            obj.VariableNamesRange = validateRange(rhs,'VariableNamesRange',@SingleRecordNumVars,obj.getNumVars());
        catch ME
            throwAsCaller(ME);
        end
        end
        
        function obj = set.RowNamesRange(obj,rhs)
        try
            obj.RowNamesRange = validateRange(rhs,'RowNamesRange',@SingleVariable,obj.getNumVars());
        catch ME
            throwAsCaller(ME);
        end
        end
        
        function obj = set.VariableUnitsRange(obj,rhs)
        try
            obj.VariableUnitsRange = validateRange(rhs,'VariableUnitsRange',@SingleRecordNumVars,obj.getNumVars());
        catch ME
            throwAsCaller(ME);
        end
        end
        
        function obj = set.VariableDescriptionsRange(obj,rhs)
        try
            obj.VariableDescriptionsRange = validateRange(rhs,'VariableDescriptionsRange',@SingleRecordNumVars,obj.getNumVars());
        catch ME
            throwAsCaller(ME);
        end
        end
    end
    
    methods(Access = protected)
        function [rhs,obj] = setSheet(obj,rhs)
            import matlab.io.spreadsheet.internal.SheetTypeFactory
            import matlab.io.spreadsheet.internal.SheetType

            % Note: If sheetType is SheetType.Empty we don't want to error.
            % At read time, SheetType.Empty is interpreted as supplying
            % a sheet index of 1 (i.e. read the first sheet).
            sheetType = SheetTypeFactory.makeSheetType(rhs);
            if sheetType == SheetType.Index
                rhs = double(rhs);
            else
                rhs = convertStringsToChars(rhs);
            end
        end
    end
    
    methods (Abstract)
        n = getNumVars(obj);    
    end
    
    methods (Access = protected)
        function rhs = validateDataRange(obj,rhs)
        % Determine how DataRange was specified and then delegate to
        % the appropriate validators
        rhs = convertStringsToChars(rhs);
        [nrows, ncols] = size(rhs);
        
        if (~ischar(rhs) && ncols > 1) || nrows > 1
            temprhs = rhs;
            if iscellstr(rhs)
                for i = 1:nrows
                    type = ...
                        matlab.io.spreadsheet.internal.validateRange(rhs{i});
                    if ~strcmp(type, 'row-only')
                        error(message('MATLAB:spreadsheet:importoptions:RowOnlyRanges'));
                    end
                end
                % convert the intervals to numeric for validation
                temprhs = str2double(split(string(rhs),':'));
            elseif ~isnumeric(rhs)
                error(message('MATLAB:spreadsheet:importoptions:InvalidDataRange'));
            else
                % Convert to double
                rhs = double(rhs);
            end
            try
                % validate the 'DataLines' syntax
                matlab.io.internal.validators.validateLineIntervals(temprhs,'DataRange');
            catch ME
                if strcmp(ME.identifier,'MATLAB:textio:io:InvalidDataLines')
                    error(message('MATLAB:spreadsheet:importoptions:InvalidDataRange'));
                else
                    throw(ME);
                end
            end
        elseif isempty(rhs)
            error(message('MATLAB:spreadsheet:importoptions:InvalidDataRange'));
        else
            rhs = validateRange(rhs,'DataRange',@NumVars,obj.getNumVars());
        end
        end

    end
end

function rhs = validateRange(rhs,propname,orientationValidator,numElems)
rhs = convertStringsToChars(rhs);
if ischar(rhs)
    rhs = strtrim(rhs);
end
if isempty(rhs)
    rhs = '';
    return;
end
try
    if isscalar(rhs) && isnumeric(rhs)
        % Scalar is supported, number of row/column
        if any(floor(rhs)~=rhs) || (rhs <= 0) || isinf(rhs)
            error(message('MATLAB:spreadsheet:importoptions:InvalidScalarLocation',propname));
        end
        % Convert to double
        rhs = double(rhs);
    else
        % Either four element vector or range string.
        [type, rangesize] = ...
            matlab.io.spreadsheet.internal.validateRange(rhs);
        orientationValidator(propname,type,rangesize,numElems);
    end
catch ME
    if propname=="DataRange" && ismember(ME.identifier,{'MATLAB:spreadsheet:sheet:invalidRangeSpec',...
            'MATLAB:spreadsheet:sheet:rangeParseInvalid'})
        error(message('MATLAB:spreadsheet:importoptions:InvalidDataRange'));
    end
    throwAsCaller(ME)
end
end

function NumVars(propname,type,rangesize,nvars)
% must match the number of variables, be a start cell, be open-ended (cell/row), or a named range.
if nvars < inf && ~any(rangesize(2) == [nvars -1]) && ~strcmp(type,'single-cell')
    error(message('MATLAB:spreadsheet:importoptions:VarNumberMismatch',propname));
end
end

function SingleRecordNumVars(propname,type,rangesize,nvars)
% Allowed:
%   * A single open record range
%   * The number of variables must match, or be open.
%   * An exact range.

if strcmp(type,'column-only')
    error(message('MATLAB:spreadsheet:importoptions:PropSupportOpenCol',propname));
end
% must be a single row, or a named range.
if ~any(rangesize(1) == [-1 1])
    error(message('MATLAB:spreadsheet:importoptions:SingleRow',propname));
end
% must match the number of variables, be a start cell, be open-ended (cell/row), or a named range.

if nvars < inf && ~any(rangesize(2) == [nvars 1 -1])
    error(message('MATLAB:spreadsheet:importoptions:VarNumberMismatch',propname));
end

end

function SingleVariable(propname,type,rangesize,~)
% Cannot support rows
if strcmp(type,'row-only')
    error(message('MATLAB:spreadsheet:importoptions:PropSupportOpenRow',propname));
end
% must match the number of variables, be open-ended (cell/row), or a named range.
if ~any(rangesize(2) == [-1 1])
    error(message('MATLAB:spreadsheet:importoptions:SingleCol',propname));
end
end
