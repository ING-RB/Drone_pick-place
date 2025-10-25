classdef ImportModifyUnimportableRuleAction < internal.matlab.datatoolsservices.actiondataservice.Action & ...
        internal.matlab.importtool.Actions.ImportActions & ...
        internal.matlab.importtool.Actions.DialogImportAction
    % ImportModifyUnimportableRuleAction
    % Reacts to the modify unimportable cells rule action on importtool

    % Copyright 2018-2023 The MathWorks, Inc.
    properties(Access = {?internal.matlab.importtool.Actions.ImportModifyUnimportableRuleAction, ?matlab.unittest.TestCase})
        manager;
        props;
    end

    methods
        function this = ImportModifyUnimportableRuleAction(props, manager)
            this@internal.matlab.datatoolsservices.actiondataservice.Action(props);
            this.ID = 'ModifyUnimportableRule';
            this.Enabled = true;
            this.manager = manager;
            this.Callback = @(varargin) this.modifyUnimportableCellsRule(varargin{:});
        end

        function modifyUnimportableCellsRule(this, varargin)
            % Called to show the Rules dialog, to modify the rule at the
            % specified index.  varargin is the event data, a struct with the
            % fields index, offsetX, and offsetY (the latter two are used for
            % positioning the rule modification dialog)
            if isfield(varargin{1}, 'index')
                modifyIndex = varargin{1}.index;

                % Get the offset dialog position, and show it
                [offsetX, offsetY] = this.getDialogPosition(varargin{1});

                doc = this.manager.FocusedDocument;
                doc.ViewModel.DataModel.getRulesStrategy().modifyRule(modifyIndex, offsetX, offsetY);
            end
        end
    end
end
