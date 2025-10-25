classdef UIControlPopupMenuController < matlab.ui.internal.controller.uicontrol.UIControlController
    % UIControlPopupMenuController Web-based controller for uicontrol-popup.

    %   Copyright 2023 The MathWorks, Inc.

    methods( Access = 'protected' )
        function defineViewProperties( obj ) 
             defineViewProperties@matlab.ui.internal.controller.uicontrol.UIControlController(obj);
             obj.PropertyManagementService.defineViewProperty('Value');

             % Maps to SelectedIndex
             obj.PropertyManagementService.defineViewProperty('String');
        end

        function definePropertyDependencies( obj ) 
            definePropertyDependencies@matlab.ui.internal.controller.uicontrol.UIControlController(obj);
            obj.PropertyManagementService.definePropertyDependency("String", "Items");
            obj.PropertyManagementService.definePropertyDependency("Value", "SelectedIndex");
        end

        function defineRequireUpdateProperties( obj )
            defineRequireUpdateProperties@matlab.ui.internal.controller.uicontrol.UIControlController(obj);
        end

        function handleEvent(obj, src, event) 
            handleEvent@matlab.ui.internal.controller.uicontrol.UIControlController(obj, src, event);
            switch event.Data.Name
                case 'StateChanged'
                    obj.processValueChangedFromSelection(event);
                case 'processKeyEvent'
                    % Always process the event for uicontrol
                    if strcmp(event.Data.Name, 'processKeyEvent') && strcmp(event.Data.data.key,'enter')
                        obj.triggerActionEvent();
                    end
                   
                case 'Clicked'
                    %Popup menus should fire the callback even if the data
                    %doesnt fire. In this case, the popupmenu widget doesnt
                    %fire an event so instead we listen for a click on an
                    %item. event.Data.item will be empty if no item. 
                    if(~isempty(event.Data.item))
                        obj.triggerActionEvent();
                    end
            end
        end
    end

    methods

        function val = fallbackDefaultBackgroundColor ( ~ )
            val = [1,1,1];
        end

        function className = getViewModelType(~, ~)
            className = 'matlab.ui.control.UIControlDropDown';
        end

        function val = updateSelectedIndex(obj)
            import matlab.ui.internal.controller.uicontrol.UIControlConversionRules.convertValueToSelectedIndex;
            val = convertValueToSelectedIndex(obj.Model.String, obj.Model.Value);
        end

        function val = updateItems(obj)
            import matlab.ui.internal.controller.uicontrol.UIControlConversionRules.convertStringToItems;
            val = convertStringToItems(obj.Model.String);
        end
    end
end
