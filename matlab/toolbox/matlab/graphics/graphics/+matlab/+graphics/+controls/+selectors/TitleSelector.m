classdef TitleSelector < matlab.graphics.controls.selectors.LabelSelector
    % TITLESELECTOR Class that handles selection for Title text Objects
    
    % Copyright 2021-2024 The MathWorks, Inc.    
    properties(Access=protected)
        % Cache value for the visiblity of the AxesToolbar
        VisibleCache;
        
        % Cache value for the VisibleMode of the AxesToolbar
        VisibleModeCache;
    end
    
    methods
        function obj = TitleSelector(ax)
            obj@matlab.graphics.controls.selectors.LabelSelector(ax);          
        end
    end
        
    methods(Access=public)       
        function enable(obj)
           obj.enable@matlab.graphics.controls.selectors.LabelSelector();
           
           if ~isempty(obj.Target) && isvalid(obj.Target) &&...
                  isprop(obj.Target,'Toolbar') &&...
                  ~isempty(obj.Target.Toolbar) && isvalid(obj.Target.Toolbar)
               obj.VisibleCache = obj.Target.Toolbar.Visible;
               obj.VisibleModeCache = obj.Target.Toolbar.VisibleMode;

               % Disable to toolbar to prevent interference
               obj.Target.Toolbar.Visible = 'off';
           end
        end

        function delete(obj)
            % Restore the Toolbar Cached Values
            if ~isempty(obj.Target) && isvalid(obj.Target) &&...
                   isprop(obj.Target,'Toolbar') &&...
                   ~isempty(obj.Target.Toolbar) && isvalid(obj.Target.Toolbar) &&...
                   ~isempty(obj.VisibleCache) && ~isempty(obj.VisibleModeCache)
                obj.Target.Toolbar.Visible = obj.VisibleCache;
                obj.Target.Toolbar.VisibleMode = obj.VisibleModeCache;
            end

            obj.delete@matlab.graphics.controls.selectors.LabelSelector();
        end
        
    end
    
    methods(Access=protected)

        function setInputState(obj)
            obj.FeatureName = 'Title';

            obj.setInputState@matlab.graphics.controls.selectors.LabelSelector();            
        end 

        function id = getCodegenActionId(~)
            id = matlab.internal.editor.figure.ActionID.TITLE_ADDED;
        end        
        
        function str = getDefaultString(obj)
            str = obj.getMessageString("DefaultString_Selector_Title");
        end
                              
        function setPosition(obj)
            % Get pixel position for object
            textObj = obj.getSelectionObject();

            controlHeight = 20;

            if ~isempty(textObj) && ~isempty(textObj.String)
                controlWidth = length(textObj.String) * textObj.FontSize;
            else
                controlWidth = length(obj.Control.String) * obj.Control.FontSize;
            end

            pos = matlab.graphics.chart.internal.convertDataSpaceCoordsToViewerCoords(textObj,textObj.Position');

            if strcmpi(textObj.HorizontalAlignment, 'right')
                pos(1) = pos(1)- controlWidth;
            elseif strcmpi(textObj.HorizontalAlignment, 'center')
                pos(1) = pos(1)- controlWidth/2;
            end

            obj.Control.Position = [pos(1),...
                pos(2),...
                controlWidth,...
                controlHeight,...
                ];
        end
        
        function dismissedCallback(obj, evt, mouseData)                        
            % Restore the Toolbar Cached Values
           if ~isempty(obj.Target) && isvalid(obj.Target) &&...
                   isprop(obj.Target,'Toolbar') &&...
                   ~isempty(obj.Target.Toolbar) && isvalid(obj.Target.Toolbar)
               obj.Target.Toolbar.Visible = obj.VisibleCache;
               obj.Target.Toolbar.VisibleMode = obj.VisibleModeCache;
           end            
           
           obj.dismissedCallback@matlab.graphics.controls.selectors.LabelSelector(evt, mouseData);           
        end                  
    end
end