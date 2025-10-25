classdef HSVResponseView < controllib.chart.internal.view.wave.BaseResponseView
    % Class for managing lines and markers for a time based plot

    % Copyright 2021 The MathWorks, Inc.

    %% Properties
    properties (SetAccess = protected)
        InfiniteSVBar
        FiniteSVBar
        ErrorBoundLine
        InfiniteSVBarLegend
        FiniteSVBarLegend
        ErrorBoundLineLegend
    end

    %% Constructor
    methods
        function this = HSVResponseView(Response,varargin)
            this@controllib.chart.internal.view.wave.BaseResponseView(Response,varargin{:});
            build(this);
        end
    end

    %% Public methods
    methods
        function updateInfiniteSVHeight(this,YLimits)
            arguments
                this (1,1) controllib.chart.internal.view.wave.HSVResponseView
                YLimits (1,2) double
            end
            this.InfiniteSVBar.YData = repmat(YLimits(2),1,length(this.InfiniteSVBar.YData));
        end

        function updateErrorBoundBaseValue(this,YAxisScale)
            arguments
                this (1,1) controllib.chart.internal.view.wave.HSVResponseView
                YAxisScale (1,1) string {mustBeMember(YAxisScale,["log","linear"])}
            end
            errorBound = this.Response.ResponseData.ErrorBound;
            baseValue = getBaseValue(this.Response.ResponseData,YAxisScale);
            errorBound(errorBound<baseValue) = baseValue;
            this.ErrorBoundLine.YData = errorBound;
        end
    end

    %% Protected methods
    methods (Access = protected)
        function createResponseObjects(this)
            % Add Bar Chart for Unstable Modes
            this.InfiniteSVBar = createGraphicsObjects(this,"bar",Tag='HSVInfiniteSV');
            this.disableDataTipInteraction(this.InfiniteSVBar);
            controllib.plot.internal.utils.setColorProperty(this.InfiniteSVBar,...
                ["FaceColor","EdgeColor"],controllib.plot.internal.utils.GraphicsColor(10).SemanticName)
            % Add Bar Chart for Stable Modes
            this.FiniteSVBar = createGraphicsObjects(this,"bar",Tag='HSVFiniteSV');
            this.disableDataTipInteraction(this.FiniteSVBar);
            controllib.plot.internal.utils.setColorProperty(this.FiniteSVBar,...
                ["FaceColor","EdgeColor"],controllib.plot.internal.utils.GraphicsColor(1).SemanticName)
            % Add Error Bound
            this.ErrorBoundLine = createGraphicsObjects(this,"line",Tag='HSVErrorBound');
            this.ErrorBoundLine.LineWidth = 2;
            controllib.plot.internal.utils.setColorProperty(this.ErrorBoundLine,...
                "Color",controllib.plot.internal.utils.GraphicsColor(7,"secondary").SemanticName)
        end

        function legendObjects = createLegendObjects(this)
            this.InfiniteSVBarLegend = createGraphicsObjects(this,"bar",...
                DisplayName = getString(message('Controllib:plots:strUnstableModes')));
            controllib.plot.internal.utils.setColorProperty(this.InfiniteSVBarLegend,...
                ["FaceColor","EdgeColor"],controllib.plot.internal.utils.GraphicsColor(10).SemanticName)
            this.FiniteSVBarLegend = createGraphicsObjects(this,"bar",...
                DisplayName = getString(message('Controllib:plots:strStableModes')));
            controllib.plot.internal.utils.setColorProperty(this.FiniteSVBarLegend,...
                ["FaceColor","EdgeColor"],controllib.plot.internal.utils.GraphicsColor(1).SemanticName)
            this.ErrorBoundLineLegend = createGraphicsObjects(this,"line",...
                DisplayName = getString(message('Controllib:plots:strHSVAbsoluteErrorBound')));
            this.ErrorBoundLineLegend.LineWidth = 2;
            controllib.plot.internal.utils.setColorProperty(this.ErrorBoundLineLegend,...
                "Color",controllib.plot.internal.utils.GraphicsColor(7,"secondary").SemanticName)

            legendObjects = [this.InfiniteSVBarLegend,this.FiniteSVBarLegend,this.ErrorBoundLineLegend];
        end

        function responseObjects = getResponseObjects_(this,~,~,~)
            responseObjects = cat(3,this.ErrorBoundLine,this.FiniteSVBar,this.InfiniteSVBar);
        end

        function updateResponseData(this)
            % Convert frequency, magnitude and phase
            hsv = this.Response.ResponseData.HSV;
            errorBound = this.Response.ResponseData.ErrorBound;
            errorType = this.Response.ResponseData.ErrorType;
            hsvType = this.Response.ResponseData.HSVType;

            nsv = numel(hsv);
            nns = sum(isinf(hsv)); % number of infinite HSV
            hsvf = hsv(nns+1:nsv,:);

            % Stable HSV
            this.FiniteSVBar.XData = (nns+1:nsv)-strcmp(hsvType,"loss");
            this.FiniteSVBar.YData = hsvf;            
            this.FiniteSVBarLegend.LegendDisplay = nns<nsv; % Only show if there are stable modes

            % Unstable HSV
            this.InfiniteSVBar.XData = (1:nns)-strcmp(hsvType,"loss");
            this.InfiniteSVBar.YData = repmat(1e20,1,nns);            
            this.InfiniteSVBarLegend.LegendDisplay = nns>0; % Only show if there are unstable modes

            % Error bound (Note: last entry is always zero)
            this.ErrorBoundLine.XData = 0:nsv;
            if all(isnan(errorBound(1:end-1))) || strcmp(hsvType,"energy") || strcmp(hsvType,"loss")
                % No error bound for band-limited, energy, or loss
                this.ErrorBoundLineLegend.LegendDisplay = 'off';
            else
                this.ErrorBoundLineLegend.LegendDisplay = 'on';
                if errorType=="absolute"
                    this.ErrorBoundLineLegend.DisplayName = getString(message('Controllib:plots:strHSVAbsoluteErrorBound'));
                else
                    this.ErrorBoundLineLegend.DisplayName = getString(message('Controllib:plots:strHSVRelativeErrorBound'));
                end
            end
            updateResponseVisibility(this,this.RowVisible,this.ColumnVisible,this.ArrayVisible);
        end

        function updateResponseVisibility(this,rowVisible,columnVisible,arrayVisible)
            % updateResponseVisibility(this,System)
            %
            %   Update the visibility of the response line objects based on
            %   System.Visible and System.ArrayVisible. Implement in sub
            %   class.
            arguments
                this (1,1) controllib.chart.internal.view.wave.BaseResponseView
                rowVisible (:,1) logical
                columnVisible (1,:) logical
                arrayVisible logical
            end
            visibilityFlag = any(arrayVisible,'all') & any(rowVisible,'all') & any(columnVisible,'all');
            if visibilityFlag
                hsv = this.Response.ResponseData.HSV;
                errorBound = this.Response.ResponseData.ErrorBound;
                hsvType = this.Response.ResponseData.HSVType;
                nsv = numel(hsv);
                nns = sum(isinf(hsv));

                this.InfiniteSVBar.Visible = nns>0;
                this.FiniteSVBar.Visible = nns<nsv;
                this.ErrorBoundLine.Visible = ~all(isnan(errorBound(1:end-1))) && ~strcmp(hsvType,"energy") && ~strcmp(hsvType,"loss");
            else
                this.InfiniteSVBar.Visible = false;
                this.FiniteSVBar.Visible = false;
                this.ErrorBoundLine.Visible = false;                
            end
        end

        function createResponseDataTips_(this,~,~,~,~,~,customDataTipRows)
            % Add to DataTipTemplate
            frequencyRow = dataTipTextRow(getString(message('Controllib:plots:strOrder')),'XData','%0.3g');
            magnitudeRow = dataTipTextRow(getString(message('Controllib:plots:strErrorBound')),'YData','%0.3g');
            this.ErrorBoundLine.DataTipTemplate.DataTipRows = ...
                [frequencyRow; magnitudeRow; customDataTipRows(:)];
        end

        function cbResponseNameChanged(this) %#ok<MANU>
        end
    end
end