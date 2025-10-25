classdef ImportValidVariableNamesChangedAction < internal.matlab.datatoolsservices.actiondataservice.Action & internal.matlab.importtool.Actions.ImportActions
    % ImportValidVariableNamesChangedAction
    % Action for the 'Make valid variable names' checkbox in the toolstrip

    % Copyright 2019-2023 The MathWorks, Inc.
    properties(Access = {?internal.matlab.importtool.Actions.ImportValidVariableNamesChangedAction, ?matlab.unittest.TestCase})
        manager;
        props;
    end

    methods
        function this = ImportValidVariableNamesChangedAction(props, manager)
            if nargin < 1 || isempty(props)
                props = struct();
            end
            this@internal.matlab.datatoolsservices.actiondataservice.Action(props);
            this.ID = 'ValidVariableNamesChanged';
            this.manager = manager;
            this.Callback = @(varargin)this.setValidVariableNames(varargin{:});
        end

        function setValidVariableNames(this, varargin)
            evt = varargin{1};
            newValue = evt.text;
            doc = this.manager.FocusedDocument;
            doc.ViewModel.setValidVariableNames(newValue);
        end
    end
end

