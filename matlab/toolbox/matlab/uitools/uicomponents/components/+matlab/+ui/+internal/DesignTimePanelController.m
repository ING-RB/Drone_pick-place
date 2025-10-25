classdef DesignTimePanelController < ...
        matlab.ui.internal.WebPanelController & ...
        matlab.ui.internal.DesignTimeGbtParentingController & ...
        appdesservices.internal.interfaces.controller.ServerSidePropertyHandlingController
    % DesignTimePanelController A panle controller class which encapsulates
    % the design-time specific dta and behaviour and establishes the
    % gateway between the Model and the View
    
    % Copyright 2015-2024 The MathWorks, Inc.
    
    methods
        
        function obj = DesignTimePanelController( model, parentController, proxyView, adapter)
            %CONSTRUCTURE
            
            %Input verification
            narginchk( 4, 4 );
            
            % Construct the run-time controller first
            obj = obj@matlab.ui.internal.WebPanelController(model, parentController, proxyView);
            
            % Now, construct the appdesigner base class controllers
            obj = obj@matlab.ui.internal.DesignTimeGbtParentingController(model, parentController, proxyView, adapter);
            
        end

        function adjustedProps = adjustParsedCodegenPropertiesForAppLoad(obj, parsedProperties)
            % Provides an opportunity for controllers to modify what was
            % considered dirty, parsed from generated code.
            % eg: DesignTimeUIAxes needs to convert aliases
            % eg: TreeNode needs to force 'NodeId'

            adjustedProps = adjustParsedCodegenPropertiesForAppLoad@appdesigner.internal.controller.DesignTimeController(obj, parsedProperties);

            % always consider uipanel.Title, the default is different between
            % designtime and runtime defaults.
            adjustedProps = [adjustedProps, {'Title'}];
        end

        function adjustedProps = adjustPositionalPropertiesForAppLoad(obj, properties)
            adjustedProps = adjustPositionalPropertiesForAppLoad@appdesigner.internal.controller.DesignTimeController(obj, properties);
            
            propNames = adjustedProps(1:2:end);
            
            for i = length(propNames): -1 : 1
                if strcmp(propNames{i}, 'InnerPosition')
                    adjustedProps(i*2-1:i*2) = [];
                end
            end
        end

        function newPos = updatePosition(obj)
            newPos = updatePosition@matlab.ui.internal.WebPanelController(obj);

            % For design-time, we should use Position value directly instead of 
            % an updated struct
            newPos = newPos.Value;
        end

        function newFontSize = updateFontSize( obj )
            newFontSize = updateFontSize@matlab.ui.internal.WebPanelController(obj);

            if isstruct(newFontSize)
                 % For design-time, we should use Position value directly instead of 
                % an updated struct
                newFontSize = newFontSize.FontSize;
            end
        end
    end
    
    methods (Access=protected)
        function handleDesignTimePropertyChanged(obj, peerNode, data)
            % handleDesignTimePropertyChanged( obj, peerNode, data )
            % Controller method which handles property updates in design time.
            
            % Handle property updates from the client
            
            updatedProperty = data.key;
            updatedValue = data.newValue;
            
            switch ( updatedProperty )
                
                case 'BorderVisibility'
                    if(updatedValue)
                        obj.Model.BorderType = 'line';
                    else
                        obj.Model.BorderType = 'none';
                    end
                    
                    obj.EventHandlingService.setProperty( 'BorderType', obj.Model.BorderType );
                    
                case 'BorderType'
                    obj.Model.BorderType = updatedValue;
                    
                    obj.EventHandlingService.setProperty( 'BorderVisibility', strcmp(obj.Model.BorderType, 'line'));
                    
                case 'Position'
                    % Position cannot be set when the component is in a
                    % gridlayout.
                    if ~isa(obj.Model.Parent,'matlab.ui.container.GridLayout')
                        handleDesignTimePropertyChanged@matlab.ui.internal.DesignTimeGBTComponentController(obj, peerNode, data);
                    end
                    
                otherwise
                    % call base class to handle it
                    handleDesignTimePropertyChanged@matlab.ui.internal.DesignTimeGBTComponentController(obj, peerNode, data);
            end
        end

        function handleDesignTimeEvent(obj, src, event)
            %HANDLEDESIGNTIMEEVENT - Handler for 'peerEvent' from the Peer Node.

            if(strcmp(event.Data.Name, 'PropertyEditorEdited'))
                % Handle changes in the property editor that needs a
                % server side validation

                propertyName = event.Data.PropertyName;
                propertyValue = event.Data.PropertyValue;

                switch propertyName
                    case 'BorderWidth'

                        % propertyValue arrives as a char
                        convertedPropertyValue = appdesservices.internal.util.convertClientNumberToServerNumber(propertyValue);

                        % Set the property on the server and then set it on the
                        % object handle.
                        setServerSideProperty(obj, ...
                            obj.Model, ...
                            propertyName, ...
                            convertedPropertyValue, ...
                            event.Data.CommandId...
                            );

                        obj.setProperty('BorderWidth');
                        obj.setProperty('BorderWidth_I');

                        % stop handling other events
                        return;
                end
            end

            % Defer to super
            handleDesignTimeEvent@matlab.ui.internal.DesignTimeGBTComponentController(obj, src, event);
        end

        function updateToPositionBehavior(obj, src, eventData)
            obj.positionBehavior.handleClientPositionEvent( src, eventData, obj.Model );
        end
        
        function additionalPropertyNamesForView = getAdditionalPropertyNamesForView(obj)
            % Hook for subclasses to provide a list of property names that
            % needs to be sent to the view for loading in addition to the
            % ones pushed to the view defined by PropertyManagementService
            %
            % Example:
            % 1) Callback function properties
            % 2) FontUnits required by client side
            
            additionalPropertyNamesForView = {'BorderType'; 'FontUnits'; 'ButtonDownFcn'; 'SizeChangedFcn'};
            
            additionalPropertyNamesForView = [additionalPropertyNamesForView; ...
                getAdditionalPropertyNamesForView@matlab.ui.internal.DesignTimeGBTComponentController(obj);...
                ];
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
            
            viewPvPairs = {};
            
            % Base class
            viewPvPairs = [viewPvPairs, ...
                getPropertiesForView@matlab.ui.internal.DesignTimeGbtParentingController(obj, propertyNames)];
            
            % Set the Border visibility
            value = obj.Model.BorderType;
            if(isequal(value, 'none'))
                value = false;
            else
                value = true;
            end
            viewPvPairs = [viewPvPairs, ...
                {'BorderVisibility', value}, ...
                ];
        end
    end
end