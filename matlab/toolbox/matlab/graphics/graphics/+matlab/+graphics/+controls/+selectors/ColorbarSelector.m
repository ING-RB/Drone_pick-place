classdef ColorbarSelector < matlab.graphics.controls.selectors.BaseSelector
    % COLORBARSELECTOR Class that handles selection for Colorbar Objects
    
    % Copyright 2021-2024 The MathWorks, Inc.    
    properties(Access=protected)
        % Colorbar cache for the Target object  
        Colorbar;        
    end

    methods
        function obj = ColorbarSelector(ax)
            obj@matlab.graphics.controls.selectors.BaseSelector(ax);

            obj.FeatureName = 'Colorbar';

            service = matlab.plottools.service.MetadataService.getInstance();
            adapter = service.getMetaDataAccessor(ax);
            lastValue = adapter.get(obj.FeatureName); 
            
            obj.Flag = [];

            if ~isempty(lastValue) && strcmpi(string(lastValue), 'off') 
                obj.Control.String = obj.getMessageString("DefaultString_Selector_Colorbar");
                obj.Flag = 'on';
            elseif ~isempty(lastValue) && strcmpi(string(lastValue), 'on') 
                obj.Control.String = obj.getMessageString("DefaultString_Selector_RemoveColorbar");
                obj.Flag = 'off';
            end
        end
    end

    methods(Access=public)
        function enable(obj)
            if ~isempty(obj.Flag)
                obj.enable@matlab.graphics.controls.selectors.BaseSelector();
            end
        end

        function delete(obj)
            obj.Colorbar = [];
            obj.delete@matlab.graphics.controls.selectors.BaseSelector();
        end

    end

    methods(Access=protected)
        function id = getCodegenActionId(~)
            id = matlab.internal.editor.figure.ActionID.COLORBAR_ADDED;
        end        

        function info = getUndoInfo(obj)
            % Create the struct to add this info to the undo/redo stack
            % We need to use the MetaDataService to add to the stack as we
            % use it to update the state of the colorbar
            service = matlab.plottools.service.MetadataService.getInstance();
            adapter = service.getMetaDataAccessor(obj.Target);
            
            currentValue = adapter.get('Colorbar');
            
            if strcmpi(currentValue, 'on')
                oldValue = 'off';
            else
                oldValue = 'on';
            end
            
            info.Name = 'colorbar';
            info.Object = obj.Target;
            info.Fcn = @(~,~) adapter.set('Colorbar', currentValue);
            info.InvFcn = @(~,~) adapter.set('Colorbar', oldValue);    
        end

        function setPosition(obj)
            % Get pixel position for object
            if isa(obj.Target, "matlab.graphics.chart.Chart")
                pos = getpixelposition(obj.Target);
            else
                li = obj.Target.GetLayoutInformation();
                pos = li.PlotBox;
            end

            % TODO: Set the Colorbar selector in the colorbar location
            controlHeight = 20;
            controlWidth = 120;

            obj.Control.Position = [pos(1) + pos(3)/2 - controlWidth/2,...
                pos(2) + pos(4)/2 + 2,...
                controlWidth,...
                controlHeight,...
                ];
        end

        function clickedCallback(obj, ~)
            % Turn off the Control first otherwise it looks like it didn't
            % work
            obj.Control.Visible = 'off';

            service = matlab.plottools.service.MetadataService.getInstance();
            adapter = service.getMetaDataAccessor(obj.Target);
            adapter.set('Colorbar', obj.Flag)

            obj.registerUndo();            
            
            obj.generateCode();
            
            delete(obj);
        end
    end
end


