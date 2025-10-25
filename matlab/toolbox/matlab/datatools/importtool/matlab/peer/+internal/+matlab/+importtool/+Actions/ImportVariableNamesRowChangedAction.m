classdef ImportVariableNamesRowChangedAction < internal.matlab.datatoolsservices.actiondataservice.Action & internal.matlab.importtool.Actions.ImportActions
    % ImportVariableNamesRowChanged
    % Action to track the header row of the data in the Import Tool

    % Copyright 2018-2023 The MathWorks, Inc.
    properties(Access = {?internal.matlab.importtool.Actions.ImportVariableNamesRowChangedAction, ?matlab.unittest.TestCase})
        manager;
        props;
    end

    methods
        function this = ImportVariableNamesRowChangedAction(props, manager)
            if nargin < 1 || isempty(props)
                props = struct();
            end
            this@internal.matlab.datatoolsservices.actiondataservice.Action(props);
            this.ID = 'VariableNamesRowChanged';
            this.Enabled = true;
            this.manager = manager;
            this.Callback = @(varargin)this.setVariableNamesRowAction(varargin{:});
        end

        function setVariableNamesRowAction(this, varargin)
            if strcmp(varargin{1}.eventType, 'valueChanged')
                newValue = internal.matlab.importtool.Actions.ImportVariableNamesRowChangedAction.getNewPropertyValue(varargin{1});
                if ~isempty(newValue)
                    doc = this.manager.FocusedDocument;
                    doc.ViewModel.setImportVariableNamesRow(newValue);
                end
            end
        end
    end

    methods(Static)
        function newValue = getNewPropertyValue(event)
            newValue = event.newValue;
            if ischar(newValue) || isstring(newValue)
                newValue = str2double(newValue);
            end

            if isnan(newValue) || newValue < 1
                newValue = [];
            end
        end
    end
end

