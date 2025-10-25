classdef ImportVariableWidthsChangedAction < internal.matlab.datatoolsservices.actiondataservice.Action & internal.matlab.importtool.Actions.ImportActions
    % ImportVariableWidthsChangedAction
    % Reacts to the selection changed action on importtool

    % Copyright 2018-2023 The MathWorks, Inc.
    properties(Access = {?internal.matlab.importtool.Actions.ImportVariableWidthsChangedAction, ?matlab.unittest.TestCase})
        manager;
        props;
    end

    methods
        function this = ImportVariableWidthsChangedAction(props, manager)
            if nargin < 1 || isempty(props)
                props = struct();
            end
            this@internal.matlab.datatoolsservices.actiondataservice.Action(props);
            this.ID = 'VariableWidthsChanged';
            this.Enabled = true;
            this.manager = manager;
            this.Callback = @(varargin)this.setVariableWidths(varargin{:});
        end

        function setVariableWidths(this, varargin)
            newValue = double(varargin{1}.actionInfo.variableWidths)';
            doc = this.manager.FocusedDocument;

            doc.ViewModel.setState("VariableWidths", newValue);
        end
    end
end
