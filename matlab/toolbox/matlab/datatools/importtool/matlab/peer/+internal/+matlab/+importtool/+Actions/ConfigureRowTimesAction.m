classdef ConfigureRowTimesAction < internal.matlab.datatoolsservices.actiondataservice.Action & ...
        internal.matlab.importtool.Actions.ImportActions & ...
        internal.matlab.importtool.Actions.DialogImportAction
    % ConfigureRowTimesAction - action called when the user either hits the
    % button to configure row times, or selects the specify row times radio.

    % Copyright 2020-2023 The MathWorks, Inc.
    properties(Access = {?internal.matlab.importtool.Actions.ConfigureRowTimesAction, ?matlab.unittest.TestCase})
        manager;
        props;
    end

    methods
        function this = ConfigureRowTimesAction(props, manager)
            if nargin < 1 || isempty(props)
                props = struct();
            end
            this@internal.matlab.datatoolsservices.actiondataservice.Action(props);
            this.ID = "ConfigureRowTimes";
            this.Enabled = true;
            this.manager = manager;
            this.Callback = @(varargin) this.configureRowTimes(varargin{:});
        end

        function configureRowTimes(this, varargin)
            % Called to configure the row times.  Varargin is the event data,
            % which is a struct, with a field of buttonPressed (logical),
            % whether the "Configure" button was hit to show the configure row
            % times dialog or not.  It will optionally contain the x/y
            % offset coordinates, used to show the dialog.
            eventData = varargin{1};
            doc = this.manager.FocusedDocument;
            if ~isfield(eventData, "buttonPressed")
                return;
            end
            if eventData.buttonPressed
                % The user hit the "Configure" button to show the dialog
                % Get the offset dialog position, and show it
                [offsetX, offsetY] = this.getDialogPosition(eventData);

                doc.ViewModel.configureRowTimes(offsetX, offsetY);
            else
                % The user clicked the "Specify Row Times" radio button, make
                % sure the settings are correct in case the user never opens the
                % Configure Row Times dialog
                currRowTimesUnits = doc.ViewModel.getTableModelProperty("RowTimesUnits");
                rowTimesType = "timestep";
                if isempty(currRowTimesUnits)
                    % This is the first time selecting to specify the row times.
                    % Set default values for generating them:  Time Step of 1
                    % second, Start Time of duration(0,0,0)
                    values.TimeStep = true;
                    values.TimeStepValue = 1;
                    values.TimeStepUnits = "seconds";
                    values.StartTimeDuration = true;
                    values.DurationValue = duration(0, 0, 0);
                    doc.ViewModel.updateRowTimes(values);
                elseif strlength(currRowTimesUnits) == 0
                    % Sample rate is specified with no units
                    rowTimesType = "samplerate";
                end

                % Set the RowTimesType property
                doc.ViewModel.setTableModelProperty("RowTimesType", rowTimesType);
            end

            doc.ViewModel.updateRowTimesInTable();
        end
    end
end
