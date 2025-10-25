classdef ZLabelSelector < matlab.graphics.controls.selectors.LabelSelector
    % ZLABELSELECTOR Class that handles selection for ZLabel text Objects

    % Copyright 2021-2024 The MathWorks, Inc.
    methods
        function obj = ZLabelSelector(ax)
            obj@matlab.graphics.controls.selectors.LabelSelector(ax);
        end
    end

    methods(Access=protected)

        function setInputState(obj)
            obj.FeatureName = 'ZLabel';

            obj.setInputState@matlab.graphics.controls.selectors.LabelSelector();
        end

        function id = getCodegenActionId(~)
            id = matlab.internal.editor.figure.ActionID.ZLABEL_ADDED;
        end

        function str = getDefaultString(obj)
            str = obj.getMessageString("DefaultString_Selector_ZLabel");
        end

        function setPosition(obj)
            % Get pixel position for object
            pos = getpixelposition(obj.Target);
            controlHeight = 20;

            % If textObj is empty it means the axes does not support
            % ZLabel
            textObj = obj.getSelectionObject();

            if ~isempty(textObj)
                if ~isempty(textObj.String) && all(~isnan(textObj.Extent))
                    controlWidth = length(textObj.String)*textObj.FontSize;
                else
                    controlWidth = 100;
                end

                posPix = matlab.graphics.chart.internal.convertDataSpaceCoordsToViewerCoords(textObj,textObj.Position');
                pos(1) = posPix(1) - controlWidth/2;
                pos(2) = posPix(2) ;

                obj.Control.Position = [pos(1),...
                    pos(2),...
                    controlWidth,...
                    controlHeight,...
                    ];
            end
        end
    end

end

