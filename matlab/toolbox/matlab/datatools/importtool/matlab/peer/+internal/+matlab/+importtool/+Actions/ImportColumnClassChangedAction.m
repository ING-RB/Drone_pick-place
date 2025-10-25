classdef ImportColumnClassChangedAction < internal.matlab.datatoolsservices.actiondataservice.Action & internal.matlab.importtool.Actions.ImportActions
    % ImportColumnClassChangedAction
    % Action to update a column's class in the Import Tool

    % Copyright 2018-2023 The MathWorks, Inc.
    properties(Access = {?internal.matlab.importtool.Actions.ImportColumnClassChangedAction, ?matlab.unittest.TestCase})
        manager;
        props;
    end

    methods
        function this = ImportColumnClassChangedAction(props, manager)
            if nargin < 1 || isempty(props)
                props = struct();
            end
            this@internal.matlab.datatoolsservices.actiondataservice.Action(props);
            this.ID = 'ColumnClassChangedAction';
            this.Enabled = true;
            this.manager = manager;
            this.Callback = @(varargin)this.setColumnClassAction(varargin{:});
        end

        function setColumnClassAction(this, varargin)
            newValue = internal.matlab.importtool.Actions.ImportColumnClassChangedAction.getNewPropertyValue(varargin{:});
            doc = this.manager.FocusedDocument;
            doc.ViewModel.setImportColumnClass(newValue.indices, newValue.dataType, newValue.dataTypeOption);
        end
    end

    methods(Static)
        % Fetches newValue from actionInfo. if
        % index/indices/dataTypeOption are absent, assign defaults.
        function newValue = getNewPropertyValue(varargin)
            actionInfo = varargin{1}.actionInfo;
            if ~isfield(actionInfo, 'index')
                actionInfo.index = [];
            end
            if ~isfield(actionInfo, 'indices')
                actionInfo.indices = [];
            end
            newValue = struct();
            newValue.indices = double([actionInfo.index actionInfo.indices]) + 1;
            newValue.dataType = actionInfo.dataType;
            if ~isfield(actionInfo, 'dataTypeOption')
                newValue.dataTypeOption = '';
            else
                newValue.dataTypeOption = actionInfo.dataTypeOption;
            end
        end
    end
end
