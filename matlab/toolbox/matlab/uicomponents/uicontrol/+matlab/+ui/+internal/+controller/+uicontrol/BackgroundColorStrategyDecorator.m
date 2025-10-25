classdef BackgroundColorStrategyDecorator < matlab.ui.internal.controller.uicontrol.RedirectStrategyDecorater
    %BACKGROUNDCOLORSTRATEGYDECORATOR A decorator class for
    % instances of UicontrolRedirectStrategy.  It adds a label behind the
    % backing component to mimic background color for that component.

    % Copyright 2020-2021 The MathWorks, Inc.

    properties (Access = private)
        % The uilabel instance that will be drawn behind the uicontrol in
        % the view.
        BackgroundColorLabel
    end

    methods

        function obj = BackgroundColorStrategyDecorator(strategy, label)
            obj = obj@matlab.ui.internal.controller.uicontrol.RedirectStrategyDecorater(strategy);
            obj.BackgroundColorLabel = label;
        end

        function pvPairs = translateToUIComponentProperty(obj, uicontrolModel, uicomponent, propName)
            pvPairs = translateToUIComponentProperty@matlab.ui.internal.controller.uicontrol.RedirectStrategyDecorater(obj, uicontrolModel, uicomponent, propName);

            % Intercept property sets to keep the label in-sync with the
            % uicontrol.  Position and Visible must stay in-sync to keep
            % the label showing properly.
            publicPropName = obj.convertInternalNameToPublicName(propName);

            % When the UIControl moves, or is made invisible, the
            % background color label should move or change visibility along
            % with it.  Otherwise, nothing needs to be done.
            if startsWith(publicPropName, {'BackgroundColor', 'Position', 'Visible'})
                obj.BackgroundColorLabel.(publicPropName) = uicontrolModel.(publicPropName);
            elseif startsWith(publicPropName, 'Units')
                % If Units change we also need to update Position as that
                % will be automatically updated on the UIControl model.
                obj.BackgroundColorLabel.Position = uicontrolModel.Position;
            end
        end

        function controller = createBackingController(obj, uicontrolModel, uicomponent, parentController)
            controllerFactory = matlab.ui.control.internal.controller.ComponentControllerFactoryManager.Instance.ControllerFactory;

            % Create the background color label before creating the
            % controller for the Radio Button.  This ensures the label
            % appears behind the radio button.
            labelController = controllerFactory.createController(obj.BackgroundColorLabel, parentController);
            % Tell the client to treat the label as a UIControl.  This
            % enables normalized units for the label
            viewmodel.internal.factory.ManagerFactoryProducer.setProperties(labelController.ViewModel, {'IsUIControl', true});

            controller = createBackingController@matlab.ui.internal.controller.uicontrol.RedirectStrategyDecorater(obj, uicontrolModel, uicomponent, parentController);
        end

        function updateBackingComponentView(obj, uicomponent)
            obj.BackgroundColorLabel.flushDirtyProperties();
            updateBackingComponentView@matlab.ui.internal.controller.uicontrol.RedirectStrategyDecorater(obj, uicomponent);
        end

        function hideBackingUIComponent(obj, backingUIComponent)
            obj.BackgroundColorLabel.Visible = 'off';
            hideBackingUIComponent@matlab.ui.internal.controller.uicontrol.RedirectStrategyDecorater(obj, backingUIComponent);
        end

        function showBackingUIComponent(obj, backingUIComponent, uicontrolModel)
            obj.BackgroundColorLabel.Visible = uicontrolModel.Visible;
            showBackingUIComponent@matlab.ui.internal.controller.uicontrol.RedirectStrategyDecorater(obj, backingUIComponent, uicontrolModel);
        end

        function delete(obj)
            % Make sure the label is deleted to avoid leaking it in the figure.
            delete(obj.BackgroundColorLabel);
        end
    end
end
