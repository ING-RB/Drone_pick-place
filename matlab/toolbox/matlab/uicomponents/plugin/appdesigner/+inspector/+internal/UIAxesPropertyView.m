classdef UIAxesPropertyView < matlab.graphics.internal.propertyinspector.views.UIAxesPropertyView
    % This class provides the property definition and groupings for the new
    % UIAxes component, which inherits from matlab.graphics.axis.Axes

    % Copyright 2015-2021 The MathWorks, Inc.

    properties
        % These properties are ones that exist on UIAxes on top of what is
        % already defined for Axes

        % These properties are used to show "XLabel.String" and others in
        % the Labels section
        %
        % - The controllers are already sending properties to the client with
        % these property names
        %
        % Since these are not first class properties of the component, we need to do some
        % work to make sure they look like first class properties.
        %
        % In the client, before Inspecting an object, we will change the
        % display name from XLabelString to XLabel.String and also add on
        % tooltip help.
        TitleString matlab.internal.datatype.matlab.graphics.datatype.NumericOrString
        XLabelString matlab.internal.datatype.matlab.graphics.datatype.NumericOrString
        YLabelString matlab.internal.datatype.matlab.graphics.datatype.NumericOrString
        ZLabelString matlab.internal.datatype.matlab.graphics.datatype.NumericOrString
        SubtitleString matlab.internal.datatype.matlab.graphics.datatype.NumericOrString
        ToolbarVisible matlab.lang.OnOffSwitchState
        AD_AliasedVisible matlab.lang.OnOffSwitchState
        AD_ColormapString matlab.internal.datatype.matlab.graphics.datatype.ColorMap
    end

    methods
        function obj = UIAxesPropertyView(componentObject)
            % UIAXESPROPERTYVIEW - constructor for the property view
            % class.  This class subclasses Axes property view to get all groupings
            % defined for base MATLAB.  To accomodate App Designer, it
            % makes a few changes to the groups, either by removing the
            % groups entirely or removing specific properties from the
            % group.

            obj = obj@matlab.graphics.internal.propertyinspector.views.UIAxesPropertyView(componentObject);

            % Remove Units
            unitsIndex = cellfun(@(property) ischar(property) && strcmp(property, 'Units'), obj.PositionGroup.PropertyList);
            obj.PositionGroup.PropertyList(unitsIndex) = [];

            % Remove InnerPosition and PositionConstraint from the properties
            innerPositionIndex = cellfun(@(property) ischar(property) && strcmp(property, 'InnerPosition'), obj.PositionGroup.PropertyList);
            positionConstraintIndex = cellfun(@(property) ischar(property) && strcmp(property, 'PositionConstraint'), obj.PositionGroup.PropertyList);
            obj.PositionGroup.PropertyList(innerPositionIndex) = [];
            obj.PositionGroup.PropertyList(positionConstraintIndex) = [];

            % Remove FontSmoothing because it doesn't have an impact on the
            % new UIAxes:
            % (1) find the font group in the list of groups,
            % (2) find FontSmoothing within the font group, and
            % (3) remove the FontSmoothing property.
            isFontGroup = ismember({obj.getGroups.GroupID}, 'MATLAB:propertyinspector:Font');
            listOfAllPropertyGroups = obj.getGroups;
            fontGroup = listOfAllPropertyGroups(isFontGroup);

            fontSmoothingIndex = cellfun(@(property) ischar(property) && strcmp(property, 'FontSmoothing'), fontGroup.PropertyList{end}.PropertyList);
            fontGroup.PropertyList{end}.PropertyList(fontSmoothingIndex) = [];

            % Ensure that TitleHorizontalAlignment is not in the Font
            % Group.  We will place that property in the Labels Group.
            titleHorizontalAlignmentIndex = cellfun(@(property) ischar(property) && strcmp(property, 'TitleHorizontalAlignment'), fontGroup.PropertyList{end}.PropertyList);
            fontGroup.PropertyList{end}.PropertyList(titleHorizontalAlignmentIndex) = [];

            % Expose the AD_AliasedVisible, ContextMenu, and ToolbarVisible from the
            % interactivity group
            obj.InteractivityGroup.PropertyList = {'AD_AliasedVisible', 'ContextMenu', 'ToolbarVisible'};

            % Insert the AD_ColormapString property where the real Colormap
            % property is.
            colormapIndex = cellfun(@(property) ischar(property) && strcmp(property, 'Colormap'), obj.ColorAndStylingGroup.PropertyList);
            obj.ColorAndStylingGroup.PropertyList{colormapIndex} = 'AD_ColormapString';

            % "Reset" what Axes did for Labels
            obj.GroupList(obj.GroupList == obj.LabelsGroup) = [];
            delete(obj.LabelsGroup)

            % Re-create the Labels group
            obj.LabelsGroup = obj.createGroup( ...
                'MATLAB:propertyinspector:Labels', ...
                'MATLAB:propertyinspector:Labels', ...
                '');

            obj.LabelsGroup.addProperties('TitleString', 'XLabelString', 'YLabelString','ZLabelString', 'SubtitleString', 'TitleHorizontalAlignment');
            obj.LabelsGroup.Expanded = true;

            % Move Labels to front
            obj.GroupList(obj.GroupList == obj.LabelsGroup) = [];
            obj.GroupList = [obj.LabelsGroup, obj.GroupList];

            obj.GroupList(obj.GroupList == obj.CallbackGroup) = [];
            delete(obj.CallbackGroup)
        end
    end
end