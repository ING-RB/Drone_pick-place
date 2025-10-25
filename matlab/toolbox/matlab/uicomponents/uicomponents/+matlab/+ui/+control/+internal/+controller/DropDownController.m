classdef (Hidden) DropDownController < ...
        matlab.ui.control.internal.controller.StateComponentController &...
        matlab.ui.control.internal.controller.mixin.StyleableComponentController & ...
        matlab.ui.control.internal.controller.mixin.ClickableComponentController

    % DropDownController: This is the controller for the object
    % matlab.ui.control.DropDown.


    % Copyright 2011-2023 The MathWorks, Inc.

    methods
        function obj = DropDownController(varargin)
            obj@matlab.ui.control.internal.controller.StateComponentController(varargin{:});
        end
    end

    methods(Access = 'protected')

        % Override the super's handleEvent
        function handleEvent(obj, src, event)
            % HANDLEEVENT(OBJ, ~, EVENT) this method is invoked each time
            % user changes the state of the component

            % Do not call the direct super because this class needs to
            % handle the event 'StateChanged' differently
            handleEvent@matlab.ui.control.internal.controller.ComponentController(obj, src, event);

            if(strcmp(event.Data.Name, 'StateChanged'))
                % The state of the component has changed
                % The structure of the event.Data is:
                %  - SelectedIndex: index (1-based) if selection, string if user edit
                %  - SelectedIndex: index (1-based) if selection, string if user edit


                % new selected index and corresponding value and valuedata
                selectedIndex = event.Data.SelectedIndex;
                newValue = obj.Model.getValueGivenIndex(selectedIndex);
                newIndex = obj.Model.getValueIndexGivenSelectedIndex(selectedIndex);
                % whether the new value is a string
                isNewValueEdited = matlab.ui.control.internal.model.PropertyHandling.isString(selectedIndex);

                % previously selected index and corresponding value and
                % valuedata
                previousIndex = obj.validateItemIndex(event.Data.PreviousSelectedIndex);
                previousValue = obj.Model.getValueGivenIndex(previousIndex);

                % Create event data with additional properties
                valueData = matlab.ui.eventdata.ValueChangedData(...
                    newValue, ...
                    previousValue, ...
                    'Edited', isNewValueEdited,...
                    'ValueIndex', newIndex, ...
                    'PreviousValueIndex', previousIndex);

                % Update the model and emit an event which in turn will
                % trigger the user callback
                if isNewValueEdited
                    newIndex = newValue;
                end
                obj.handleUserInteraction('StateChanged', event.Data, {'ValueChanged', valueData, 'PrivateSelectedIndex', newIndex});

            elseif(strcmp(event.Data.Name, 'DropDownOpening'))
                dropDownOpeningEventData = matlab.ui.eventdata.DropDownOpeningData();
                obj.handleUserInteraction('DropDownOpening', event.Data, {'DropDownOpening', dropDownOpeningEventData});
            elseif(strcmp(event.Data.Name,'LinkClicked'))
                if (isfield(event.Data,'url'))
                    obj.handleLinkClicked(event.Data.url);
                end
            end
           
            handleEvent@matlab.ui.control.internal.controller.mixin.ClickableComponentController(obj, src, event);
        end

        function propertyNames = getAdditionalPropertyNamesForView(obj)
            % Get additional properties to be sent to the view

            propertyNames = getAdditionalPropertyNamesForView@matlab.ui.control.internal.controller.StateComponentController(obj);

            % Non - public properties that need to be sent to the view
            propertyNames = [propertyNames; {...
                'StyleConfigurationStorage' ...
                }];
        end
        
        function viewPvPairs = getPropertiesForView(obj, propertyNames)
            % GETPROPERTIESFORVIEW(OBJ, PROPERTYNAME) returns view-specific
            % properties, given the PROPERTYNAMES
            %
            % Inputs:
            %
            %   propertyNames - list of properties that changed in the
            %                   component model.
            %
            % Outputs:
            %
            %   viewPvPairs   - list of {name, value, name, value} pairs
            %                   that should be given to the view.
            import appdesservices.internal.util.ismemberForStringArrays;
            viewPvPairs = {};

            % Properties from Super
            viewPvPairs = [viewPvPairs, ...
                getPropertiesForView@matlab.ui.control.internal.controller.StateComponentController(obj, propertyNames), ...
                ];
            checkFor = ["StyleConfigurationStorage"];
            isPresent = ismemberForStringArrays(checkFor, propertyNames);

            if isPresent(1)
                newValue = obj.formatStyleConfigurationStorage(obj.Model.StyleConfigurationStorage);
                viewPvPairs = [viewPvPairs, ...
                    {"StyleConfigurationStorage", newValue}, ...
                    ];
            end
        end

        function validIndex = validateItemIndex(~, itemIndex)
            % VALIDATEITEMINDEX Ensure the given index is in the valid range
            %
            % May return -1 to indicate an index out of range.
            %
            % Just returns the given index by default. Overridden by the
            % workspace dropdown controller.
            validIndex = itemIndex;
        end
    end

    methods(Access = protected)
        function infoObject = getComponentInteractionInformation(obj, event, info)
            % GETCLICKEDINTERACTIONINFORMATION - Struct with
            % component specific information to be used in Clicked events
            
            info.Item = event.Data.item;
            infoObject = matlab.ui.eventdata.DropDownInteraction(info);
        end
    end

     methods(Static=true, Hidden=true)
        function formattedSerializableStyle = formatStyleConfigurationStorage(value)
            import matlab.ui.control.internal.controller.mixin.StyleableComponentController; 
            formattedSerializableStyle = StyleableComponentController.getSerializableStyleConfigurationStorage(value);
        end
    end

end
