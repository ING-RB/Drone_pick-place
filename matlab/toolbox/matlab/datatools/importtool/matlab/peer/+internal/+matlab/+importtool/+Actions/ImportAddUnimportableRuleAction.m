classdef ImportAddUnimportableRuleAction < internal.matlab.datatoolsservices.actiondataservice.Action & ...
        internal.matlab.importtool.Actions.ImportActions & ...
        internal.matlab.importtool.Actions.DialogImportAction
    % ImportAddUnimportableRuleAction
    % Reacts to the add unimportable cells rule action on importtool

    % Copyright 2018-2023 The MathWorks, Inc.
    properties(Access = {?internal.matlab.importtool.Actions.ImportAddUnimportableRuleAction, ?matlab.unittest.TestCase})
        manager;
    end

    methods
        function this = ImportAddUnimportableRuleAction(props, manager)
            this@internal.matlab.datatoolsservices.actiondataservice.Action(props);
            this.ID = 'AddUnimportableRule';
            this.Enabled = true;
            this.manager = manager;
            this.Callback = @(varargin) this.addUnimportableCellsRule(varargin{:});
        end

        function addUnimportableCellsRule(this, varargin)
            % sometimes we get the pushbutton event and the add rule event
            % I'm not sure why we suddenly started getting both,
            % but this ignores the extra event
            if ~strcmp(varargin{1}.eventType, 'addUnimportableRule')
                return;
            end

            % Called to show the rules dialog to add a new dialog.  varargin is
            % the event data, a struct with the fields index, offsetX, and
            % offsetY (the latter two are used for positioning the rule
            % add dialog)

            % Get the offset dialog position, and show it
            [offsetX, offsetY] = this.getDialogPosition(varargin{1});

            doc = this.manager.FocusedDocument;
            doc.ViewModel.DataModel.getRulesStrategy().addRule(offsetX, offsetY);
        end
    end
end
