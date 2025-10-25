% WEBCONTROLLER Abstract base class for all MATLAB Component Framework (MCF)
% controller classes. This class is the gateway to the core services of the MCF,
% such as the Property Management Service (PMS), the Identification Service (IS)
% and the Event Handling Service (EHS).
classdef (Abstract) WebController < handle

%   Copyright 2014-2023 The MathWorks, Inc.
    
    properties ( Access = 'public' )
        
        % View representation of the web component.
        ViewModel = appdesservices.internal.interfaces.view.EmptyViewModel.Instance;       
    end
    
    properties ( Access = {...
            ?matlab.ui.internal.componentframework.WebController, ...
            ?matlab.ui.internal.componentframework.services.optional.ControllerInterface,...
            ?matlab.ui.internal.controller.CanvasController, ...
            ?matlab.ui.control.internal.model.mixin.FocusableComponent})
        
        % Representation of the web component
        Model
        
        % Parent controller
        ParentController            
    end
    
    properties( Access = 'protected' )
        
        % Gateway to the Property Management Service (PMS)
        PropertyManagementService
        
        % Gateway to the Identification Service (IS)
        IdentificationService
        
        % Gateway to the Event Handling Service (EHS)
        EventHandlingService
        
    end
    
    methods ( Access = 'protected' )
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:      defineViewProperties
        %
        %  Inputs:      None.
        %  Outputs:     None.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function defineViewProperties( obj )
            % By leveraging MCF's Property Management Service (PMS), the controllers
            % can customize which of the model properties will be represented in the
            % view. This method provides the interface to achieve this capability.
            % This method needs to exist for correct binding.
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:      definePropertyDependencies
        %
        %  Inputs:      None.
        %  Outputs:     None.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function definePropertyDependencies( obj )
            % By leveraging MCF's Property Management Service (PMS), the controllers
            % can customize which of the model properties will have dependencies
            % that will impact the view. This method provides the interface to
            % achieve this capability.
            % This method needs to exist for correct binding.
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:      defineRequireUpdateProperties
        %  Description: Within the context of MVC ( Model-View-Controller )
        %               software paradigm, this is the method the "Controller"
        %               layer uses to establish property which needs updates
        %               before updating them to view.
        %  Inputs:      None
        %  Outputs:     None
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function defineRequireUpdateProperties( obj )
           
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:       is
        %
        %  Inputs:       onoff -> On/off flag which will be converted to logical.
        %  Outputs:      result -> Conversion result.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function result = is( ~, onoff )
            % Converts 'on'/'off' values to logical.
            % RESULT = this.IS(ONOFF) returns logical true if ONOFF is
            % 'on', false otherwise.
            result = strcmp( onoff, 'on' );
        end
        
    end
    
    methods ( Access = 'public' )
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:         Constructor
        %
        %  Postconditions: Controller bound to web-based specializations of all the
        %                  MCF services.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = WebController()
            % MCF uses this constructor to bind to the web-based specializations
            % of the services, such as the web-based PMS, IS and EHS.
            
            % Bind to the PMS.
            obj.PropertyManagementService = matlab.ui.internal.componentframework. ...
                services.core.propertymanagement.PropertyManagementService;
            obj.defineViewProperties();
            obj.definePropertyDependencies();
            obj.defineRequireUpdateProperties();
            
            % Bind to the web-based IS.
            obj.IdentificationService = matlab.ui.internal.componentframework. ...
                services.core.identification.WebIdentificationService;
            
            % Bind to the web-based EHS.
            obj.EventHandlingService = matlab.ui.internal.componentframework. ...
                services.core.eventhandling.WebEventHandlingService;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:       getId
        %
        %  Inputs:       None.
        %  Outpus:       None.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function id = getId( obj )
            % Method which retrieves the unique identifier for the web component
            % using the IS.
            id = obj.IdentificationService.perform( obj.ViewModel );
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:       delete
        %
        %  Inputs:       None.
        %  Outpus:       None.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function delete( obj )
            % Method which deletes the view representation from the hierarchy by
            % leveraging the EHS.
            if ~isempty(obj.EventHandlingService) && isvalid(obj.EventHandlingService)
                obj.EventHandlingService.clearView();
            end
        end
    end
end

