classdef Controller < ...
        matlabshared.mediator.internal.Subscriber & ...
        matlabshared.mediator.internal.Publisher & ...
        matlabshared.transportapp.internal.utilities.ITestable & ...
        matlabshared.testmeasapps.internal.dialoghandler.DialogSource

    % CONTROLLER is the controller class for the Communication Log Section
    % of the toolstrip. It contains business logic for operations that need
    % to be performed when user interacts with the View elements.

    % Copyright 2021-2023 The MathWorks, Inc.

    properties (Constant)
        Constants = matlabshared.transportapp.internal.toolstrip.analyze.Constants
    end

    properties (Dependent)
        View
    end

    properties (Access = {?matlabshared.transportapp.internal.utilities.ITestable})
        ViewListeners = event.listener.empty

        % Check for whether the Signal Analyzer app is installed
        SPToolboxInstalled = []

        % The Communication Table row that is selected to be plotted or
        % viewed in the Signal Analyzer app.
        SelectedRowData

        % The handle to the ViewConfiguration instance containing the View.
        ViewConfiguration

        % Check for whether the communication log table is empty.
        TableEmpty (1, 1) logical = true

        FigureHandles
    end

    %% Lifetime
    methods
        function obj = Controller(mediator, viewConfiguration, ~)
            arguments
                mediator matlabshared.mediator.internal.Mediator
                viewConfiguration matlabshared.transportapp.internal.utilities.viewconfiguration.IViewConfiguration
                ~
            end
            obj@matlabshared.mediator.internal.Publisher(mediator);
            obj@matlabshared.mediator.internal.Subscriber(mediator);
            obj@matlabshared.testmeasapps.internal.dialoghandler.DialogSource(mediator);
            obj.ViewConfiguration = viewConfiguration;

            % Only for production mode
            if isa(obj.ViewConfiguration, ...
                    "matlabshared.transportapp.internal.utilities.viewconfiguration.ViewConfiguration")
                obj.setupListeners();
            end
        end

        function delete(obj)
            delete(obj.ViewListeners);

            for figHandle = obj.FigureHandles
                if isvalid(figHandle)
                    delete(figHandle);
                end
            end
        end
    end

    %% Implement matlabshared.mediator.internal.Subscriber abstract methods
    methods
        function subscribeToMediatorProperties(obj, ~, ~)

            obj.subscribe('SelectedRowData', ...
                @(src, event)obj.handleSelectedRowChanged(event.AffectedObject.SelectedRowData));

            obj.subscribe('TableValue', ...
                @(src, event)obj.checkTableEmpty(event.AffectedObject.TableValue));
        end
    end

    %% Subscriber handler methods
    methods
        function handleSignalAnalyzerOption(obj, options)
            % The confirmation dialog is shown and when user clicks "Open" to launching the add-ons explorer page
            % when they do not have the SPT license.
            if string(showConfirmationDialog(obj, options)) == obj.Constants.OpenOption
                matlab.internal.addons.launchers.showExplorer(obj.Constants.SigAnUniqueID, "identifier", "SG");
            end
        end

        function handleNoDataSelected(obj, option)
            % The confirmation dialog is shown and it launchs the signal analyzer app if
            % user selected "Open Anyway".
            if string(showConfirmationDialog(obj, option)) == obj.Constants.OpenAnywayOption
                signalAnalyzer();
            end
        end

        function handleSelectedRowChanged(obj, selectedRow)
            % When the user clicks on a different row of the communication
            % log table, get the row data.

            obj.SelectedRowData = selectedRow;
        end
    end

    %% Listener Functions
    methods (Access = {?matlabshared.transportapp.internal.utilities.ITestable})
        function plotButtonPressed(obj, ~, ~)
            % Handler for when the "Plot" button is pressed.

            button = "PlotButton";
            cleanup = onCleanup(@()obj.reEnableButton(button));
            obj.ViewConfiguration.setViewProperty(button, "Enabled", false);

            try
                if obj.TableEmpty
                    throw(MException(message("transportapp:toolstrip:analyze:PlotErrorTableEmpty")));
                end

                if isempty(obj.SelectedRowData)
                    throw(MException(message("transportapp:toolstrip:analyze:PlotErrorNoSelectedRow")));
                end
            catch ex
                showErrorDialog(obj, ex);
                return
            end

            try
                validateattributes(obj.SelectedRowData.Data, "numeric", "nonempty");

                if isempty(obj.FigureHandles)
                    obj.FigureHandles = figure;
                else
                    obj.FigureHandles(end+1) = figure;
                end

                % Make the figure window themeable.
                matlab.graphics.internal.themes.figureUseDesktopTheme(obj.FigureHandles(end));
                ax = axes(Parent=obj.FigureHandles(end));
                if isscalar(obj.SelectedRowData.Data)
                    plot(obj.SelectedRowData.Data, "-o", Parent=ax);
                else
                    plot(obj.SelectedRowData.Data, Parent=ax);
                end
                uistack(ax,"top");
            catch
                ex = MException(message("transportapp:toolstrip:analyze:PlotFailed"));
                showErrorDialog(obj, ex);
            end
        end

        function sigAnButtonPressed(obj, ~, ~)
            % Handler for when the "Signal Analyzer" button is pressed.

            button = "SignalAnalyzerButton";
            cleanup = onCleanup(@()obj.reEnableButton(button));
            obj.ViewConfiguration.setViewProperty(button, "Enabled", false);

            % Do a one time check for toolbox installed.
            if isempty(obj.SPToolboxInstalled)
                obj.SPToolboxInstalled = ~isempty(ver('signal'));
            end

            try
                % If the Signal Processing Toolbox is installed, validate
                % that there is a valid license associated with the
                % toolbox.
                if obj.SPToolboxInstalled
                    validateSPTLicense(obj);
                    exportToSignalAnalyzer(obj);
                else
                    % Prepare the option dialogs for when the Signal
                    % Analyzer button is pressed when there is no Signal
                    % Processing Toolbox.
                    options = matlabshared.testmeasapps.internal.dialoghandler.forms.OptionsForm;
                    options.Message = obj.Constants.NoLicenseOptionStringText;
                    options.Options = [obj.Constants.OpenOption, obj.Constants.NoOption];
                    options.DefaultOption = string(obj.Constants.NoOption);
                    handleSignalAnalyzerOption(obj, options);

                end
            catch ex
                showErrorDialog(obj, ex);
            end

            function exportToSignalAnalyzer(obj)
                % Launch Signal Analyser app with the selected row data.
                % When the table is empty or no table row is selected,
                % inform the user that no data is selected to be viewed in
                % the Signal Analyzer app, and do users still want to open
                % the Signal Analyzer app.

                if obj.TableEmpty || isempty(obj.SelectedRowData)
                    option = matlabshared.testmeasapps.internal.dialoghandler.forms.OptionsForm;
                    option.Message = obj.Constants.NoDataSelectedOptionStringText;
                    option.Options = [obj.Constants.OpenAnywayOption, obj.Constants.NoOption];
                    option.DefaultOption = string(obj.Constants.OpenAnywayOption);
                    handleNoDataSelected(obj, option);
                else
                    signalAnalyzer(obj.SelectedRowData.Data);
                end
            end
        end

        function checkTableEmpty(obj, tableValue)
            % Check whether the communication log table is empty or not.

            obj.TableEmpty = isempty(tableValue);
        end
    end

    %% Other helper methods
    methods (Access = {?matlabshared.transportapp.internal.utilities.ITestable})
        function setupListeners(obj)
            obj.ViewListeners(end+1) = listener(obj.View, "PlotButtonPressed", ...
                @(src, evt)obj.plotButtonPressed(src, evt));

            obj.ViewListeners(end+1) = listener(obj.View, "SignalAnalyzerButtonPressed", ...
                @(src, evt)obj.sigAnButtonPressed(src, evt));
        end

        function validateSPTLicense(~)
            % If the toolbox is already installed but no SPT license is
            % found, throw an error.

            [checkoutLicense, ~] = builtin('license','checkout','Signal_Toolbox');
            if ~checkoutLicense
                throw(MException(message("transportapp:toolstrip:analyze:NoSPTLicense")));
            end
        end

        function reEnableButton(obj, button)
            arguments
                obj
                button (1, 1) string {mustBeMember(button, ["PlotButton", "SignalAnalyzerButton"])} = "PlotButton"
            end
            obj.ViewConfiguration.setViewProperty(button, "Enabled", true);
        end
    end

    %% Getters and Setters
    methods
        function value = get.View(obj)
            value = obj.ViewConfiguration.View;
        end
    end
end
