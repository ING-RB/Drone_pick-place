classdef UIControlPropertyManager < matlab.graphics.mixin.Mixin
    % UICONTROLPROPERTYMANAGER Defines common properties across all uicontrol
    % styles.

    %   Copyright 2023 The MathWorks, Inc.

    properties (Access = 'private')
        PropertyManagementService
    end

    methods
        function obj = UIControlPropertyManager(pms)
            obj.PropertyManagementService = pms;
            obj.defineUIControlViewProperties();
            obj.defineUIControlPropertyDependencies();
            obj.defineUIControlRequireUpdateProperties();
        end
    end

    methods( Access = 'protected' )
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function defineUIControlViewProperties(obj)
            obj.PropertyManagementService.defineViewProperty('Enable');
            obj.PropertyManagementService.defineViewProperty('BackgroundColor');

            % Font Properties
            obj.PropertyManagementService.defineViewProperty('FontAngle');
            obj.PropertyManagementService.defineViewProperty('FontName');
            obj.PropertyManagementService.defineViewProperty('FontSize');
            obj.PropertyManagementService.defineViewProperty('FontWeight');
            obj.PropertyManagementService.defineViewProperty('ForegroundColor');
            obj.PropertyManagementService.defineViewProperty("Position");
            obj.PropertyManagementService.defineViewProperty("Units");

            obj.PropertyManagementService.defineViewProperty("Visible");
            obj.PropertyManagementService.defineViewProperty("Tooltip");
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function defineUIControlPropertyDependencies( obj )
            obj.PropertyManagementService.definePropertyDependency("Enable", "UIControlEnable");
            obj.PropertyManagementService.definePropertyDependency("ForegroundColor", "FontColor");
            obj.PropertyManagementService.definePropertyDependency("FontUnits", "FontSize");

            obj.PropertyManagementService.definePropertyDependency("Units", "Position");
        end

        function defineUIControlRequireUpdateProperties( obj )
            obj.PropertyManagementService.defineRequireUpdateProperty("IsUIControl");
            obj.PropertyManagementService.defineRequireUpdateProperty("FontAngle");
            obj.PropertyManagementService.defineRequireUpdateProperty("FontSize");
            obj.PropertyManagementService.defineRequireUpdateProperty("FontName");
            obj.PropertyManagementService.defineRequireUpdateProperty("Position");
            obj.PropertyManagementService.defineRequireUpdateProperty("BackgroundColor");
        end
    end
end