classdef YLabelSelector < matlab.graphics.controls.selectors.LabelSelector
    % YLABELSELECTOR Class that handles selection for YLabel text Objects

    % Copyright 2024 The MathWorks, Inc.
    methods
        function obj = YLabelSelector(ax)
            obj@matlab.graphics.controls.selectors.LabelSelector(ax);
        end
    end

    methods(Access=protected)

        function setInputState(obj)
            obj.FeatureName = 'YLabel';

            obj.setInputState@matlab.graphics.controls.selectors.LabelSelector();
        end

        function id = getCodegenActionId(~)
            id = matlab.internal.editor.figure.ActionID.YLABEL_ADDED;
        end

        function str = getDefaultString(obj)
            str = obj.getMessageString("DefaultString_Selector_YLabel");
        end

        function setPosition(obj)
            % Get pixel position for object
            pos = getpixelposition(obj.Target);
            controlHeight = 20;
            textObj = obj.getSelectionObject();

            if ~isempty(textObj) && ~isempty(textObj.String) && all(~isnan(textObj.Extent))
                controlWidth = length(textObj.String) * textObj.FontSize;
            else
                controlWidth = 100;
            end
            posPix = matlab.graphics.chart.internal.convertDataSpaceCoordsToViewerCoords(textObj,textObj.Position');
            pos(1) = posPix(1) - controlWidth/2;
            pos(2) = posPix(2) ;
            % For 3D axes, adjust the Selector's position based on the lable text object's Alignment
            if ~isa(obj.Target, "matlab.graphics.chart.Chart") && ~is2D(obj.Target)
                if  strcmpi ( textObj.HorizontalAlignment, 'right')
                    pos(1) = posPix(1) - controlWidth;
                    pos(2) = posPix(2) - controlHeight;
                else
                    pos(1) = posPix(1);
                    pos(2) = posPix(2) - controlHeight;
                end
            end
            obj.Control.Position = [pos(1),...
                pos(2),...
                controlWidth,...
                controlHeight,...
                ];
             
        end
    end

end

