classdef LegendSelector < matlab.graphics.controls.selectors.BaseSelector
    %LEGENDSELECTOR Class that handles selection for Legend Objects
    
    % Copyright 2021-2024 The MathWorks, Inc.   
  
    methods
        function obj = LegendSelector(ax)
            obj@matlab.graphics.controls.selectors.BaseSelector(ax);   
            
            obj.FeatureName = 'Legend';

            service = matlab.plottools.service.MetadataService.getInstance();
            adapter = service.getMetaDataAccessor(ax);
            lastValue = adapter.get(obj.FeatureName); % Legend
            obj.Flag=[];
            if  ~isempty(lastValue) && strcmpi(string(lastValue), 'off') 
                obj.Control.String = obj.getMessageString("DefaultString_Selector_Legend");
                obj.Flag = 'on';
            elseif ~isempty(lastValue) && strcmpi(string(lastValue), 'on') 
                obj.Control.String = obj.getMessageString("DefaultString_Selector_RemoveLegend");
                obj.Flag = 'off';
            end
        end
    end

    methods(Access=public)
        function enable(obj)
            if ~isempty( obj.Flag)
                obj.enable@matlab.graphics.controls.selectors.BaseSelector();
            end
        end
    end

    methods(Access=protected)  
        function id = getCodegenActionId(~)
            id = matlab.internal.editor.figure.ActionID.LEGEND_ADDED;
        end               
        
        function info = getUndoInfo(obj)
            % Create the struct to add this info to the undo/redo stack
            % We need to use the MetaDataService to add to the stack as we
            % use it to update the state of the legend
            service = matlab.plottools.service.MetadataService.getInstance();
            adapter = service.getMetaDataAccessor(obj.Target);
            
            currentValue = adapter.get('Legend');
            
            if strcmpi(currentValue, 'on')
                oldValue = 'off';
            else
                oldValue = 'on';
            end
            
            info.Name = 'legend';
            info.Object = obj.Target;
            info.Fcn = @(~,~) adapter.set('Legend', currentValue);
            info.InvFcn = @(~,~) adapter.set('Legend', oldValue);   
        end             
        
        function setPosition(obj)
           % Get pixel position for object

           fig = ancestor(obj.Target, 'figure');

           if isa(obj.Target, "matlab.graphics.chart.Chart")
               ref = ancestor(obj.Target, 'matlab.ui.internal.mixin.CanvasHostMixin');
               pos = hgconvertunits(fig, obj.Target.Position, obj.Target.Units, 'pixels', ref);

               if isa(obj.Target.Parent,'matlab.graphics.layout.TiledChartLayout')
                    pos = obj.Target.Parent.computeAbsolutePosition(obj.Target.Position, obj.Target.Units, 'pixels', true);
               end
           else
               li = obj.Target.GetLayoutInformation();
               pos = li.PlotBox;
           end

           controlHeight = 20;
           controlWidth = 120;
            
            obj.Control.Position = [pos(1) + pos(3) - controlWidth - 2,...
                pos(2) + pos(4) - controlHeight - 2,...
                controlWidth,...
                controlHeight,...
                ];              
        end         
        
        function clickedCallback(obj, ~)
            % Turn off the Control first otherwise it looks like it didn't
            % work
            obj.Control.Visible = 'off';
            % Set the legend for this axes

            service = matlab.plottools.service.MetadataService.getInstance();
            adapter = service.getMetaDataAccessor(obj.Target);
            adapter.set('Legend', obj.Flag)

            obj.registerUndo();
            
            obj.generateCode();
            
            delete(obj);
        end  
    end
end

