classdef RowTimesColumnChangedAction < internal.matlab.datatoolsservices.actiondataservice.Action & internal.matlab.importtool.Actions.ImportActions
    % RowTimesColumnChanged
    % Reacts to the timetable row times column changed

    % Copyright 2020-2023 The MathWorks, Inc.
    properties(Access = {?internal.matlab.importtool.Actions.RowTimesColumnChangedAction, ?matlab.unittest.TestCase})
        manager;
        props;
    end

    methods
        function this = RowTimesColumnChangedAction(props, manager)
            if nargin < 1 || isempty(props)
                props = struct();
            end
            this@internal.matlab.datatoolsservices.actiondataservice.Action(props);
            this.ID = "RowTimesColumnChanged";
            this.Enabled = true;
            this.manager = manager;
            this.Callback = @(varargin)this.setRowTimesColumnChanged(varargin{:});
        end

        function setRowTimesColumnChanged(this, varargin)
            if nargin < 2
                return;
            end

            % Get the new value for the row times column
            newValue = internal.matlab.importtool.Actions.RowTimesColumnChangedAction.getNewPropertyValue(varargin{1});
            if ~isempty(newValue)
                % If we have a new value, update the table model properties, and
                % update the row times which are displayed
                doc = this.manager.FocusedDocument;
                doc.ViewModel.setTableModelProperties(...
                    "RowTimesColumn", newValue, ...
                    "RowTimesType", "column");
                doc.ViewModel.updateRowTimesInTable();
            end
        end
    end

    methods(Static)
        function value = getNewPropertyValue(eventData)
            value = [];
            if isfield(eventData, "text")
                % eventData contains the event data and event type
                value = eventData.text;
            end
        end
    end
end

