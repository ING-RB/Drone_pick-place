classdef ImportOutputVariableNameAction < internal.matlab.datatoolsservices.actiondataservice.Action & internal.matlab.importtool.Actions.ImportActions
    % ImportSelectionChangedAction
    % Reacts to the selection changed action on importtool

    % Copyright 2018-2023 The MathWorks, Inc.
    properties(Access = {?internal.matlab.importtool.Actions.ImportOutputVariableNameAction, ?matlab.unittest.TestCase})
        manager;
        props;
    end

    methods
        function this = ImportOutputVariableNameAction(props, manager)
            if nargin < 1 || isempty(props)
                props = struct();
            end
            this@internal.matlab.datatoolsservices.actiondataservice.Action(props);
            this.ID = 'OutputVariableNameChanged';
            this.Enabled = true;
            this.manager = manager;
            this.Callback = @(varargin)this.setOutputVariableName(varargin{:});
        end

        function setOutputVariableName(this, varargin)
            newValue = internal.matlab.importtool.Actions.ImportOutputVariableNameAction.getNewPropertyValue(varargin);
            doc = this.manager.FocusedDocument;
            doc.ViewModel.setOutputVariableName(newValue.value);
        end
    end

    methods(Static)
        function newValue = getNewPropertyValue(varargin)
            newValue = struct();
            newValue.property = 'OutputVariableName';
            % varargin is a nested cell array where the inner cell contains
            % the event data and event type
            newValue.value = varargin{1}{1}.text;
        end
    end
end

