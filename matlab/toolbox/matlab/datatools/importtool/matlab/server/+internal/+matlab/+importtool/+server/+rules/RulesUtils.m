% This class is unsupported and might change or be removed without
% notice in a future version.

% Copyright 2022 The MathWorks, Inc.

classdef RulesUtils
    methods(Static)
        % converts a rule action string to the rule piece enumeration
        function actionEnum = actionToEnum(actionString)
            import internal.matlab.importtool.server.rules.UnimportableRules;

            switch(actionString)
                case message('MATLAB:codetools:importtool:DropdownOptionReplace').string
                    actionEnum = UnimportableRules.Replace;

                case message('MATLAB:codetools:importtool:DropdownOptionExcludeRows').string
                    actionEnum = UnimportableRules.ExcludeRows;

                case message('MATLAB:codetools:importtool:DropdownOptionExcludeCols').string
                    actionEnum = UnimportableRules.ExcludeColumns;

                otherwise
                    actionEnum = UnimportableRules.empty;
            end
        end

        % Converts a rule enumeration to the rule action string
        function actionString = enumToAction(action)
            import internal.matlab.importtool.server.rules.UnimportableRules;

            switch(action)
                case UnimportableRules.Replace
                    actionString = message('MATLAB:codetools:importtool:DropdownOptionReplace').string;

                case UnimportableRules.ExcludeRows
                    actionString = message('MATLAB:codetools:importtool:DropdownOptionExcludeRows').string;

                case UnimportableRules.ExcludeColumns
                    actionString = message('MATLAB:codetools:importtool:DropdownOptionExcludeCols').string;

                otherwise
                    actionString = strings(0);
            end
        end

        % Converts a rule value action string to the rule value enumeration
        function typeEnum = valueTypeToEnum(valueString)
            import internal.matlab.importtool.server.rules.UnimportableRules;

            switch(valueString)
                case message('MATLAB:codetools:importtool:DropdownOptionReplaceUnimportableCells').string
                    typeEnum = UnimportableRules.ReplaceUnimportable;

                case message('MATLAB:codetools:importtool:DropdownOptionReplaceEmptyCells').string
                    typeEnum = UnimportableRules.ReplaceEmpty;

                case message('MATLAB:codetools:importtool:DropdownOptionExcludeUnimportableCells').string
                    typeEnum = UnimportableRules.ExcludeUnimportable;

                case message('MATLAB:codetools:importtool:DropdownOptionExcludeEmptyCells').string
                    typeEnum = UnimportableRules.ExcludeEmpty;

                otherwise
                    typeEnum = UnimportableRules.empty;
            end
        end

        % Converts a rule value enumeration to the rule value action string
        function valueString = enumToValue(value)
            import internal.matlab.importtool.server.rules.UnimportableRules;

            switch(value)
                case UnimportableRules.ReplaceUnimportable
                    valueString = message('MATLAB:codetools:importtool:DropdownOptionReplaceUnimportableCells').string;

                case UnimportableRules.ReplaceEmpty
                    valueString = message('MATLAB:codetools:importtool:DropdownOptionReplaceEmptyCells').string;

                case UnimportableRules.ExcludeUnimportable
                    valueString = message('MATLAB:codetools:importtool:DropdownOptionExcludeUnimportableCells').string;

                case UnimportableRules.ExcludeEmpty
                    valueString = message('MATLAB:codetools:importtool:DropdownOptionExcludeEmptyCells').string;

                otherwise
                    valueString = strings(0);
            end
        end

        function cellsLeft = cellsLeftInMap(map)
            cellsLeft = any(any(map));
        end

        function cellRule = ruleIsForCells(rule)
            cellRule = ~(rule.rowExcludeRule || rule.colExcludeRule);
        end

        function rowColRule = ruleIsForRowsOrColumns(rule)
            rowColRule = rule.rowExcludeRule || rule.colExcludeRule;
        end

        function isBlank = ruleIsForBlankCells(rule)
            isBlank = false;

            if contains(lower(rule.ID), 'blank')
                isBlank = true;
            end
        end

        function isUnimportable = ruleIsForUnimportableCells(rule)
            % the options are presently only rules for blank or
            % unimportable cells, so if this rule isn't blank it must be
            % unimportable.
            isUnimportable = ~internal.matlab.importtool.server.rules.RulesUtils.ruleIsForBlankCells(rule);
        end

        % converts the rule pieces to a human readable string that will be displayed in the create rule pop-up
        function humanReadable = humanReadableRule(action, valueType, value)
            import internal.matlab.importtool.server.rules.UnimportableRules;

            if action == UnimportableRules.Replace && valueType == UnimportableRules.ReplaceUnimportable
                humanReadable = char( message('MATLAB:codetools:importtool:ImportRuleReadableReplaceUnimportable', num2str(value)).string );
            elseif action == UnimportableRules.Replace && valueType == UnimportableRules.ReplaceEmpty
                humanReadable = char( message('MATLAB:codetools:importtool:ImportRuleReadableReplaceEmpty', num2str(value)).string );
            elseif action == UnimportableRules.ExcludeRows && valueType == UnimportableRules.ExcludeUnimportable
                humanReadable = char( message('MATLAB:codetools:importtool:ImportRuleReadableExcludeRowsUnimportable').string );
            elseif action == UnimportableRules.ExcludeRows && valueType == UnimportableRules.ExcludeEmpty
                humanReadable = char( message('MATLAB:codetools:importtool:ImportRuleReadableExcludeRowsEmpty').string );
            elseif action == UnimportableRules.ExcludeColumns && valueType == UnimportableRules.ExcludeUnimportable
                humanReadable = char( message('MATLAB:codetools:importtool:ImportRuleReadableExcludeColumnsUnimportable').string );
            elseif action == UnimportableRules.ExcludeColumns && valueType == UnimportableRules.ExcludeEmpty
                humanReadable = char( message('MATLAB:codetools:importtool:ImportRuleReadableExcludeColumnsEmpty').string );
            else
                exception = MException('TabularImportViewModel:InvalidRuleType', 'invalid rule type');
                throw(exception);
            end
        end

        % takes the valueType for a given rule and returns whether it is an unimportable type or not
        function isUnimportable = isUnimportableRule(valueType)
            if valueType == internal.matlab.importtool.server.rules.UnimportableRules.ReplaceUnimportable || ...
                    valueType == internal.matlab.importtool.server.rules.UnimportableRules.ExcludeUnimportable

                isUnimportable = true;
            else
                isUnimportable = false;
            end
        end

        function ruleString = convertRuleToKey(rule)
            import internal.matlab.importtool.server.rules.UnimportableRules;

            if rule.Action == UnimportableRules.Replace && rule.ValueType == UnimportableRules.ReplaceEmpty
                ruleString = 'blankreplace';
            elseif rule.Action == UnimportableRules.Replace && rule.ValueType == UnimportableRules.ReplaceUnimportable
                ruleString = 'nonnumericreplacerule';
            elseif rule.Action == UnimportableRules.ExcludeRows && rule.ValueType == UnimportableRules.ExcludeEmpty
                ruleString = 'excluderowswithblanks';
            elseif rule.Action == UnimportableRules.ExcludeRows && rule.ValueType == UnimportableRules.ExcludeUnimportable
                ruleString = 'excludeunimportablerows';
            elseif rule.Action == UnimportableRules.ExcludeColumns && rule.ValueType == UnimportableRules.ExcludeEmpty
                ruleString = 'excludecolumnswithblanks';
            elseif rule.Action == UnimportableRules.ExcludeColumns && rule.ValueType == UnimportableRules.ExcludeUnimportable
                ruleString = 'excludeunimportablecolumns';
            end
        end

        function excludedRows = getExcludedRowsResolvedWithSelection( ...
                unimportableCells, selRows, selCols)

            % Returns the excluded rows, based on the current set of
            % unimportable cells, and the current selection.  Only rows within
            % the current selection are considered.  Returns a logical array the
            % same length as the number of rows in the unimportableCells array,
            % with the rows set to true that should be excluded.
            s = false(size(unimportableCells));
            s(selRows(1):selRows(2), selCols(1):selCols(2)) = true;
            unimportableCells = unimportableCells & s;
            excludedRows = any(unimportableCells, 2);
        end

        function excludedColumns = getExcludedColumnsResolvedWithSelection( ...
                unimportableCells, selRows, selCols)

            % Returns the excluded columns, based on the current set of
            % unimportable cells, and the current selection.  Only columns
            % within the current selection are considered.  Returns a logical
            % array the same length as the number of columns in the
            % unimportableCells array, with the columns set to true that should
            % be excluded.
            s = false(size(unimportableCells));
            s(selRows(1):selRows(2), selCols(1):selCols(2)) = true;
            unimportableCells = unimportableCells & s;
            excludedColumns = any(unimportableCells);
        end
    end
end
