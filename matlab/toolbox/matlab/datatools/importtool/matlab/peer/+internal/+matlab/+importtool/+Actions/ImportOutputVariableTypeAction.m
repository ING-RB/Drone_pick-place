classdef ImportOutputVariableTypeAction < internal.matlab.datatoolsservices.actiondataservice.Action & ...
        internal.matlab.importtool.Actions.ImportActions & ...
        internal.matlab.importtool.Actions.DialogImportAction

    % ImportSelectionChangedAction
    % Reacts to the selection changed action on importtool

    % Copyright 2018-2023 The MathWorks, Inc.
    properties(Access = {?internal.matlab.importtool.Actions.ImportOutputVariableTypeAction, ?matlab.unittest.TestCase})
        Manager;
        IncludesVarName = true;
    end

    methods
        function this = ImportOutputVariableTypeAction(props, manager)
            if nargin < 1 || isempty(props)
                props = struct();
            end
            this@internal.matlab.datatoolsservices.actiondataservice.Action(props);
            this.ID = 'OutputVariableTypeChanged';
            this.Enabled = true;
            this.Manager = manager;
            this.Callback = @(varargin)this.setOutputVariableType(varargin{:});
        end

        function setOutputVariableType(this, varargin)
            % Get the new output variable type
            newValue = internal.matlab.importtool.Actions.ImportOutputVariableTypeAction.getNewPropertyValue(varargin{1});
            doc = this.Manager.FocusedDocument;
            doc.ViewModel.setState("OutputVariableType", newValue);
        end
    end

    methods(Static)
        function newValue = getNewPropertyValue(eventData)
            % Return the new output variable type
            newValue = eventData;
            newValue.property = 'OutputVariableType';
            newValue.value = eventData.text;
        end
    end
end

