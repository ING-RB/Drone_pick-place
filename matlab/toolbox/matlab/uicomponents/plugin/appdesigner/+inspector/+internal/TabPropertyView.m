classdef TabPropertyView < inspector.internal.AppDesignerPropertyView
    % This class provides the property definition and groupings for Tab

    % Copyright 2015-2022 The MathWorks, Inc.

    properties(SetObservable = true)

        Title char {matlab.internal.validation.mustBeVector(Title)}
        Scrollable matlab.lang.OnOffSwitchState

        AutoResizeChildren matlab.lang.OnOffSwitchState

        ForegroundColor matlab.internal.datatype.matlab.graphics.datatype.RGBAColor
        BackgroundColor matlab.internal.datatype.matlab.graphics.datatype.RGBAColor

        Tooltip matlab.internal.datatype.matlab.graphics.datatype.NumericOrString

        Tag char {matlab.internal.validation.mustBeVector(Tag)}
    end


    methods
        function obj = TabPropertyView(componentObject)
            obj = obj@inspector.internal.AppDesignerPropertyView(componentObject);

            inspector.internal.CommonPropertyView.createPropertyInspectorGroup(obj, 'MATLAB:ui:propertygroups:TitleAndColorGroup',...
                'Title', ...
                'ForegroundColor', ...
                'BackgroundColor');

            % Common properties across all components
            groups = inspector.internal.CommonPropertyView.createCommonPropertyInspectorGroup(obj);

            % Remove font / color, as that is managed above uniquely for
            % Tab
            obj.GroupList(strcmp({obj.GroupList.Title}, 'MATLAB:ui:propertygroups:FontAndColorGroup')) = [];
            delete(groups.FontAndColorGroup);

            % Other properties of the Interactivity group do not apply to TAB
            groups.InteractivityGroup.PropertyList = {'Tooltip', 'Scrollable', 'ContextMenu'};

        end
    end
end
