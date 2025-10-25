% HASCONTEXTMENUBEHAVIORADDON Web-based controller addon class.
classdef HasContextMenuBehaviorAddOn < matlab.ui.internal.componentframework.services.optional.BehaviorAddOn
    %

    %   Copyright 2019-2022 The MathWorks, Inc.

    methods ( Access=protected )

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:      defineViewProperties
        %
        %  Description: Within the context of MVC ( Model-View-Controller )
        %               software paradigm, this is the method the "Controller"
        %               layer uses to define which properties will be consumed by
        %               the web-based user interface.
        %  Inputs:      None
        %  Outputs:     None
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function defineViewProperties( ~, propManagementService )
            % Define Model properties that concern the view. 
            propManagementService.defineViewProperty("UIContextMenu");
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:      definePropertyDependencies
        %  Description: Within the context of MVC ( Model-View-Controller )
        %               software paradigm, this is the method the "Controller"
        %               layer uses to establish property dependencies between
        %               a property (or set of properties) defined by the "Model"
        %               layer and dependent "View" layer property.
        %  Inputs:      None
        %  Outputs:     None
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function definePropertyDependencies( ~, propManagementService )
            % Define mapping form Model -> View Property.
            propManagementService.definePropertyDependency("UIContextMenu", "ContextMenuID");
        end
    end

    methods

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:  Constructor
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function this = HasContextMenuBehaviorAddOn( propManagementService )
            % Super constructor
            this = this@matlab.ui.internal.componentframework.services.optional.BehaviorAddOn( propManagementService );
        end

        function newUIContextMenu = updateContextMenuID( ~, uiContextMenu)
            newUIContextMenu = '';
            if(~isempty(uiContextMenu))
                % Get ContextMenuID from UIContextMenu object
                newUIContextMenu = uiContextMenu.ObjectID;
            end      
         end     

         function wasHandled = handleEvent( obj, controller, component, src, eventStructure )

            wasHandled = false;

            switch ( eventStructure.Name )
                case 'ContextMenuOpeningFcn'
                    % process 'ContextMenuOpeningFcn' event from client to model
                    % Get the context menu object to fire the event

                    if (isa(component, 'matlab.ui.container.TabGroup') &&...
                            ~isempty(eventStructure.tab))
                        % Special case for TabGroup (via Tab thumb node)
                        % Component should be the Tab that was right-clicked
                        component = controller.getChildTabComponent(eventStructure.tab);
                    end

                    contextMenu = component.ContextMenu;

                    interactionInformation.Source = component;
                    interactionInformation.LocationOffset = eventStructure.localOffset;

                    % Add component-specific information
                    interactionInformation = controller.addComponentSpecificInteractionInformation(interactionInformation, eventStructure);
                    interactionObject = controller.constructInteractionObject(interactionInformation);
                    contextMenuOpeningData = matlab.ui.eventdata.ContextMenuOpeningData(component, interactionObject);
                    contextMenu.notify('ContextMenuOpening',contextMenuOpeningData);

                    % Save event data to the ContextMenu controller for use
                    % in MenuSelectedFcn
                    menuSelectedData = matlab.ui.eventdata.MenuSelectedData(component, interactionObject);
                    contextMenuController = controller.getControllerFromModel(contextMenu);
                    contextMenuController.MenuSelectedData = menuSelectedData;

                    wasHandled = true;
            end
         end
    end
end
