classdef ImportRemoveUnimportableRuleAction < internal.matlab.datatoolsservices.actiondataservice.Action & internal.matlab.importtool.Actions.ImportActions
    % ImportRemoveUnimportableRuleAction
    % Reacts to the remove unimportable cells rule action on importtool

    % Copyright 2018-2023 The MathWorks, Inc.
    properties(Access = {?internal.matlab.importtool.Actions.ImportRemoveUnimportableRuleAction, ?matlab.unittest.TestCase})
        manager;
        props;
    end

    methods
        function this = ImportRemoveUnimportableRuleAction(props, manager)
            this@internal.matlab.datatoolsservices.actiondataservice.Action(props);
            this.ID = 'RemoveUnimportableRule';
            this.Enabled = true;
            this.manager = manager;
            this.Callback = @(varargin) this.removeUnimportableCellsRule(varargin{:});
        end

        function removeUnimportableCellsRule(this, varargin)
            if isfield(varargin{1}, 'index')
                removeIndex = varargin{1}.index;

                doc = this.manager.FocusedDocument;
                doc.ViewModel.DataModel.FileImporter.RulesStrategy.removeRule(removeIndex);
            end
        end
    end
end
