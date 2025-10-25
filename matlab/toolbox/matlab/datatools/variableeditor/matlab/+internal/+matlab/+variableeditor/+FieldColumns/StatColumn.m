classdef StatColumn < handle
    % This class is unsupported and might change or be removed without notice in
    % a future version.

    % This abstract class provides statistical data for the Stats Columns
    % in scalar struct view.

    % Copyright 2020-2024 The MathWorks, Inc.

    properties(Constant)
        DEFAULT_SHOW_NANS_VALUE logical = false;
        DEFAULT_NUMEL_LIMIT double = 500000;
    end

    methods
        function this = StatColumn()
            % These come from other mixins
            this.Editable = false; %#ok<*MCNPR>
            this.Sortable = true;
        end

        % Returns the view display data for the statistical column for
        % given data from startRow:endRow.If formatOutput is explicitly
        % false, return unformatted data to be able to perform actions like
        % sort on the FieldColumn.
        function viewData = getData(this, startRow, endRow, data, ~, virtualProps, ~, formatOutput, isDataTruncated, fieldIds)
            arguments
                this
                startRow
                endRow
                data
                ~
                virtualProps
                ~
                formatOutput logical = true;
                isDataTruncated logical = false;
                fieldIds = "";
            end
            % data is a cell array containing the data to get the value for,
            % while origData is the actual object or structure.
            if ~isempty(this.SettingsController)
                showNaNs = this.SettingsController.getUseNanSetting;
                numelLimit = this.SettingsController.getStatNumelLimitSetting;
            else
                showNaNs = this.DEFAULT_SHOW_NANS_VALUE;
                numelLimit = this.DEFAULT_NUMEL_LIMIT;
            end

            statData = cellfun(@internal.matlab.variableeditor.FieldColumns.StatColumn.handleSummary, ...
                data, num2cell(virtualProps), "UniformOutput", false);
            if isDataTruncated
                startRow = 1;
                endRow = length(statData);
            end
            viewData = matlab.internal.datatoolsservices.getWorkspaceStatDisplay(...
                startRow, endRow, statData, ...
                this.getStatFunction(), this.getShowNaNStatFunction(), ...
                formatOutput, showNaNs, numelLimit);
        end

        % Returns the sorted indices w.r.t order of fields in the struct.
        % Get the unformatted stat data and sort them.
        % Ensure that missing values are always placed at the very end.
        function sortIndices = getSortedIndices(this, data, fieldnames, virtualProps, origData)
            viewData = this.getData(1, length(data), data, fieldnames, virtualProps, origData, false);

            % Convert to a table, and add in the variable names at the end.  This way, the variable
            % names are the tie-breaker in the case where the statistics are the same.
            tb = array2table(cell2mat(viewData));
            if isrow(fieldnames)
                tb.VarNames = fieldnames';
            else
                tb.VarNames = fieldnames;
            end
            tb.VarNames = cellfun(@(x) double(x(1)), tb.VarNames);

            % Convert viewData from cell to matrix as MissingPlacement is
            % not supported for cell arrays.
            if this.SortAscending
                [~,sortIndices] = sortrows(tb, tb.Properties.VariableNames, 'MissingPlacement', 'last');
            else
                [~,sortIndices] = sortrows(tb, tb.Properties.VariableNames, 'descend', 'MissingPlacement', 'last');
            end
        end
    end

    methods(Abstract)
        getShowNaNStatFunction(this);
        getStatFunction(this);
    end

    methods(Static)
        function val = handleSummary(cellData, isVirtual)
            if isVirtual
                % Don't show any statistics for virtual properties
                val = [];
            elseif isa(cellData, 'internal.matlab.workspace.ObjectValueSummary') && ...
                    internal.matlab.datatoolsservices.VariableUtils.isNumericObject(cellData.RawValue)
                val = cellData.RawValue;
            else
                val = cellData;
            end
        end
    end
end

