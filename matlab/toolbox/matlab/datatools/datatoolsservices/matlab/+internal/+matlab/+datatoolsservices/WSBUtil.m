classdef WSBUtil < handle
    % Utility class which provides Workspace Browser display functionality

    % Copyright 2019-2025 The MathWorks, Inc.

    properties(Constant)
        DEFAULT_COLUMN_NAMES = ["name", "size", "class", "value"];
        ALL_COLUMNS = ["Name", "Size", "Class", "Value", "Range", "Min", "Max", "Mean", "Median", "Mode", "Var", "Std", "Bytes", "IsSummary", "IsDirty", "IconClass"];
        DEFAULT_WORKSPACE = "debug";
        DEFAULT_STATS_USE_NANS = true;
        DEFAULT_STATS_NUMEL_LIMIT = 500000;
    end

    methods(Static)
        % Returns the Workspace Display struct for the given variable names, colums, and statistics
        % settings.
        function info = getWorkspaceDisplay(varNames, columns, statsUseNaNs, statsNumelLimit, workspace)
            arguments
                varNames string;
                columns string = internal.matlab.datatoolsservices.WSBUtil.DEFAULT_COLUMN_NAMES;
                statsUseNaNs logical = internal.matlab.datatoolsservices.WSBUtil.DEFAULT_STATS_USE_NANS;
                statsNumelLimit double = internal.matlab.datatoolsservices.WSBUtil.DEFAULT_STATS_NUMEL_LIMIT;
                workspace string = internal.matlab.datatoolsservices.WSBUtil.DEFAULT_WORKSPACE;
            end

            columns = lower(columns);

            try
                % Create a cell array of all the variables
                var = cell(size(varNames));
                missingVars = strings(0);
                for idx = 1:length(varNames)
                    varExists = true;
                    if evalin("debug", "exist('" + varNames(idx) + "', 'var');") == 0
                        % Check if each variable exists before eval'ing it.
                        % This handles the case where variable names could
                        % be function/object names
                        varExists = false;
                    else
                        try
                            var{idx} = evalin(workspace, varNames(idx));
                        catch
                            varExists = false;
                        end
                    end

                    if ~varExists
                        % Do we need to handle the case where we are asked for a variable which
                        % doesn't exist?  For now treat as empty.
                        var{idx} = [];
                        missingVars(end+1) = varNames(idx); %#ok<AGROW>
                    end
                end

                % Use existing function to get the workspace display
                info = internal.matlab.datatoolsservices.WSBUtil.getDisplayStruct( ...
                    var, varNames, columns, statsUseNaNs, statsNumelLimit);

                % Go through the returned struct array to update the IsDirty flag for any missing
                % variables)
                if ~isempty(missingVars)
                    for idx = 1:length(info)
                        if any(strcmp(missingVars, varNames(idx)))
                            info(idx).IsDirty = true;
                        end
                    end
                end

                for idx = 1:length(internal.matlab.datatoolsservices.WSBUtil.ALL_COLUMNS)
                    colName = internal.matlab.datatoolsservices.WSBUtil.ALL_COLUMNS{idx};
                    if ~isfield(info, colName)
                        [info.(colName)] = deal('');
                    end
                end

                info = orderfields(info, internal.matlab.datatoolsservices.WSBUtil.ALL_COLUMNS);
            catch ME
                info.Name = varNames;
                internal.matlab.datatoolsservices.logDebug("datatoolsservices::WSBUtil", "Error in getWorkspaceDisplay");
            end
        end

        % Returns true if ans exists in the workspace
        function b = ansExistsInWS()
            b = evalin("debug", "exist('ans', 'var')");
        end

        % Called to rename a variable from the origVarName to the newVarName
        function rename(origVarName, newVarName)
            arguments
                origVarName (1,1) string
                newVarName (1,1) string
            end

            errorMsg = [];
            cmd = newVarName + " = " + origVarName + "; builtin clear " + origVarName;
            currVars = evalin("debug", "who");
            if any(strcmp(currVars, newVarName))
                errorMsg = message('MATLAB:codetools:structArray:VariableExists', newVarName);
            else
                try
                    evalin("debug", cmd);
                catch
                    varName = internal.matlab.datatoolsservices.VariableUtils.getTruncatedIdentifier(newVarName);
                    errorMsg = message('MATLAB:codetools:structArray:InvalidRenameVarOnEdit', varName);
                    msgSuffix = message('MATLAB:codetools:structArray:InvalidRenameMsgOnEdit', namelengthmax);
                    errorMsg = errorMsg.string + msgSuffix.string;
                end
            end

            if isempty(errorMsg)
                desktop_ve = internal.matlab.desktop_variableeditor.DesktopVariableEditor.getInstance();
                desktop_ve.renamevar(origVarName, newVarName);
            elseif evalin("base", "exist('" + origVarName + "', 'var')")
                % Show an error message if the original variable actually
                % exists in the workspace
                title = getString(message('MATLAB:codetools:structArray:EditFailedTitle'));
                d = internal.matlab.datatoolsservices.DTDialogHandler.getInstance;
                d.showConfirmationDialog(errorMsg, title, "Icon", "warning", "DialogButtons", "OK");
            end
        end

        % Called to edit a variable with varName to the newValue
        function editValue(varName, newValue)
            arguments
                varName (1,1) string
                newValue (1,1) string
            end

            cmd = varName + " = " + newValue + ";";
            try
                evalin("debug", cmd);
            catch ex
                title = getString(message('MATLAB:codetools:structArray:EditFailedTitle'));
                d = internal.matlab.datatoolsservices.DTDialogHandler.getInstance;
                d.showConfirmationDialog(ex.message, title, "Icon", "warning", "DialogButtons", "OK");
            end
        end
    end

    methods(Static, Hidden)
        % Returns a struct array for the given variables, variableNames, columns, and statistics
        % settings.
        %
        % Note that this logic is similar to getWorkspaceDisplay, but is optimized for just the
        % Workspace Browser use, whereas getWorkspaceDisplay is a more general purpose display
        % function used by many downstream teams.
        function s = getDisplayStruct(variables, varNames, columns, showNaNs, numelLimit)
            import internal.matlab.datatoolsservices.FormatDataUtils;
            import internal.matlab.datatoolsservices.StatFunctionUtils;
            import matlab.internal.datatoolsservices.getWorkspaceStatDisplay;

            if isempty(variables)
                % There's no variables, just return empty
                s = [];
                return
            end

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
            COL_BYTES = 13;

            currentFormat = internal.matlab.datatoolsservices.FormatDataUtils.getCurrentNumericFormat();

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
                    case "bytes"
                        indexedColunms(colIdx) = COL_BYTES;
                end
            end

            % Create a table to hold the results, which will grow as the data is accumulated. Use
            % struct constructor with cellstrs to get struct array
            t = struct('Name', cellstr(varNames), 'IsDirty', false);

            if any(strcmp(columns, "bytes"))
                whosInfo = evalin("debug", "whos('" + strjoin(varNames, "','") + "')");
                whosInfoNames = {whosInfo.name};
                whosInfoBytes = [whosInfo.bytes];
            end

            varCount = length(varNames);
            for idx = 1:varCount
                try
                    % Try/catch for each variable means that one bad apple
                    % doesn't spoil the whole bunch
                    var = variables{idx};

                    for colIdx = 1:length(indexedColunms)
                        % For each of the specified columns, get the appropriate data and add it to the
                        % table
                        switch(indexedColunms(colIdx))
                            case COL_SIZE
                                t(idx).Size = FormatDataUtils.formatSize(var);

                            case COL_CLASS
                                t(idx).Class = FormatDataUtils.getClassString(var, false);

                            case COL_VALUE
                                [t(idx).Value, t(idx).IsSummary] = internal.matlab.datatoolsservices.WSBUtil.getEditValue(var, currentFormat);

                            case COL_MEDIAN
                                val = getWorkspaceStatDisplay(...
                                    1, 1, {var}, @median, @StatFunctionUtils.computeNaNMedian, ...
                                    true, showNaNs, numelLimit);
                                t(idx).Median = char(val{1});

                            case COL_MEAN
                                val = getWorkspaceStatDisplay(...
                                    1, 1, {var}, @mean, @StatFunctionUtils.computeNaNMean, ...
                                    true, showNaNs, numelLimit);
                                t(idx).Mean = char(val{1});

                            case COL_MODE
                                val = getWorkspaceStatDisplay(...
                                    1, 1, {var}, @StatFunctionUtils.computeMode, @StatFunctionUtils.computeMode, ...
                                    true, showNaNs, numelLimit);
                                t(idx).Mode = char(val{1});

                            case COL_MIN
                                val = getWorkspaceStatDisplay(...
                                    1, 1, {var}, @min, @StatFunctionUtils.computeMin, ...
                                    true, showNaNs, numelLimit);
                                t(idx).Min = char(val{1});

                            case COL_MAX
                                val = getWorkspaceStatDisplay(...
                                    1, 1, {var}, @max, @StatFunctionUtils.computeMax, ...
                                    true, showNaNs, numelLimit);
                                t(idx).Max = char(val{1});

                            case COL_RANGE
                                val = getWorkspaceStatDisplay(...
                                    1, 1, {var}, @StatFunctionUtils.computeRange, @StatFunctionUtils.computeNaNRange, ...
                                    true, showNaNs, numelLimit);
                                t(idx).Range = char(val{1});

                            case COL_STD
                                val = getWorkspaceStatDisplay(...
                                    1, 1, {var}, @std, @StatFunctionUtils.computeNaNStd, ...
                                    true, showNaNs, numelLimit);
                                t(idx).Std = char(val{1});

                            case COL_VAR
                                val = getWorkspaceStatDisplay(...
                                    1, 1, {var}, @var, @var, ...
                                    true, showNaNs, numelLimit);
                                t(idx).Var = char(val{1});

                            case COL_BYTES
                                bIndex = strcmp(whosInfoNames, t(idx).Name);
                                if any(bIndex)
                                    t(idx).Bytes = num2str(whosInfoBytes(bIndex));
                                else
                                    t(idx).Bytes = '';
                                end
                        end
                    end

                    % Add in class icon
                    if ~isfield(t(idx), "Class") || isempty(t(idx).Class)
                        cls = FormatDataUtils.getClassString(var, false);
                    else
                        cls = t(idx).Class;
                    end
                    if contains(cls, ["distributed", "codistributed", "gpuArray", "dlarray", "tall"])
                        if isempty(t(idx).Value)
                            editValue = internal.matlab.datatoolsservices.WSBUtil.getEditValue(var, currentFormat);
                        else
                            editValue = t(idx).Value;
                        end
                        t(idx).IconClass = char(internal.matlab.datatoolsservices.FormatDataUtils.formattedClassValue(editValue, cls));
                    else
                        t(idx).IconClass = char(cls);
                    end
                catch
                    % Something failed with one of the variables, fill in
                    % any missing fields with default values.  Loop will
                    % continue with next variable.

                    % add in columns not asked for but computed
                    if any(strcmpi("Value", columns))
                        columns = [columns, "IsSummary"];
                    end
                    columns = [columns, "IconClass"];
                    for colIdx = 1:length(columns)
                        colName = char(columns{colIdx});
                        colName(1) = upper(colName(1));
                        if ~isfield(t(idx), colName)
                            if any(strcmp(colName, ["IsSummary", "IsDirty"]))
                                t(idx).(colName) = false;
                            else
                                t(idx).(colName) = '';
                            end
                        elseif any(strcmp(colName, ["IsSummary", "IsDirty"])) && ~islogical(t(idx).(colName))
                            t(idx).(colName) = false;
                        elseif ~ischar(t(idx).(colName))
                            t(idx).(colName) = '';
                        end
                    end
                end
            end
            s = t;
        end

        function [v, m] = getEditValue(var, currentFormat)
            try
                [c, ~, m] = internal.matlab.datatoolsservices.FormatDataUtils.formatDataBlockForMixedView(1, 1, 1, 1, {var}, currentFormat);
                v = c{1};
            catch
                % guard against errors
                v = '[ ]';
                m = false;
            end
            v = char(v);
        end
    end
end
