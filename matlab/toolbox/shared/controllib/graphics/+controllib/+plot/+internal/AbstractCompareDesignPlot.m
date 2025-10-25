classdef AbstractCompareDesignPlot < handle & matlab.mixin.Heterogeneous
    % Abstract class for Plots.
 
    % Copyright 2014-2023 The MathWorks, Inc.
    
    %%
    properties (Access = protected)
        PlotHandle % Plot Handle (Resppack)
        Designs % Data for design
        DesignStyles = cell(0,2);
        DesignStyleList = {...
                '--', 'g';
                '-.', 'c';
                ':' , 'r'};
        DesignSemanticColorList = controllib.plot.internal.utils.GraphicsColor(2:7).SemanticName
        DesignSemanticColorsUsed = string.empty
        PlotType = '';

        PlotVersion = 2
    end
    properties (Access = protected, Transient)
        PlotDeleteListener
    end
    
    %% Public Methods
    methods 
        function this = AbstractCompareDesignPlot()
        end
        
        function showLegend(this)
            % Turn legend on first plot
            if isPlotValid(this)
                ax = this.PlotHandle.AxesGrid.getaxes('2d');
                legend(ax(1,1),'show')
            end
        end
        
        function delete(this)
            delete(this.PlotDeleteListener);
            cleanup(this);
            
            if ishandle(this.PlotHandle)
                delete(getFigure(this))
            end
        end
        
        function show(this)
            % Show Plot
            if ishandle(this.PlotHandle)
                figure(getFigure(this))
            else
                createPlot(this)
            end
        end
        
        function hide(this)
            % Hide Plot
            if ishandle(this.PlotHandle)
                set(getFigure(this),'Visible','off')
            end
        end
        
        function Fig = getFigure(this)
            % Get Figure Handle
            if isempty(this.PlotHandle)
                Fig = [];
            elseif controllib.chart.internal.utils.isChart(this.PlotHandle)
                Fig = this.PlotHandle.Parent;
            else
                Fig = this.PlotHandle.AxesGrid.Parent;
            end
        end
        
        function PlotType = getType(this)
            % Get Plot Type
            PlotType = this.PlotType;
        end

        function addDesign(this,Design,styleOrColor)
            if controllib.chart.internal.utils.isChart(this.PlotHandle)
                % Add Design
                if nargin == 2
                    designColor = findNextAvailableDesignColor(this);
                else
                    designColor = styleOrColor;
                end
                addDesign_(this,Design,designColor)
                this.DesignSemanticColorsUsed = [this.DesignSemanticColorsUsed; designColor];
                this.Designs = [this.Designs;Design];
            else
                % Add Design
                if nargin == 2
                    NewStyle = findNextAvailableDesignStyle(this);
                    styleOrColor = NewStyle;
                end
                addDesign_(this,Design,styleOrColor)
                this.Designs = [this.Designs;Design];
                this.DesignStyles = [this.DesignStyles;styleOrColor];
            end
        end

        function removeDesign(this,Design)
            removeDesign_(this,Design)
            
            [~,~,idx] = intersect(Design,this.Designs);
            this.Designs(idx) = [];

            if controllib.chart.internal.utils.isChart(this.PlotHandle)
                this.DesignSemanticColorsUsed(idx) = [];
                if isempty(this.DesignSemanticColorsUsed)
                    this.DesignSemanticColorsUsed = string.empty;
                end
            else
                this.DesignStyles(idx,:) = [];
            end
        end
       
    end
    
    
    %% Protected Methods
    methods (Access = protected)
        function addListeners(this)
            this.PlotDeleteListener = event.listener(getFigure(this),'ObjectBeingDestroyed',@(es,ed) delete(this));
        end
        
        function StyleList = getDesignStyleList(this)
            StyleList = this.DesignStyleList;
        end
        
        function Style = findNextAvailableDesignStyle(this)
            StyleList = getDesignStyleList(this);
                        
            index = zeros(size(StyleList(:,1)));
            for ct=1:length(this.DesignStyles(:,1))
                [~,~,match] = intersect(this.DesignStyles(ct,1),StyleList(:,1));
                index(match) = index(match) + 1;
            end
            
            [~, StyleIdx] = min(index);
            Style = StyleList(StyleIdx,:);
        end

        function designColor = findNextAvailableDesignColor(this)
            index = zeros(size(this.DesignSemanticColorList));
            if ~isempty(this.DesignSemanticColorsUsed)
                for ct = 1:length(this.DesignSemanticColorsUsed)
                    [~,~,match] = intersect(this.DesignSemanticColorsUsed(ct),this.DesignSemanticColorList);
                    index(match) = index(match) + 1;
                end
                [~,designColorIdx] = min(index);
            else
                designColorIdx = 1;
            end
            designColor = this.DesignSemanticColorList(designColorIdx);
        end
    end
    
    
    %% Hidden Public Methods
    methods (Hidden, Access = public)
        function h = getPlotHandle(this)
            h = this.PlotHandle;
        end
        
        function B = isPlotValid(this)
            % Retruns true if plot is created and valid
            B = false;
            if ~isempty(this.PlotHandle)
                if ishandle(this.PlotHandle) || ...
                    (controllib.chart.internal.utils.isChart(this.PlotHandle) && ...
                     isvalid(this.PlotHandle))
                    B = true;
                end
            end
        end

    end
    
    %% Sealed Public Methods
    methods (Access = public, Sealed = true)
        function createPlot(this)
            h = createPlot_(this);
            this.PlotHandle = h;
            addListeners(this)
        end
    end
        
    %% Abstract protected methods
    methods (Abstract = true, Access = protected)
        % part of  
        h = createPlot_(this,Fig) % Returns resppack handle
        addDesign_(this,Design,Style) % Adds a design to a plot
        removeDesign_(this,Design) % Removes a design froma plot
        % full
        updateDesign(this,Design) % Updates the plotting of a design
        updatePlot(this) % Updates the entire plot
        recreatePlot(this) % Recreates the plot
        cleanup(this) % cleanup code
    end

end