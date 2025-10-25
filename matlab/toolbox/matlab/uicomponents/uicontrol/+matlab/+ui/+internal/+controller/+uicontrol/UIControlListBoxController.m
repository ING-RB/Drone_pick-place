classdef UIControlListBoxController < matlab.ui.internal.controller.uicontrol.UIControlController
    % UIControlListBoxController Web-based controller for uicontrol listbox.

    %   Copyright 2023 The MathWorks, Inc.

    methods( Access = 'protected' )
        function defineViewProperties( obj ) 
             defineViewProperties@matlab.ui.internal.controller.uicontrol.UIControlController(obj);
            
             % Determines MultiSelect
             obj.PropertyManagementService.defineViewProperty('Max');
             obj.PropertyManagementService.defineViewProperty('Min');

             % Maps to SelectedIndex
             obj.PropertyManagementService.defineViewProperty('Value');
             
             % Maps to Items
             obj.PropertyManagementService.defineViewProperty('String');

             obj.PropertyManagementService.defineViewProperty('ListboxTop');
             
        end

        function definePropertyDependencies( obj ) 
             definePropertyDependencies@matlab.ui.internal.controller.uicontrol.UIControlController(obj);
             obj.PropertyManagementService.definePropertyDependency("Max", "Multiselect");
             obj.PropertyManagementService.definePropertyDependency("Min", "Multiselect");

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
                    obj.triggerActionEvent();
                case 'processKeyEvent'
                    % Always process the event for uicontrol
                    if strcmp(event.Data.data.type, 'keyup') &&( strcmp(event.Data.data.key,'return'))
                        obj.triggerActionEvent();
                    end
                case 'Clicked'
                    %% Clicked event drives the callback if no item is selected
                    isSelected = isfield(event.Data,'isSelected') && event.Data.isSelected;

                    % If the listbox is entirely empty, dont fire the
                    % callback
                    isEmpty = isempty(matlab.ui.internal.controller.uicontrol.UIControlConversionRules.convertStringToItems(obj.Model.String));
                    if(~strcmp(obj.Model.Enable,'inactive') && (isSelected || event.Data.item ==0)) && ~isEmpty 
                        obj.triggerActionEvent();
                    end
                case 'ListboxTopChanged'
                    newValue = event.Data.ListboxTop;
                    obj.Model.updateListboxTopFromView(newValue);
            end
        end
    end

    methods


        function val = fallbackDefaultBackgroundColor ( ~ )
            val = [1,1,1];
        end

        function className = getViewModelType(~, ~)
            className = 'matlab.ui.control.UIControlListBox';
        end

        function val = updateMultiselect(obj)
            import matlab.ui.internal.controller.uicontrol.UIControlConversionRules.convertMinMaxToMultiSelect;
            val = convertMinMaxToMultiSelect(obj.Model.Min, obj.Model.Max);
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
