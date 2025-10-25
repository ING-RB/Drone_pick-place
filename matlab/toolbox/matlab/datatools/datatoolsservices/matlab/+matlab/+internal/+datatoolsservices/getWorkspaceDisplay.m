% This function is unsupported and might change or be removed without notice in
% a future version.
%
% This function provides a display of variables, similar to the Workspace Browser.
%
% The first argument is a workspace, which can be:
% - 'base' or 'caller'
% - a Workspace-like object which supports the 'who' and 'evalin' methods
% - a cell array of variables
%
% Additional arguments can be the columns to display.  If not specified, the
% default set of columns will be returned, which is:
% name, size, class, value
%
% Columns can be any one of the following:
% name, size, class, value, min, max, mean, median, mode, range, std, var
%
% The return value is a structure array, with each struct containing the fields
% for the selected columns.

% Copyright 2020-2021 The MathWorks, Inc.

function s = getWorkspaceDisplay(workspace, varargin)
    import internal.matlab.datatoolsservices.FormatDataUtils;
    import internal.matlab.datatoolsservices.StatFunctionUtils;
    import matlab.internal.datatoolsservices.getWorkspaceStatDisplay;

    if iscell(workspace)
        % Input is a cell array of variables.  (Generate the variable names,
        % just so it is filled in)
        vars = "Var" + (1:length(workspace));
    elseif isobject(workspace) && ~isstring(workspace)
        % Input is a workspace-like object, call 'who' on it
        vars = string(who(workspace));
    elseif strcmp(workspace, "init")
        % Early return, just used to make sure classes are loaded
        s = [];
        return;
    else
        % Input is text (caller or base) -- eval who in it
        vars = string(evalin(workspace, "who"));
    end
    
    % Sort the variable names like the workspace browser does
    if ~isequal(size(vars, 2), 1)
        vars = vars';
    end
    [~,idx] = sort(lower(vars));
    varNames = vars(idx);

    varCount = length(varNames);
    
    if varCount == 0
        % There's no variables, just return empty
        s = [];
        return
    end

    defaultColumns = ["name", "size", "class", "value"];
    statsColumns = ["min", "max", "mean", "median", "mode", "range", "std", "var"];
    % Used to create faster indexed lookup
    COL_NAME = 1;
    COL_SIZE = 2;
    COL_CLASS = 3;
    COL_VALUE = 4;
    COL_MIN = 5;
    COL_MAX = 6;
    COL_MEAN = 7;
    COL_MEDIAN = 8;
    COL_MODE = 9;
    COL_RANGE = 10;
    COL_STD = 11;
    COL_VAR = 12;

    currentFormat = internal.matlab.datatoolsservices.FormatDataUtils.getCurrentNumericFormat();

    if nargin == 1
        % Only the workspace was provided, use the default list of columns
        columns = defaultColumns;
    else
        % The user has specified columns.  Make sure the columns specified are
        % valid ones
        columns = string(varargin);
        supportedCols = [defaultColumns statsColumns];
        if ~isequal(sort(union(columns, supportedCols)), sort(supportedCols))
            error(message("MATLAB:datatools:workspaceFunctions:UnsupportedColumn", ...
                strjoin(supportedCols, ", ")));
        end
    end

    % Create indexed lookup for faster processing of many variables
    indexedColunms = zeros(length(columns), 1);
    for colIdx=1:length(columns)
        switch(columns(colIdx))
            case "name"
                indexedColunms(colIdx) = COL_NAME;
            case "size"
                indexedColunms(colIdx) = COL_SIZE;
            case "class"
                indexedColunms(colIdx) = COL_CLASS;
            case "value"
                indexedColunms(colIdx) = COL_VALUE;
            case "median"
                indexedColunms(colIdx) = COL_MEDIAN;
            case "mean"
                indexedColunms(colIdx) = COL_MEAN;
            case "mode"
                indexedColunms(colIdx) = COL_MODE;
            case "min"
                indexedColunms(colIdx) = COL_MIN;
            case "max"
                indexedColunms(colIdx) = COL_MAX;
            case "range"
                indexedColunms(colIdx) = COL_RANGE;
            case "std"
                indexedColunms(colIdx) = COL_STD;
            case "var"
                indexedColunms(colIdx) = COL_VAR;
        end
    end
    
    if ~isequal(columns, "name")
        % We need to compute more than just the name column.  Create a table to
        % hold the results, which will grow as the data is accumulated.
        % Use struct constructor with cellstrs to get struct array
        t = struct('Name', cellstr(varNames));

        if isempty(intersect(columns, statsColumns))
            % We don't need these values if no stats columns are being requested
            showNaNs = [];
            numelLimit = [];
        else
            s = settings;
            showNaNs = s.matlab.desktop.workspace.statisticalcalculations.WorkspaceBrowserUseNaNs.ActiveValue;
            numelLimit = s.matlab.desktop.workspace.statisticalcalculations.WorkspaceBrowserStatNumelLimit.ActiveValue;
        end
        
        for idx = 1:varCount
            t(idx).Name = string(t(idx).Name);
            if iscell(workspace)
                % Get the variable from the workspace cell array
                var = workspace{idx};
            else
                % Call evalin on the workspace for the variable name
                var = evalin(workspace, varNames(idx));
            end
            
            for colIdx = 1:length(indexedColunms)
                % For each of the specified columns, get the appropriate data
                % and add it to the table
                switch(indexedColunms(colIdx))
                    case COL_SIZE
                        sizeStr = string(FormatDataUtils.formatSize(var));
                        t(idx).Size = sizeStr;
                        
                    case COL_CLASS
                        t(idx).Class = string(FormatDataUtils.getClassString(var, false));
                        
                    case COL_VALUE
                        [v, ~, m] = FormatDataUtils.formatDataBlockForMixedView(1, 1, 1, 1, {var}, currentFormat);
                        try
                            t(idx).Value = string(v);
                        catch
                            % guard against errors in string conversion. 
                            t(idx).Value = "[ ]";
                        end
                        t(idx).IsSummary = m;
                        
                    case COL_MEDIAN
                        val = getWorkspaceStatDisplay(...
                            1, 1, {var}, @median, @StatFunctionUtils.computeNaNMedian, ...
                            true, showNaNs, numelLimit);
                        t(idx).Median = val{1};
                        
                    case COL_MEAN
                        val = getWorkspaceStatDisplay(...
                            1, 1, {var}, @mean, @StatFunctionUtils.computeNaNMean, ...
                            true, showNaNs, numelLimit);
                        t(idx).Mean = val{1};

                    case COL_MODE
                        val = getWorkspaceStatDisplay(...
                            1, 1, {var}, @StatFunctionUtils.computeMode, @StatFunctionUtils.computeMode, ...
                            true, showNaNs, numelLimit);
                        t(idx).Mode = val{1};

                    case COL_MIN
                        val = getWorkspaceStatDisplay(...
                            1, 1, {var}, @min, @StatFunctionUtils.computeMin, ...
                            true, showNaNs, numelLimit);
                       t(idx).Min = val{1}; 

                    case COL_MAX
                        val = getWorkspaceStatDisplay(...
                            1, 1, {var}, @max, @StatFunctionUtils.computeMax, ...
                            true, showNaNs, numelLimit);
                        t(idx).Max = val{1};

                    case COL_RANGE
                        val = getWorkspaceStatDisplay(...
                            1, 1, {var}, @StatFunctionUtils.computeRange, @StatFunctionUtils.computeNaNRange, ...
                            true, showNaNs, numelLimit);
                        t(idx).Range = val{1};

                    case COL_STD
                        val = getWorkspaceStatDisplay(...
                            1, 1, {var}, @std, @StatFunctionUtils.computeNaNStd, ...
                            true, showNaNs, numelLimit);
                        t(idx).Std = val{1};

                    case COL_VAR
                        val = getWorkspaceStatDisplay(...
                            1, 1, {var}, @var, @var, ...
                            true, showNaNs, numelLimit);
                        t(idx).Var = val{1};
                end
            end
        end
        
        s = t;
    else
        % If only names are specified, return it as a string array
        s = varNames;
    end
end
