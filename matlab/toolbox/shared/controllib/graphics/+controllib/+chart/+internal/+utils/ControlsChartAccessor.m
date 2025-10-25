classdef (Abstract,AllowedSubclasses=?matlab.plottools.service.accessor.ControlsChartAccessor) ControlsChartAccessor < matlab.plottools.service.accessor.ChartAccessor
    %CONTROLSCHARTACCESSOR Provides the methods to access all controls
    %chart properties from figure toolstrip.
    
    % Copyright 2024 The MathWorks, Inc.

    methods
        function this = ControlsChartAccessor()
            this = this@matlab.plottools.service.accessor.ChartAccessor();            
        end
        
        function id = getIdentifier(~)
            id = {'controllib.chart.StepPlot';...
			'controllib.chart.ImpulsePlot';...
			'controllib.chart.InitialPlot';...
			'controllib.chart.LSimPlot';...
			'controllib.chart.BodePlot';...
			'controllib.chart.NicholsPlot';...
			'controllib.chart.NyquistPlot';...
			'controllib.chart.SigmaPlot';...
			'controllib.chart.SectorPlot';...
			'controllib.chart.PassivePlot';...
			'controllib.chart.PZPlot';...
			'controllib.chart.IOPZPlot';...
			'controllib.chart.RLocusPlot';...
			'controllib.chart.HSVPlot';...
			'controllib.chart.DiskMarginPlot';...
			'controllib.chart.editor.BodeEditor';...
			'controllib.chart.editor.NicholsEditor';...
			'controllib.chart.editor.RLocusEditor';...
			'robustplot.DiskMarginPlot';...
			'robustplot.WCSigmaPlot';...
			'robustplot.WCDiskMarginPlot';...
			'slcontrolplot.FFTPlot';...
			'slcontrolplot.SimComparePlot';...
			'mpcplots.InputResponsePlot';...
			'mpcplots.OutputResponsePlot'};
        end
        
        function result = isUnifiedChart(~)
            result = true;
        end
    end

    % SupportsFeature Overrides
    methods (Access=protected)
        function result = supportsTitle(this)
            result = isscalar(this.ReferenceObject.Title.String);
        end

        function result = supportsSubtitle(this)
            result = isscalar(this.ReferenceObject.Subtitle.String);
        end

        function result = supportsXLabel(this)
            result = isscalar(this.ReferenceObject.XLabel.String);
        end

        function result = supportsYLabel(this)
            result = isscalar(this.ReferenceObject.YLabel.String);
        end

        function result = supportsZLabel(~)
            result = false;
        end

        function result = supportsGrid(~)
            result = true;
        end

        function result = supportsLegend(~)
            result = true;
        end

        function result = supportsColorbar(~)
            result = false;
        end
    end

    % Getter Method Overrides
    methods (Access=protected)
        function result = getTitle(this)
            tcl = getChartLayout(this.ReferenceObject);
            result = tcl.Title.Text;
        end

        function result = getSubtitle(this)
            tcl = getChartLayout(this.ReferenceObject);
            result = tcl.Subtitle.Text;
        end

        function result = getXLabel(this)
            tcl = getChartLayout(this.ReferenceObject);
            result = tcl.XLabel.Text;
            % Overwrite xlabel string with label without units
            result.String = this.ReferenceObject.XLabel.String;
        end

        function result = getYLabel(this)
            tcl = getChartLayout(this.ReferenceObject);
            result = tcl.YLabel.Text;
            % Overwrite ylabel string with label without units
            result.String = this.ReferenceObject.YLabel.String;
        end

        function result = getGrid(this)
            result = this.ReferenceObject.AxesStyle.GridVisible;
        end

        function result = getLegend(this)
            result = this.ReferenceObject.LegendVisible;
        end
    end

    % Setter Method Overrides
    methods (Access=protected)
        function setTitle(this, value)
            this.ReferenceObject.Title.String = value+"a"; %Dummy to dirty object
            this.ReferenceObject.Title.String = value;
        end

        function setSubtitle(this, value)
            this.ReferenceObject.Subtitle.String = value+"a"; %Dummy to dirty object
            this.ReferenceObject.Subtitle.String = value;
        end

        function setXLabel(this, value)
            this.ReferenceObject.XLabel.String = value+"a"; %Dummy to dirty object
            this.ReferenceObject.XLabel.String = value;
        end

        function setYLabel(this, value)
            this.ReferenceObject.YLabel.String = value+"a"; %Dummy to dirty object
            this.ReferenceObject.YLabel.String = value;
        end

        function setGrid(this, value)
            this.ReferenceObject.AxesStyle.GridVisible = value; 
        end

        function setLegend(this, value)
            this.ReferenceObject.LegendVisible = value;
        end
    end

    % Code Generation Overrides
    methods (Access=protected)
        function code = generateTitleCode(~)
            code = '';
        end  

        function code = generateSubtitleCode(~)
            code = '';
        end  

        function code = generateXLabelCode(~)
            code = '';
        end          

        function code = generateYLabelCode(~)
            code = '';
        end 

        function code = generateZLabelCode(~)
            code = '';
        end         

        function code = generateGridCode(~)
            code = '';
        end 

        function code = generateXGridCode(~)
            code = '';
        end

        function code = generateYGridCode(~)
            code = '';
        end

        function code = generateZGridCode(~)
            code = '';
        end

        function code = generateRGridCode(~)
            code = '';
        end

        function code = generateThetaGridCode(~)
            code = '';
        end

        function code = generateLegendCode(~)
            code = '';
        end         

        function code = generateColorbarCode(~)
            code = '';
        end         
    end
end
