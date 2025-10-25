% This function is unsupported and might change or be removed without notice in
% a future version.
%
% This function will produce statistical column information, like the Workspace
% Browser display will show.
%
% Arguments:
% startRow - the start row of the data to get the statistical data for
% endRow - the end row of the data to get the statistical data for
% data - cell array of data variables
% statFunc - the statistical function to call
% showNaNstatFunc - the statistical function to call if showing NaN's
% formatOutput - whether to format the output as strings or not
% showNaNs - whether to show NaNs in the data or not
% numelLimit - the number of elements to limit the statistical compuations to

% Copyright 2020-2024 The MathWorks, Inc.

function viewData = getWorkspaceStatDisplay(startRow, endRow, data, statFunc, ...
        showNaNstatFunc, formatOutput, showNaNs, numelLimit)
    arguments
        startRow (1,1) double
        endRow (1,1) double
        data cell
        statFunc function_handle
        showNaNstatFunc function_handle
        formatOutput logical = true
        showNaNs logical = false
        numelLimit (1,1) double = 500000
    end

    rows = startRow: endRow;
    viewData = cell(length(rows), 1);
    statFuncStr = func2str(statFunc);

    for i=1:length(rows)
        cellData = data{rows(i)};

        % NOTE: When we add support for object like
        % data(datetimes/duration etc). For now, just support objects
        % which inherit from builtin numeric types
        if isUnsupportedStatColumn(cellData, statFuncStr)
            if formatOutput
                viewData{i} = "";
            else
                viewData{i} = nan;
            end
        elseif ~isa(cellData, "tall") && numel(cellData) > numelLimit
            % Handle tall data and data where the size exceeds the numelLimit
            if formatOutput
                viewData{i} = string(getString(message("MATLAB:codetools:structArray:TooManyElements")));
            else
                viewData{i} = nan;
            end
        else
            if ~isscalar(cellData)
                cellData = cellData(:);
            end

            % Determine the function to call based on the showNaNs setting
            if showNaNs
                fun = showNaNstatFunc;
            else
                fun = statFunc;
            end

            % Call the function with the given data
            statVal = fun(cellData);

            if formatOutput
                % Format data as needed
                if isnan(statVal)
                    viewData{i} = "NaN";
                else
                    if isnumeric(statVal)
                        try
                            viewData{i} = string(matlab.internal.display.numericDisplay(double(statVal)));
                        catch ME
                            viewData{i} = string(strtrim(evalc("disp(statVal)")));
                        end
                    else
                        viewData{i} = string(strtrim(evalc("disp(statVal)")));
                    end
                end
            else
                % Always typecast to double (There could be types
                % like half that would error on a cell sort)
                viewData{i} = double(statVal);
            end
        end
    end
end

function isUnsupported = isUnsupportedStatColumn(celldata, statName)
    % Some data types don't support some of the statistical columns
    statName = lower(statName);
    isUnsupported = ~ (builtin("isnumeric", celldata) || builtin("islogical", celldata)) || ...
        isempty(celldata) || issparse(celldata);
    if ~isUnsupported
        % For integers, support only min/max/range and nothing for complex integers
        if (isinteger(celldata) && (~endsWith(statName, "max") && ...
                ~endsWith(statName, "min") && ~endsWith(statName, "range") || ~isreal(celldata)))
            isUnsupported = true;
            % For half types, median and mode are unsupported.
        elseif isa(celldata, "half") && (endsWith(statName, "median") || endsWith(statName, "mode"))
            isUnsupported = true;
        end
    end
end

