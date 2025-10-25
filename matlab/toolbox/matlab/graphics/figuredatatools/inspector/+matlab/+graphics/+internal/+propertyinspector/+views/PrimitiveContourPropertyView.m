classdef PrimitiveContourPropertyView < matlab.graphics.internal.propertyinspector.views.CommonPropertyViews & matlab.graphics.internal.propertyinspector.views.IconDataMixin
    % This class has the metadata information on the matlab.graphics.chart.primitive.Contour property
    % groupings as reflected in the property inspector
    
    % Copyright 2017-2023 The MathWorks, Inc.
    
    properties
        Annotation
        BeingDeleted
        BusyAction
        ButtonDownFcn
        Children
        Clipping
        ContourMatrix
        CreateFcn
        DeleteFcn
        DisplayName
        EdgeAlpha
        EdgeColor
        FaceAlpha
        FaceColor
        HandleVisibility
        HitTest
        Interruptible
        LabelColor
        LabelSpacing
        LabelFormat
        LevelList
        LevelListMode
        LevelStep
        LevelStepMode
        LineStyle
        LineWidth
        Parent
        PickableParts
        Selected
        SelectionHighlight
        ShowText
        Tag
        TextList
        TextListMode
        TextStep
        TextStepMode
        Type
        ContextMenu
        UserData
        Visible
        XData
        XDataMode
        XDataSource
        YData
        YDataMode
        YDataSource
        ZData
        ZDataSource
        ZLocation
        DataTipTemplate
    end

    methods(Static)
        function iconProps = getIconProperties(hContour)
            iconProps.shape = string(matlab.graphics.internal.propertyinspector.views.Shapes.contour); 
            iconProps.faceColor = 'none';
            iconProps.edgeColor = hContour.EdgeColor;
            iconProps.labelColor = hContour.LabelColor;
            colorStyles = {'auto','flat'};
            % checking to see if the colors are one of the words listed
            % above and if so, using the colormap to decide to color of the
            % icon
            if ismember(1,strcmpi(hContour.EdgeColor,colorStyles))
                ax = ancestor(hContour,'matlab.graphics.axis.AbstractAxes');                
                if strcmpi(ax.ColormapMode,'manual')
                    c = ax.Colormap;
                else
                    f = ancestor(hContour,'figure');
                    c = f.Colormap;
                end
                iconProps.edgeColor = c(round(length(c))/2,:);
            end
            if ismember(1,strcmpi(hContour.LabelColor,colorStyles))
                ax = ancestor(hContour,'matlab.graphics.axis.AbstractAxes');                
                if strcmpi(ax.ColormapMode,'manual')
                    c = ax.Colormap;
                else
                    f = ancestor(hContour,'figure');
                    c = f.Colormap;
                end
                iconProps.labelColor = c(round(length(c))/2,:);
            end
        end
    end
    
    methods
        function this = PrimitiveContourPropertyView(obj)
            this@matlab.graphics.internal.propertyinspector.views.CommonPropertyViews(obj);
            
            %...............................................................
            
            g1 = this.createGroup(getString(message('MATLAB:propertyinspector:Levels')),'','');
            g1.addProperties('LevelList','LevelStep');
            g1.addSubGroup('LevelListMode','LevelStepMode','ZLocation');
            g1.Expanded = true;
            
            %...............................................................
            
            g2 = this.createGroup(getString(message('MATLAB:propertyinspector:ColorandStyling')),'','');
            g2.addProperties('FaceColor','EdgeColor');
            g2.addSubGroup('FaceAlpha','EdgeAlpha','LineStyle','LineWidth');
            g2.Expanded = true;
            
            %...............................................................
            
            g21 = this.createGroup(getString(message('MATLAB:propertyinspector:Labels')),'','');
            g21.addProperties('ShowText',...
                'LabelFormat',...
                'LabelSpacing',...
                'LabelColor',...
                'TextStep',...
                'TextStepMode',...
                'TextList',...
                'TextListMode');
            
            %...............................................................
            
            g3 = this.createGroup(getString(message('MATLAB:propertyinspector:Data')),'','');
            g3.addProperties('ContourMatrix',...
                'XData',...
                'XDataMode',...
                'XDataSource',...
                'YData',...
                'YDataMode',...
                'YDataSource',...
                'ZData',...
                'ZDataSource');
            
            %...............................................................
            this.createLegendGroup();
            
            %...............................................................
            this.createCommonInspectorGroup();
        end
    end
end
