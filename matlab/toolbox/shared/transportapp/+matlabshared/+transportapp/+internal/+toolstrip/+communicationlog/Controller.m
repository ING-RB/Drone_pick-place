classdef Controller < matlabshared.mediator.internal.Publisher & ...
        matlabshared.mediator.internal.Subscriber & ...
        matlabshared.transportapp.internal.utilities.ITestable & ...
        matlabshared.transportapp.internal.toolstrip.communicationlog.IController & ...
        matlabshared.testmeasapps.internal.dialoghandler.DialogSource

    % CONTROLLER is the controller class for the Communication Log Section
    % of the toolstrip. It contains business logic for operations that need
    % to be performed when user interacts with the View elements.

    % Copyright 2021-2023 The MathWorks, Inc.

    properties (SetObservable)
        % The display type drowpdown value selected by the user.
        DisplayType

        % The command to clear the Communication Log table.
        ClearTable
    end

    properties (Access = protected)
        % The handle to the ViewConfiguration instance containing the View.
        ViewConfiguration

        % Check for whether the communication log table is empty.
        TableEmpty (1,1) logical = true
    end

    properties (Dependent)
        View
    end

    properties (Constant)
        Constants = matlabshared.transportapp.internal.toolstrip.communicationlog.Constants
    end

    properties (Access = {?matlabshared.transportapp.internal.utilities.ITestable})
        ViewListeners = event.listener.empty
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
        end
    end

    %% Implement matlabshared.mediator.internal.Subscriber abstract methods
    methods
        function subscribeToMediatorProperties(obj, ~, ~)

            obj.subscribe('TableValue', ...
                @(src, event)obj.handleTableValue(event.AffectedObject.TableValue));
        end
    end

    %% Listener Functions
    methods (Access = {?matlabshared.transportapp.internal.utilities.ITestable})
        function displayValueChanged(obj, ~, evt)
            % When the Display type option changes.

            obj.DisplayType = evt.Data;
        end

        function clearLogButtonPressed(obj, ~, ~)
            % When the "Clear Log" button is pressed.

            if obj.TableEmpty
                return
            end

            % Create the options dialog asking users if it is okay to clear
            % the communication log table contents.
            options = matlabshared.testmeasapps.internal.dialoghandler.forms.OptionsForm;
            options.Message = obj.Constants.OptionStringText;
            options.Options = [obj.Constants.YesOption, obj.Constants.NoOption];
            options.DefaultOption = string(obj.Constants.NoOption);
            handleClearCommunicationLogOption(obj,options)
        end
       
        function handleClearCommunicationLogOption(obj,options)
            % The confirmation dialog is shown and the it clears the communicationLog if
            % user selected Yes.
            if string(showConfirmationDialog(obj, options)) == obj.Constants.YesOption
                obj.ClearTable = true;
            end
        end

        function handleTableValue(obj, tableValue)
            % Handler that notifies whenever there is a change in the
            % communication log table data.

            obj.TableEmpty = isempty(tableValue);
        end
    end

    %% Other helper methods
    methods (Access = private)
        function setupListeners(obj)
            obj.ViewListeners(end+1) = listener(obj.View, "DisplayValueChanged", ...
                @(src, evt)obj.displayValueChanged(src, evt));

            obj.ViewListeners(end+1) = listener(obj.View, "ClearLogButtonPressed", ...
                @(src, evt)obj.clearLogButtonPressed(src, evt));
        end
    end

    %% Getters and Setters
    methods
        function value = get.View(obj)
            value = obj.ViewConfiguration.View;
        end
    end
end
