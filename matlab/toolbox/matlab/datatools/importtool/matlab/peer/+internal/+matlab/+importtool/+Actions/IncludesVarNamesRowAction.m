classdef IncludesVarNamesRowAction < internal.matlab.datatoolsservices.actiondataservice.Action & internal.matlab.importtool.Actions.ImportActions
    % IncludesVarNamesRowAction - action for when the "Variable Names Row"
    % checkbox is toggled, which is used to indicate whether or not the file has
    % a variable names row.

    % Copyright 2019-2023 The MathWorks, Inc.
    properties(Access = {?internal.matlab.importtool.Actions.IncludesVarNamesRowAction, ?matlab.unittest.TestCase})
        manager;
        props;
    end

    methods
        function this = IncludesVarNamesRowAction(props, manager)
            if nargin < 1 || isempty(props)
                props = struct();
            end
            this@internal.matlab.datatoolsservices.actiondataservice.Action(props);
            this.ID = "IncludesVariableNamesRowChanged";
            this.manager = manager;
            this.Callback = @(varargin)this.setIncludesVarNamesRowAction(varargin{:});
        end

        function setIncludesVarNamesRowAction(this, varargin)
            evt = varargin{1};
            enabled = evt.enabled;
            doc = this.manager.FocusedDocument;
            vm = doc.ViewModel;

            vm.updateIncludesVarNamesRow(enabled);
        end
    end
end

