classdef (Hidden) ListBoxController < ...
        matlab.ui.control.internal.controller.StateComponentController &...
        matlab.ui.control.internal.controller.mixin.StyleableComponentController & ...
        matlab.ui.control.internal.controller.mixin.ClickableComponentController  &...
        matlab.ui.control.internal.controller.mixin.DoubleClickableComponentController
    
    % ListBoxController - This is the controller for the object:
    % matlab.ui.control.ListBox.

    % Copyright 2014-2023 The MathWorks, Inc.
    
    methods
        function obj = ListBoxController(varargin)
            obj@matlab.ui.control.internal.controller.StateComponentController(varargin{:});
        end
        
         function populateView(obj, proxyView)
             populateView@matlab.ui.control.internal.controller.StateComponentController(obj, proxyView);

             % Execute scroll() when view is guarenteed to be created.
             % This supports workflows invoking scroll() method during
             % controller construction.
             if ~isempty(obj.Model.InitialIndexToScroll)
                 obj.scroll(obj.Model.InitialIndexToScroll);
                 
                 % Reset index to default
                 obj.Model.InitialIndexToScroll = [];
             end
         end
    end
    
    methods
        
        function scroll(obj, index)
            % SCROLL - Send message to view to scroll listbox.  This does
            % not affect the selected component.
            
            
            func = @() obj.ClientEventSender.sendEventToClient(...
                'scroll',...
                { ...
                'Index', index;
                } ...
                );
            matlab.ui.internal.dialog.DialogHelper.dispatchWhenPeerNodeViewIsReady(obj.Model, obj.ViewModel, func);
        end
    end
    
    methods(Access = 'protected')
        
        function handleEvent(obj, src, event)
            
            % Handle changes in the property editor that needs a
            % server side validation
            if(strcmp(event.Data.Name, 'PropertyEditorEdited'))
                
                propertyName = event.Data.PropertyName;
                propertyValue = event.Data.PropertyValue;
                
                if(strcmp(propertyName, 'Value'))
                    if(isempty(propertyValue))
                        % convert empty values to {} to indicate no
                        % selection
                        propertyValue = {};
                    end
                    if(strcmp(obj.Model.Multiselect, 'off') && ...
                            iscell(propertyValue) && ...
                            length(propertyValue) == 1)
                        % Convert something like {'One'} to 'One'
                        %
                        % The value from the view comes as an array
                        % regardless of multi selection state
                        propertyValue = propertyValue{1};
                    end
                    
                    setModelProperty(obj, propertyName, propertyValue, event);
                    return;                
                end
           elseif(strcmp(event.Data.Name,'LinkClicked'))
                if (isfield(event.Data,'url'))
                    obj.handleLinkClicked(event.Data.url);
                end
            end
            
            % Allow super classes to handle their events
            handleEvent@matlab.ui.control.internal.controller.StateComponentController(obj, src, event);
            handleEvent@matlab.ui.control.internal.controller.mixin.ClickableComponentController(obj, src, event);
            handleEvent@matlab.ui.control.internal.controller.mixin.DoubleClickableComponentController(obj, src, event);
            
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
    
    end
    methods(Access = protected)
        function infoObject = getComponentInteractionInformation(obj, event, info)
            % GETCLICKEDINTERACTIONINFORMATION - Struct with
            % component specific information to be used in Clicked and
            % DoubleClicked events
            info.Item = [];

            % When Item is 0 that represents clicking on the listbox in a region
            % with no item.
            if event.Data.item > 0
                info.Item = event.Data.item;
            end
            infoObject = matlab.ui.eventdata.ListBoxInteraction(info);
        end
    end    
    methods(Static=true, Hidden=true)
        function formattedSerializableStyle = formatStyleConfigurationStorage(value)
            import matlab.ui.control.internal.controller.mixin.StyleableComponentController; 
            formattedSerializableStyle = StyleableComponentController.getSerializableStyleConfigurationStorage(value);
        end
    end
end

