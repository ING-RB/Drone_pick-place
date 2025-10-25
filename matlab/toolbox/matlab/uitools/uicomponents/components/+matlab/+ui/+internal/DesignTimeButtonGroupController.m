classdef DesignTimeButtonGroupController < ...
        matlab.ui.internal.WebButtonGroupController & ...
        matlab.ui.internal.DesignTimeGbtParentingController & ...
        appdesservices.internal.interfaces.controller.ServerSidePropertyHandlingController
    % DESIGNTIMEBUTTONGROUPCONTROLLER is Buttongroup Controller class which
    % encapsulates the design-time specific data, behaviour  and establishes
    % the gateway between Model and the View
    
    %  Copyright 2015-2022 The MathWorks, Inc.
    
    methods
        
        function obj = DesignTimeButtonGroupController( model, parentController, proxyView, adapter)
            %CONSTRUCTURE
            
            %Input arguments verification
            narginchk(4, 4);
            
            %Construct the run-time controller
            obj = obj@matlab.ui.internal.WebButtonGroupController( model, parentController, proxyView);
            
            % Construct the other appdesigner base class controller
            obj = obj@matlab.ui.internal.DesignTimeGbtParentingController(model, parentController, proxyView, adapter);
        end

        function adjustedProps = adjustParsedCodegenPropertiesForAppLoad(obj, parsedProperties)
            % Provides an opportunity for controllers to modify what was
            % considered dirty, parsed from generated code.

            adjustedProps = adjustParsedCodegenPropertiesForAppLoad@appdesigner.internal.controller.DesignTimeController(obj, parsedProperties);

            % always consider uipanel.Title, the default is different between
            % designtime and runtime defaults.
            adjustedProps = [adjustedProps, {'Title'}];
        end

        function newPos = updatePosition(obj)
            newPos = updatePosition@matlab.ui.internal.WebButtonGroupController(obj);

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
    
    methods (Access = protected)
        function handleDesignTimePropertyChanged(obj, peerNode, data)
            
            % handleDesignTimePropertyChanged( obj, peerNode, data )
            % Controller method which handles property updates in design time. For
            % property updates that are common between run time and design time,
            % this method delegates to the corresponding run time controller.
            
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
                    
                    obj.EventHandlingService.setProperty( 'BorderVisibility', strcmp(obj.Model.BorderType, 'line'))
                    
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
        
        function additionalPropertyNamesForView = getAdditionalPropertyNamesForView(obj)
            % Hook for subclasses to provide a list of property names that
            % needs to be sent to the view for loading in addition to the
            % ones pushed to the view defined by PropertyManagementService
            %
            % Example:
            % 1) Callback function properties
            % 2) FontUnits required by client side
            
            additionalPropertyNamesForView = {'BorderType'; 'SelectionChangedFcn'; 'FontUnits'; 'ButtonDownFcn'; 'SizeChangedFcn'};
            
            additionalPropertyNamesForView = [additionalPropertyNamesForView; ...
                getAdditionalPropertyNamesForView@matlab.ui.internal.DesignTimeGBTComponentController(obj);
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
    methods(Access = {...
            ?appdesservices.internal.interfaces.controller.AbstractController, ...
            ?appdesservices.internal.interfaces.controller.AbstractControllerMixin})
        function handleChildCodeGenerated(obj, changedChild)
            handleChildCodeGenerated@matlab.ui.internal.DesignTimeGbtParentingController(obj, changedChild)

            % When a button group's child changes, then re-generate code
            % for all button group children

            for idx = 1:length(obj.Model.Children)
                child = obj.Model.Children(idx);

                if(isa(child, 'matlab.ui.control.internal.model.AbstractMutualExclusiveComponent'))
                    child.getControllerHandle().updateGeneratedCode();
                end
            end
        end
    end
end

