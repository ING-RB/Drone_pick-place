classdef ToggleToolPropertyView < inspector.internal.AppDesignerNoPositionPropertyView
    % This class provides the property definition and groupings for
    % Toggle Tool

    % Copyright 2022 The MathWorks, Inc.

    properties(SetObservable = true)
        Icon internal.matlab.editorconverters.datatype.FileName
        State matlab.lang.OnOffSwitchState
        Separator matlab.lang.OnOffSwitchState

        Visible matlab.lang.OnOffSwitchState
        Enable matlab.lang.OnOffSwitchState
        Tooltip matlab.internal.datatype.matlab.graphics.datatype.NumericOrString

        Tag char {matlab.internal.validation.mustBeVector(Tag)}
    end

    methods
        function obj = ToggleToolPropertyView(componentObject)
            obj = obj@inspector.internal.AppDesignerNoPositionPropertyView(componentObject);

            % Sepecial Toggle Tool Group at the top of the inspector has
            % 'State' and 'Separator' properties
            inspector.internal.CommonPropertyView.createPropertyInspectorGroup(obj, ...
                'MATLAB:ui:propertygroups:ToggleToolGroup',...
                'State', 'Icon', 'Separator');

            % Common properties across all components
            inspector.internal.CommonPropertyView.createCommonPropertyInspectorGroup(obj);

        end
    end
end