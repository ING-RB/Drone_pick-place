% WEBCONTROLLER Web-based controller base class.
classdef LayoutBehaviorAddOn < matlab.ui.internal.componentframework.services.optional.BehaviorAddOn
    %

    %   Copyright 2018-2022 The MathWorks, Inc.

    methods ( Access=protected )

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:      defineViewProperties
        %
        %  Description: Within the context of MVC ( Model-View-Controller )
        %               software paradigm, this is the method the "Controller"
        %               layer uses to define which properties will be consumed by
        %               the web-based user interface.
        %  Inputs:      None
        %  Outputs:     None
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function defineViewProperties( ~, propManagementService )
            % The constructor of this class calls this method on the derived
            % class. This function needs to exist for correct binding.
            propManagementService.defineViewProperty("Layout");
        end
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         %
         %  Method:      definePropertyDependencies                     
         %  Description: Within the context of MVC ( Model-View-Controller )   
         %               software paradigm, this is the method the "Controller"
         %               layer uses to establish property dependencies between 
         %               a property (or set of properties) defined by the "Model"
         %               layer and dependent "View" layer property.
         %  Inputs:      None 
         %  Outputs:     None 
         %
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         function definePropertyDependencies( ~, propManagementService )
            % The constructor of this class calls this method on the derived
            % class. This function needs to exist for correct binding.
            propManagementService.definePropertyDependency("Layout", "LayoutConstraints");

        end
    end

    methods

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:  Constructor
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function this = LayoutBehaviorAddOn( propManagementService )
            % Super constructor
            this = this@matlab.ui.internal.componentframework.services.optional.BehaviorAddOn( propManagementService );
        end


        function newConstraintsValue = updateLayout(~, layoutOptions)
            newConstraintsValue = matlab.ui.control.internal.controller.mixin.LayoutableController.convertContraintsToStruct(layoutOptions);

        end
    end
end
