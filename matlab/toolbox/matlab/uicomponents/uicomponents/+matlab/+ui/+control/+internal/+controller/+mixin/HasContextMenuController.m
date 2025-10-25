classdef (Hidden) HasContextMenuController <  appdesservices.internal.interfaces.controller.AbstractControllerMixin
    % HasContextMenuPropertyController Mixin for ContextMenu property

    % Copyright 2019-2023 The MathWorks, Inc.
    methods(Abstract, Access = protected)
        infoObject = getComponentInteractionInformation(obj, event, info)
    end
    methods (Static = true)

        function additionalProperties = getAdditonalContextMenuPropertyNamesForView()
            % These are non - public properties that need to be explicitly
            % added
            additionalProperties = {...
                'ContextMenuID';...
                'UIContextMenu';...
                };
        end

        function excludedPropertyNames = getExcludedContextMenuPropertyNamesForView()
            % Provide a list of property names that needs
            % to be excluded from the properties to sent to the view

            excludedPropertyNames = {...
                'ContextMenu';...
                'UIContextMenu';...
                };
        end
    end


    methods

        function viewPvPairs = getContextMenuPropertyForView(obj, propertyNames)
            % Update ContextMenu property so it can be sent to the view
            import appdesservices.internal.util.ismemberForStringArrays;
            viewPvPairs = {};
            propertiesToCheck = ["ContextMenu", "UIContextMenu"];
            propIsPresent = ismemberForStringArrays(propertiesToCheck, propertyNames);

            if any(propIsPresent)
                cmID = '';
                % Get ObjectID from UIContextMenu object
                if(~isempty(obj.Model.ContextMenu))
                    cmID = obj.Model.ContextMenu.ObjectID;
                end
                viewPvPairs = [viewPvPairs, ...
                    {'ContextMenuID', cmID} ...
                    ];
            end
        end

    end

    methods(Access = 'protected')

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:       handleEvent
        %
        %  Description:  handle the Callback event from the client
        %
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function wasHandled = handleEvent( obj, src, event )

            wasHandled = false;

            eventStructure = event.Data;
            switch ( eventStructure.Name )
                case 'ContextMenuOpeningFcn'
                    % If the component is a UIControl backing component,
                    % ignore the event. It was already processed by the
                    % UIControl.
                    if (obj.ViewModel.hasProperty('IsUIControl') && obj.ViewModel.getProperty('IsUIControl'))
                        return
                    end
                    
                    % process 'ContextMenuOpening' event from client to model
                    % Get the context menu object to fire the event
                    component = obj.getComponentToApplyContextMenuEvent(event);
                    contextMenu = component.ContextMenu;

                    interactionInformation.Source = component;
                    interactionInformation.LocationOffset = eventStructure.localOffset;

                    % Construct component-specific interaction information
                    interactionObject = obj.getComponentInteractionInformation(event, interactionInformation);
                    contextMenuOpeningData = matlab.ui.eventdata.ContextMenuOpeningData(component, interactionObject);
                                  contextMenuOpeningData = matlab.ui.eventdata.ContextMenuOpeningData(component, interactionObject);
                    contextMenu.notify('ContextMenuOpening',contextMenuOpeningData);
                    

                    % Save event data to the ContextMenu controller for use
                    % in MenuSelectedFcn
                    menuSelectedData = matlab.ui.eventdata.MenuSelectedData(component, interactionObject);
                    contextMenuController = contextMenu.getControllerHandle();
                    contextMenuController.MenuSelectedData = menuSelectedData;

                    wasHandled = true;
            end
        end
    end

end

