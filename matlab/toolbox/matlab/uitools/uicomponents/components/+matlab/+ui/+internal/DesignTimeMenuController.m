classdef DesignTimeMenuController< ...
        matlab.ui.internal.controller.WebMenuController & ...
        matlab.ui.internal.DesignTimeGbtParentingController& ...
        appdesservices.internal.interfaces.controller.ServerSidePropertyHandlingController
    % DesignTimeMenuController controller class which encapsulates
    % the design-time specific behaviour and establishes the
    % gateway between the Model and the View
    
    % Copyright 2016-2024 The MathWorks, Inc.
    
    methods
        
        function obj = DesignTimeMenuController( model, parentController, proxyView, adapter)
            %CONSTRUCTOR
            
            %Input verification
            narginchk( 4, 4 );
            
            % Construct the run-time controller first
            obj = obj@matlab.ui.internal.controller.WebMenuController( model, parentController, proxyView );

            % Now, construct the client-driven controller
             obj = obj@matlab.ui.internal.DesignTimeGbtParentingController(model, parentController, proxyView, adapter);          
        end
    end
    
  
    
    methods        
         function viewPvPairs = getPositionPropertiesForView(~, ~)
            % Override to suppress the default implementation in
            % DesignTimeGBTControllerPositionMixin
            % because menu does not have/need any Position-type properties

            viewPvPairs = {};
         end
        
         
         function additionalProperties = getAdditonalPositionPropertyNamesForView(objModel)            
            % Override to suppress the default implementation in
            % DesignTimeGBTControllerPositionMixin
            % because menu does not require 
            % AspectRatioLimits and IsSizeFixed
            
            additionalProperties = {'MenuSelectedFcn'};            
         end     

         function isOptimizedLoad = isOptimizedForAppLoad(~)
            isOptimizedLoad = false;
        end
    end
    
     methods (Access = protected)
        function excludedPropertyNames = getExcludedPropertyNamesForView(obj)
            % Do not send LabelMode to view as App Designer Client customizes the
            % Menu label on drag & drop.
            excludedPropertyNames = {'LabelMode'};

            excludedPropertyNames = [excludedPropertyNames; ...
                obj.getExcludedPositionPropertyNamesForView(); ...
                ];

            excludedPropertyNames = [excludedPropertyNames; ...
                getExcludedPropertyNamesForView@matlab.ui.internal.DesignTimeGBTControllerViewPropertiesMixin(obj); ...
                ];
        end
        
        function handleDesignTimeEvent(obj, src, event)
            % implement abstract method from DesignTimeController to
            % validate if user enters invalid characters from inspector
            
            if(strcmp(event.Data.Name, 'PropertyEditorEdited'))
                propertyName = event.Data.PropertyName;
                propertyValue = event.Data.PropertyValue;               
               
                if(any(strcmp(propertyName, {'Accelerator'})))
                    
                    % the next 3 lines are essentially the same as in
                    % ComponentController's setModelProperty
                    % because this is a GBT-style controller that does not 
                    % mix in ComponentController
                    commandId = event.Data.CommandId;
                    model = obj.Model;                    
                    setServerSideProperty(obj, model, propertyName, propertyValue, commandId)                    
                    if(strcmp(model.Accelerator, propertyValue))
                        % model property would have updated only if setServerSideProperty
                        % succeeded. If so, push this value to the peer-node                        
                        obj.EventHandlingService.setProperty( 'Accelerator', propertyValue);
                    end                                 
                end
            end
        end
        
     end

end
