classdef WebToolbarController < matlab.ui.internal.componentframework.WebContainerController
    %WebToolbarController Web-based controller for
    % matlab.ui.container.Toolbar object.
    
    properties
    end
    
    methods
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Constructor
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = WebToolbarController(model, varargin )
            %WebToolbarController Construct an instance of this class
            obj = obj@matlab.ui.internal.componentframework.WebContainerController( model, varargin{:} );
        end     
        
    end
    
    methods (Access = 'protected')
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:      defineViewProperties
        %
        %  Description: Within the context of MVC ( Model-View-Controller )
        %               software paradigm, this is the method the "Controller"
        %               layer uses to define which properties will be consumed by
        %               the web-based buser interface.
        %  Inputs:      None
        %  Outputs:     None
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function defineViewProperties( obj )
            % Add view properties specific to the uitoolbar,
            obj.PropertyManagementService.defineViewProperty( 'Visible' );
            obj.PropertyManagementService.defineViewProperty( 'BackgroundColor' );
            obj.PropertyManagementService.defineViewProperty( 'ContextMenu' );
        end
    end    
end

