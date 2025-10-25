% This class is unsupported and might change or be removed without notice in a
% future version.

% This class provides an unimportable rules implementation

% Copyright 2022 The MathWorks, Inc.

classdef RulesStrategy < handle
    properties
        RuleDialog;
        Rules = ...
            struct('Action', internal.matlab.importtool.server.rules.UnimportableRules.Replace, ...
            'ValueType', internal.matlab.importtool.server.rules.UnimportableRules.ReplaceUnimportable, ...
            'Value', NaN, ...
            'HumanReadable', char( message('MATLAB:codetools:importtool:ImportRuleReadableReplaceUnimportable', 'NaN').string ), ...
            'IsUnimportable', true, ...
            'index', 1)...
            ;
        NextRuleId = 2;
        ExclusionsMap;
        CellExclusionsMap;
        ExclusionRulesDisplayed logical = false;
    end

    properties(Constant)
        ROW_EXCLUDED = 'isRowExcluded';
        COLUMN_EXCLUDED = 'isColExcluded';
    end

    properties(Access = private)
        RowExcludeRules
        ColExcludeRules
        FileImporterState
    end

    properties (Constant, Hidden = true)
        DEFAULT_UNIMPORTABLE_RULE = 9999999;
    end

    events
        DataChange
    end

    methods
        function delete(this)
            this.closeNewRuleDialog();
        end

        function generateExclusionMaps(this, data, raw, dateData, ...
                trimNonNumericCols, startRow, endRow, startColumn, endColumn, ...
                selRows, selCols, columnClasses)

            this.ExclusionRulesDisplayed = false;
            this.ExclusionsMap = containers.Map;
            this.CellExclusionsMap = containers.Map;
            if this.hasRowOrColumnExclusionRules()
                rulesList = string(arrayfun(@(s) internal.matlab.importtool.server.rules.RulesUtils.convertRuleToKey(s), ...
                    this.Rules, "UniformOutput", false));

                [blankCellMap, unimportableCellMap] = this.invalidCellMaps(...
                    data, raw, dateData, trimNonNumericCols, columnClasses);

                for idx = 1:length(rulesList)
                    ruleid = rulesList{idx};
                    value = this.Rules(idx).Value;
                    rule = internal.matlab.importtool.server.rules.ImportRuleFactory.getImportRuleFromText(ruleid, value);

                    if internal.matlab.importtool.server.rules.RulesUtils.ruleIsForCells(rule)
                        if internal.matlab.importtool.server.rules.RulesUtils.ruleIsForBlankCells(rule)
                            unimportableCellMap = logical(unimportableCellMap - blankCellMap);
                            blankCellMap = zeros(size(blankCellMap));
                        else
                            unimportableCellMap = zeros(size(unimportableCellMap));
                            blankCellMap = zeros(size(blankCellMap));
                        end
                    elseif internal.matlab.importtool.server.rules.RulesUtils.ruleIsForRowsOrColumns(rule)
                        if internal.matlab.importtool.server.rules.RulesUtils.ruleIsForBlankCells(rule)
                            excludedCells = blankCellMap;
                        elseif internal.matlab.importtool.server.rules.RulesUtils.ruleIsForUnimportableCells(rule)
                            excludedCells = unimportableCellMap;
                        end

                        s = struct;
                        s.excludedCells = excludedCells;
                        s.startRow = startRow;
                        s.endRow = endRow;
                        s.startColumn = startColumn;
                        s.endColumn = endColumn;
                        this.CellExclusionsMap(ruleid) = s;

                        if rule.rowExcludeRule
                            excludedCells = internal.matlab.importtool.server.rules.RulesUtils.getExcludedRowsResolvedWithSelection(...
                                excludedCells, selRows, selCols);
                        elseif rule.colExcludeRule
                            excludedCells = internal.matlab.importtool.server.rules.RulesUtils.getExcludedColumnsResolvedWithSelection(...
                                excludedCells, selRows, selCols);
                        end

                        if internal.matlab.importtool.server.rules.RulesUtils.ruleIsForBlankCells(rule) && ...
                                internal.matlab.importtool.server.rules.RulesUtils.cellsLeftInMap(blankCellMap)
                            this.ExclusionsMap(ruleid) = excludedCells;
                            unimportableCellMap = unimportableCellMap - blankCellMap;
                            blankCellMap = zeros(size(blankCellMap));
                        elseif internal.matlab.importtool.server.rules.RulesUtils.ruleIsForUnimportableCells(rule) && ...
                            internal.matlab.importtool.server.rules.RulesUtils.cellsLeftInMap(unimportableCellMap)
                            this.ExclusionsMap(ruleid) = excludedCells;
                            unimportableCellMap = zeros(size(unimportableCellMap));
                            blankCellMap = zeros(size(blankCellMap));
                        else
                            % if the rule has already been processed, we do
                            % not want to write over the map generated for
                            % the rule. we do, however, still need a map
                            % for the rule, because one will be expected
                            % later.
                            if this.ruleNotYetProcessed(ruleid)
                                this.ExclusionsMap(ruleid) = zeros(size(excludedCells));
                            end
                        end
                    end
                end
                this.RowExcludeRules = arrayfun(@(s) s.Action == internal.matlab.importtool.server.rules.UnimportableRules.ExcludeRows, this.Rules);
                this.ColExcludeRules = arrayfun(@(s) s.Action == internal.matlab.importtool.server.rules.UnimportableRules.ExcludeColumns, this.Rules);
            end
        end

        function [blankCells, unimportableCells] = invalidCellMaps(...
                this, data, raw, dateData, trimNonNumericCols, columnClasses)

            % create dummy rules for unimportable and blank rule
            % exclusions.
            unimportableRule = internal.matlab.importtool.server.rules.ExcludeUnimportableRowRule();
            blankRule = internal.matlab.importtool.server.rules.ExcludeRowsWithBlanksRule();

            % with the dummy rules we will create potential exclusion
            % strategies and get the excluded cells for both unimportable
            % and blank cells. These will be used to generate the final
            % exclusion map, accounting for the fact that the order of the
            % rules matters
            if isfield(this.FileImporterState, "DecimalSeparator")
                decimalSeparator = this.FileImporterState.DecimalSeparator;
            else
                decimalSeparator = ".";
            end

            if isfield(this.FileImporterState, "ThousandsSeparator")
                thousandsSeparator = this.FileImporterState.ThousandsSeparator;
            else
                thousandsSeparator = ",";
            end
            
            exclusionStrategy = unimportableRule.getRuleStrategy();
            unimportableCells = exclusionStrategy.getExcludedCells(...
                columnClasses, data, raw, dateData, ...
                trimNonNumericCols, decimalSeparator, ...
                thousandsSeparator);

            exclusionStrategy = blankRule.getRuleStrategy();
            blankCells = exclusionStrategy.getExcludedCells(...
                columnClasses, data, raw, dateData, ...
                trimNonNumericCols, decimalSeparator, ...
                thousandsSeparator);
        end

        % Sets the table model property for the rules, and forces the selection
        % update.
        function sendRuleUpdate(this)
            evt = internal.matlab.datatoolsservices.data.DataChangeEventData;
            
            data = struct();
            data.unimportableCellRule = this.Rules;
            data.refreshSelection = true;
            evt.NewData = data;
            this.notify("DataChange", evt);
        end

        % creates a new rule struct from the given pieces and adds it to the rules list
        function sendNewRule(this, action, valueType, value, varargin)
            newRule = struct('Action', action, 'ValueType', valueType, 'Value', value, ...
                'HumanReadable', internal.matlab.importtool.server.rules.RulesUtils.humanReadableRule(action, valueType, num2str(value)), ...
                'IsUnimportable', internal.matlab.importtool.server.rules.RulesUtils.isUnimportableRule(valueType), ...
                'index', this.NextRuleId);
            this.Rules = [ this.Rules, newRule ];
            this.NextRuleId = this.NextRuleId + 1;
            this.sendRuleUpdate();
        end

        % Updates a rule in the rules list with the specified index
        function sendRuleModification(this, action, valueType, value, index)
            newRule = struct('Action', action, 'ValueType', valueType, 'Value', value, ...
                'HumanReadable', internal.matlab.importtool.server.rules.RulesUtils.humanReadableRule(action, valueType, num2str(value)), ...
                'IsUnimportable', internal.matlab.importtool.server.rules.RulesUtils.isUnimportableRule(valueType), ...
                'index', index);
            this.Rules(index) = newRule;
            this.sendRuleUpdate();
        end

        % opens the create rule pop-up. this is intended to be triggered by the
        % new rule button action
        function addRule(this, x, y)
            import internal.matlab.importtool.server.rules.UnimportableRules;
            if internal.matlab.importtool.server.ImportUtils.dialogIsOpen(this.RuleDialog, "dialog")
                % a dialog is already open. bring it to the front and then
                % abandon ship
                figure(this.RuleDialog.dialog);
                this.RuleDialog.importToolCallback = @this.sendNewRule;

                actionString = internal.matlab.importtool.server.rules.RulesUtils.enumToAction(UnimportableRules.Replace);
                valueString = internal.matlab.importtool.server.rules.RulesUtils.enumToValue(UnimportableRules.ReplaceUnimportable);
                this.RuleDialog.updateAllValues(actionString, valueString, NaN, true);
                this.RuleDialog.dialog.Name = message(...
                    'MATLAB:codetools:importtool:NewRuleDialogTitle').string;
                return;
            end

            this.RuleDialog = internal.matlab.importtool.addRuleDialog(...
                @this.sendNewRule, x, y, ...
                message('MATLAB:codetools:importtool:NewRuleDialogTitle').string);
        end

        function closeNewRuleDialog(this)
            % Save and reset the lasterror state, since we don't care about
            % errors here
            l = lasterror;
            try
                delete(this.RuleDialog.dialog);
            catch
                % If deleting the add rule dialog didn't work, it's likely
                % because it wasn't open yet/anymore. If there was some
                % other error, there's nothing the user can do about it
                % anyway. No-op
            end
            lasterror(l);
        end

        % removes the rule at the given index. this is intended to be triggered
        % by the delete rule button action
        function removeRule(this, ruleIndex)
            indices = [this.Rules.index];
            positionInList = indices == ruleIndex;
            this.Rules(positionInList) = [];
            this.sendRuleUpdate();
        end

        % Called to modify the rule at the specified rule index
        function modifyRule(this, ruleIndex, x, y)
            import internal.matlab.importtool.server.rules.UnimportableRules;
            if internal.matlab.importtool.server.ImportUtils.dialogIsOpen(this.RuleDialog, "dialog")
                % a dialog is already open. bring it to the front and then
                % abandon ship
                figure(this.RuleDialog.dialog);
                this.RuleDialog.importToolCallback = @this.sendRuleModification;
                this.RuleDialog.dialog.Name = message(...
                    'MATLAB:codetools:importtool:ModifyRuleDialogTitle').string;
            else
                this.RuleDialog = internal.matlab.importtool.addRuleDialog(...
                    @this.sendRuleModification, x, y, ...
                    message('MATLAB:codetools:importtool:ModifyRuleDialogTitle').string);
            end

            allowReplaceEmpty = true;
            if ruleIndex == this.DEFAULT_UNIMPORTABLE_RULE
                % Default rule, show default values
                actionString = internal.matlab.importtool.server.rules.RulesUtils.enumToAction(UnimportableRules.Replace);
                valueString = internal.matlab.importtool.server.rules.RulesUtils.enumToValue(UnimportableRules.ReplaceUnimportable);
                val = NaN;
                positionInList = [];

                % Treat modification of the default rule as an add
                this.RuleDialog.importToolCallback = @this.sendNewRule;
                allowReplaceEmpty = false;
            else
                indices = [this.Rules.index];
                positionInList = indices == ruleIndex;
                ruleToModify = this.Rules(positionInList);
                actionString = internal.matlab.importtool.server.rules.RulesUtils.enumToAction(ruleToModify.Action);
                valueString = internal.matlab.importtool.server.rules.RulesUtils.enumToValue(ruleToModify.ValueType);
                val = ruleToModify.Value;
            end

            this.RuleDialog.importToolCallbackData = positionInList;
            this.RuleDialog.updateAllValues(actionString, valueString, val, allowReplaceEmpty);
        end

        function b = hasRowOrColumnExclusionRules(this)
            % Returns true if any of the rules in the rules list are row or
            % column exclusion rules
            b = any(arrayfun(@(s) s.Action == internal.matlab.importtool.server.rules.UnimportableRules.ExcludeColumns || ...
                s.Action == internal.matlab.importtool.server.rules.UnimportableRules.ExcludeRows, this.Rules));
        end

        function r = getRuleReplacementValue(this)
            % Returns the replacement value for the rules.  There can only be a
            % single unique replacement value.  Returns NaN if there are no
            % other replacements.
            values = {this.Rules.Value};
            b = cellfun(@(x) isnumeric(x), values);
            if any(b)
                r = values{b};
            else
                r = NaN;
            end
        end

        function v = getExclusionType(this, row, col, currType)
            v = currType;
            if this.hasRowOrColumnExclusionRules
                % Is the row excluded for unimportable or blank cells?

                for rowIdx = find(this.RowExcludeRules)
                    rule = this.Rules(rowIdx);
                    excludedRows = this.ExclusionsMap(internal.matlab.importtool.server.rules.RulesUtils.convertRuleToKey(rule));
                    if excludedRows(row)
                        v = this.ROW_EXCLUDED;
                        this.ExclusionRulesDisplayed = true;
                    end
                end

                for colIdx = find(this.ColExcludeRules)
                    rule = this.Rules(colIdx);
                    excludedCols = this.ExclusionsMap(internal.matlab.importtool.server.rules.RulesUtils.convertRuleToKey(rule));
                    if excludedCols(col)
                        v = this.COLUMN_EXCLUDED;
                        this.ExclusionRulesDisplayed = true;
                    end
                end
            end
        end

        function setFileImporterState(this, state)
            this.FileImporterState = state;
        end

        function rules = getRulesList(this)
            rules = internal.matlab.importtool.server.rules.ImportRule.empty(length(this.Rules), 0);
            for idx = 1:length(this.Rules)
                rule = this.Rules(idx);
                ruleString = internal.matlab.importtool.server.rules.RulesUtils.convertRuleToKey(rule);
                if strcmp(rule.Value, 'NaN')
                    value = NaN;
                else
                    value = rule.Value;
                end
                rules(idx) = internal.matlab.importtool.server.rules.ImportRuleFactory.getImportRuleFromText(ruleString, value);
            end
        end 
    end

    methods(Access = private)

        function notProcessed = ruleNotYetProcessed(this, ruleID)
            notProcessed = ~isKey(this.ExclusionsMap, ruleID);
        end
    end
end
