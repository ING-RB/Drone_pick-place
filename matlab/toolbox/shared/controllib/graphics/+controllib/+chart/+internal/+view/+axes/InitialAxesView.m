classdef InitialAxesView < controllib.chart.internal.view.axes.TimeOutputAxesView
    % InitialView
    
    % Copyright 2023 The MathWorks, Inc.
    methods
        function this = InitialAxesView(chart,varargin)
            arguments
                chart (1,1) controllib.chart.InitialPlot
            end

            arguments (Repeating)
                varargin
            end
            this@controllib.chart.internal.view.axes.TimeOutputAxesView(chart,varargin{:});
            build(this);
        end
    end

    methods (Access = protected)
        function responseView = createResponseView(this,response)
            arguments
                this (1,1) controllib.chart.internal.view.axes.InitialAxesView
                response (1,1) controllib.chart.response.InitialResponse
            end
            responseView = controllib.chart.internal.view.wave.InitialResponseView(response,...
                OutputVisible=this.RowVisible(1:response.NOutputs),...
                ShowMagnitude=this.ShowMagnitude,...
                ShowReal=this.ShowReal,...
                ShowImaginary=this.ShowImaginary);
            responseView.TimeUnit = this.TimeUnit;
        end

        function postParentResponseView(this,responseView)
            arguments
                this (1,1) controllib.chart.internal.view.axes.InitialAxesView
                responseView (1,1) controllib.chart.internal.view.wave.InitialResponseView
            end
            if ~responseView.Response.IsReal
                ax = getAxes(this);
                aspectRatio = ax(1).PlotBoxAspectRatio(1:2);
                updateMarkers(responseView,AspectRatio=aspectRatio);
            end
        end

        function cbAxesGridXLimitsChanged(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.InitialAxesView
            end
            cbAxesGridXLimitsChanged@controllib.chart.internal.view.axes.TimeOutputAxesView(this);
            if ~isempty(this.ResponseViews)
                allIsReal = true;
                for k = 1:length(this.ResponseViews)
                    allIsReal = allIsReal & all(this.ResponseViews(k).Response.IsReal(:));
                end
                if ~allIsReal
                    ax = getAxes(this);
                    aspectRatio = ax(1).PlotBoxAspectRatio;
                    for k = 1:length(this.ResponseViews)
                        if any(~this.ResponseViews(k).Response.IsReal)
                            updateMarkers(this.ResponseViews(k),AspectRatio=aspectRatio);
                        end
                    end
                end
            end
        end

        function cbAxesGridYLimitsChanged(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.InitialAxesView
            end
            cbAxesGridYLimitsChanged@controllib.chart.internal.view.axes.TimeOutputAxesView(this);
            if ~isempty(this.ResponseViews)
                allIsReal = true;
                for k = 1:length(this.ResponseViews)
                    allIsReal = allIsReal & all(this.ResponseViews(k).Response.IsReal(:));
                end
                if ~allIsReal
                    ax = getAxes(this);
                    aspectRatio = ax(1).PlotBoxAspectRatio;
                    for k = 1:length(this.ResponseViews)
                        if any(~this.ResponseViews(k).Response.IsReal)
                            updateMarkers(this.ResponseViews(k),AspectRatio=aspectRatio);
                        end
                    end
                end
            end
        end
    end
end

