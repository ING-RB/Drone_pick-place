classdef LaunchableData < matlab.mixin.Heterogeneous
    % This class defines the common properties and constructor for launchable
    % data items within Hardware Manager context.

    % Copyright 2024 The MathWorks, Inc.

    properties(GetAccess = public, SetAccess = public)

        % Feature Unique ID
        Identifier (1,1) string {mustBeNonempty}

        % The Category the feature belongs to. E.g., Applet, LiveTask
        Category 

        % Customer visible name
        DisplayName (1,1) string

        % Feature description
        Description (1,1) string

        % Feature Icon ID
        IconID (1,1) string

        % Feature's documentation link
        LearnMoreLink

        % Customer facing action text. E.g., "Launch Example", "Setup Hardware"
        ActionText (1,1) string

    end

    properties

        % Feature description heading
        DescriptionHeading (1,1) string

        % The product that the feature is associated with. E.g., MATLAB, Simulink
        BaseProductConstraints (1,:) string

        % List of specific platfroms the feature can be launched on
        PlatformConstraints (1,:) string

        % A list of base codes for toolboxes the feature depends on
        ToolboxBaseCodes (1, :) string

        % A list of base codes for hardware support packages the feature depends on
        SupportPackageBaseCodes (1, :) string

    end

    methods (Access = protected)
        function obj = LaunchableData(identifier, category, displayName, description, iconID, learnMoreLink, actionText, nameValueArgs)
            arguments
                identifier (1, 1) string
                category matlab.hwmgr.internal.data.FeatureCategory
                displayName (1, 1) string
                description (1, 1) string
                iconID (1, 1) string
                learnMoreLink
                actionText (1, 1) string
                nameValueArgs.DescriptionHeading (1, 1) string = ""
                nameValueArgs.BaseProductConstraints (1, :) string = string.empty()
                nameValueArgs.PlatformConstraints (1, :) string = string.empty()
                nameValueArgs.ToolboxBaseCodes (1, :) string = string.empty()
                nameValueArgs.SupportPackageBaseCodes (1, :) string = string.empty()
            end

            validateattributes(category, "matlab.hwmgr.internal.data.FeatureCategory", "scalar");

            % Empty learnMoreLink is allowed as it could be irrelevant for some launchables
            if (~isempty(learnMoreLink) && ~isa(learnMoreLink,'matlab.hwmgr.internal.data.LinkData') &&  ~isa(learnMoreLink,'matlab.hwmgr.internal.data.DocLinkData'))
                     error('MATLAB:invalidType', 'Expected input to be one of these types:↵↵matlab.hwmgr.internal.data.LinkData, matlab.hwmgr.internal.data.DocLinkData↵↵');
            end


            % Set properties
            obj.Identifier = identifier;
            obj.Category = category;
            obj.DisplayName = displayName;
            obj.Description = description;
            obj.IconID = iconID;
            obj.LearnMoreLink = learnMoreLink;
            obj.ActionText = actionText;  

            % Set properties from parsed name-value pairs
            obj.PlatformConstraints = nameValueArgs.PlatformConstraints;
            obj.BaseProductConstraints = nameValueArgs.BaseProductConstraints;
            obj.DescriptionHeading = nameValueArgs.DescriptionHeading;
            obj.ToolboxBaseCodes = upper(nameValueArgs.ToolboxBaseCodes);
            obj.SupportPackageBaseCodes = upper(nameValueArgs.SupportPackageBaseCodes);

        end
    end
end