classdef BarChartSelector < handle
    %Bar chart selector
    %   Allows selection of bar chart elements and highlights them
    %   For example,
    %        b = bar(1:10)
    %        S = ctrluis.BarChartSelector(b, [1,3])

%   Copyright 2015-2023 The MathWorks, Inc.

    properties
        SelectorHitDetection (1,1) matlab.lang.OnOffSwitchState = true;
        AllowMultiSelect (1,1) matlab.lang.OnOffSwitchState = true;
    end
    
    properties (Dependent, AbortSet, SetObservable)
        % Selected values are the XData values for the bar elements to be
        % highlighted.
        SelectedValues
    end

    properties (Dependent, SetObservable)        
        % Face color for selected elements
        SelectedFaceColor
        
        % Edge color for selected elements
        SelectedEdgeColor

        % Face alpha for selected elements
        SelectedFaceAlpha
        
        % Edge alpha for selected elements
        SelectedEdgeAlpha

        % Display name for overlay chart
        DisplayName
    end
    
    properties (Access = private)
        % Selected Values
        SelectedValues_I

        % Face color for selected elements
        SelectedFaceColor_I = controllib.plot.internal.utils.GraphicsColor(8).SemanticName;
        
        % Edge color for selected elements
        SelectedEdgeColor_I = controllib.plot.internal.utils.GraphicsColor(1).SemanticName;
        
        % Overlay chart for highlighted values
        OverlayChart
    end

    properties (Access=private,WeakHandle)        
        % Original Bar Chart
        BarChart (1,1) matlab.graphics.chart.primitive.Bar
    end

    properties (Access=private,Transient)
        Listeners
    end
    
    methods
        function this = BarChartSelector(BarChart,SelectedValues)
            arguments
                BarChart (1,1) matlab.graphics.chart.primitive.Bar
                SelectedValues (:,1) double
            end
            % BarChart is handle to the bar chart to attach to
            % SelectedValues is a array of x values to be selected
            this.BarChart = BarChart;
            this.SelectedValues = SelectedValues;
            initialize(this)
            installListeners(this)
            updatePlot(this)
        end
        
        function Values = get.SelectedValues(this)
            Values = this.SelectedValues_I;
        end
        
        function set.SelectedValues(this,Values)
            arguments
                this (1,1) ctrluis.BarChartSelector
                Values (:,1) double
            end
            this.SelectedValues_I = sort(Values);
            updatePlot(this)
        end
        
        function set.SelectedFaceColor(this,Color)
            controllib.plot.internal.utils.setColorProperty(...
                this.OverlayChart,"FaceColor",Color);
            this.SelectedFaceColor_I = Color;
        end
        
        function Color = get.SelectedFaceColor(this)
            Color = this.SelectedFaceColor_I;
        end
        
        function set.SelectedEdgeColor(this,Color)
            controllib.plot.internal.utils.setColorProperty(...
                this.OverlayChart,"EdgeColor",Color);
            this.SelectedEdgeColor_I = Color;
        end
        
        function Color = get.SelectedEdgeColor(this)
            Color = this.SelectedEdgeColor_I;
        end
        
        function set.SelectedFaceAlpha(this,Alpha)
            this.OverlayChart.FaceAlpha = Alpha;
        end
        
        function Alpha = get.SelectedFaceAlpha(this)
            Alpha = this.OverlayChart.FaceAlpha;
        end

        function set.SelectedEdgeAlpha(this,Alpha)
            this.OverlayChart.EdgeAlpha = Alpha;
        end
        
        function Alpha = get.SelectedEdgeAlpha(this)
            Alpha = this.OverlayChart.EdgeAlpha;
        end

        function Name = get.DisplayName(this)
            Name = this.OverlayChart.DisplayName;           
        end

        function set.DisplayName(this,Name)
            this.OverlayChart.DisplayName = Name;           
        end
        
        function delete(this)
            delete(this.OverlayChart)
        end
        
        function updatePlot(this)
            Locs = NaN(size(this.BarChart.XData));
            idx = ismember(this.BarChart.XData,this.SelectedValues);
            Locs(idx) = 1;
            sz = min(length(this.BarChart.XData),length(this.BarChart.YData));
            Locs = Locs(1:sz);
            yData = this.BarChart.YData(1:sz);
            this.OverlayChart.XData = this.BarChart.XData;
            this.OverlayChart.YData = Locs.*yData;
            this.OverlayChart.Visible = 'on';
        end
    end 
    
    methods (Access = private)
        function initialize(this)
            % Construct Overlay
            this.OverlayChart = matlab.graphics.chart.primitive.Bar(...
                'XData',[],'YData',[],...
                'Parent', this.BarChart.Parent, 'Visible', 'on', ...
                'DisplayName','Selected Values');
            controllib.plot.internal.utils.setColorProperty(this.OverlayChart,"FaceColor",this.SelectedFaceColor_I);
            controllib.plot.internal.utils.setColorProperty(this.OverlayChart,"EdgeColor",this.SelectedEdgeColor_I);
            bh = hggetbehavior(this.OverlayChart,'DataCursor');
            bh.Enable = 0;
        end
        
        function installListeners(this)
            % Bar chart x data and y data
            weakThis = matlab.lang.WeakReference(this);
            L1 = addlistener(this.BarChart,'XData', 'PostSet', @(es,ed) updatePlot(weakThis.Handle));
            L2 = addlistener(this.BarChart,'YData', 'PostSet', @(es,ed) updatePlot(weakThis.Handle));
            
            % Bar chart button down
            L3 = addlistener(this.BarChart,'Hit', @(es,ed) cbHitBarChart(weakThis.Handle,ed));
            
            % Overlay button down
            L4 = addlistener(this.OverlayChart,'Hit', @(es,ed) cbHitOverlay(weakThis.Handle,ed));
            
            % Delete listener
            L5 = addlistener(this.BarChart,'ObjectBeingDestroyed', @(es,ed) delete(weakThis.Handle));

            this.Listeners = [L1;L2;L3;L4;L5];
        end
        
        function cbHitBarChart(this,ed)
            if this.SelectorHitDetection
                % Determine bar location
                [~,Idx] = min(abs(this.BarChart.XData-ed.IntersectionPoint(1)));
                XValue = this.BarChart.XData(Idx);
                % Update selected values based on shift-click, ctrl-click, or normal click
                if strcmpi(get(ancestor(this.BarChart,'Figure'),'SelectionType'),'alt') && this.AllowMultiSelect
                    this.SelectedValues = [this.SelectedValues(:);XValue];
                else
                    this.SelectedValues = XValue;
                end
            end
        end

        function cbHitOverlay(this,ed)
            if this.SelectorHitDetection
                % Determine bar location
                [~,Idx] = min(abs(this.BarChart.XData-ed.IntersectionPoint(1)));
                XValue = this.BarChart.XData(Idx);
                % Update selected values based on ctrl-click or normal click
                % and size of SelectedValues, there always must be one
                if strcmpi(get(ancestor(this.BarChart,'Figure'),'SelectionType'),'alt') && ~isscalar(this.SelectedValues) && this.AllowMultiSelect
                    this.SelectedValues(this.SelectedValues == XValue) = [];
                else
                    this.SelectedValues = XValue;
                end
            end
        end
        
    end
    
    
    %% QE Testing Methods
    methods (Hidden)
        function Chart = qeGetBarChart(this)
            % Get bar chart handle
            Chart = this.BarChart;
        end
        
        function Chart = qeGetOverlayChart(this)
            % Get overlay bar chart handle
            Chart = this.OverlayChart;
        end
        
    end
    
end


