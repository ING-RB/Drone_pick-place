classdef ImpulseAxesView < controllib.chart.internal.view.axes.TimeRowColumnAxesView & ...
                        controllib.chart.internal.view.axes.MixInInputOutputAxesViewLabels

    % Copyright 2022-2024 The MathWorks, Inc.

    %% Constructor
    methods
        function this = ImpulseAxesView(chart,varargin)
            arguments
                chart (1,1) controllib.chart.ImpulsePlot
            end

            arguments (Repeating)
                varargin
            end

            this@controllib.chart.internal.view.axes.TimeRowColumnAxesView(chart,varargin{:});
            build(this);
        end
    end

    %% Public methods
    methods
        function updateResponseView(this,response)
            arguments
                this (1,1) controllib.chart.internal.view.axes.ImpulseAxesView
                response (1,1)  controllib.chart.response.ImpulseResponse
            end
            idx = find(arrayfun(@(x) x.Response.Tag == response.Tag,this.ResponseViews),1);
            responseView = this.ResponseViews(idx);
            hasDifferentCharacteristics = ~isempty(setdiff(...
                union(responseView.CharacteristicTypes,response.CharacteristicTypes),...
                intersect(responseView.CharacteristicTypes,response.CharacteristicTypes)));
            if responseView.Response.NResponses ~= response.NResponses ||...
                    responseView.Response.NRows ~= response.NRows ||...
                    responseView.Response.NColumns ~= response.NColumns ||...
                    responseView.IsDiscrete ~= response.IsDiscrete ||...
                    hasDifferentCharacteristics ||...
                    (isa(responseView.ResponseLines,'matlab.graphics.chart.primitive.Stem') && ~isa(response.Model,"idlti"))
                delete(responseView);
                this.ResponseViews = this.ResponseViews(isvalid(this.ResponseViews));
                responseView = createResponseView(this,response);
                responseView.ColumnNames = this.ColumnNames;
                responseView.RowNames = this.RowNames;
                createResponseDataTips(responseView);
                this.ResponseViews = [this.ResponseViews(1:idx-1); responseView; this.ResponseViews(idx:end)];
                parentResponseViews(this);
                for ii = 1:length(responseView.CharacteristicTypes)
                    charType = responseView.CharacteristicTypes(ii);
                    updateCharacteristic(responseView,charType);
                    if isfield(this.CharacteristicsVisibility,charType)
                        setCharacteristicVisible(responseView,charType,this.CharacteristicsVisibility.(charType));
                    end
                end
                postParentResponseView(this,responseView);
            else
                update(responseView);
            end
        end
    end

    %% Protected methods
    methods (Access = protected)
        function responseView = createResponseView(this,response)
            arguments
                this (1,1) controllib.chart.internal.view.axes.ImpulseAxesView
                response (1,1) controllib.chart.response.ImpulseResponse
            end
            responseView = controllib.chart.internal.view.wave.ImpulseResponseView(response,...
                ColumnVisible=this.ColumnVisible(1:response.NColumns),...
                RowVisible=this.RowVisible(1:response.NRows),...
                ShowMagnitude=this.ShowMagnitude,...
                ShowReal=this.ShowReal,...
                ShowImaginary=this.ShowImaginary);
            responseView.TimeUnit = this.TimeUnit;
        end

        function postParentResponseView(this,responseView)
            arguments
                this (1,1) controllib.chart.internal.view.axes.ImpulseAxesView
                responseView (1,1) controllib.chart.internal.view.wave.ImpulseResponseView
            end
            if ~responseView.Response.IsReal
                ax = getAxes(this);
                aspectRatio = ax(1).PlotBoxAspectRatio(1:2);
                updateMarkers(responseView,AspectRatio=aspectRatio);
            end
        end

        function [timeFocus, amplitudeFocus] = computeFocus(this,responses)
            arguments
                this (1,1) controllib.chart.internal.view.axes.ImpulseAxesView
                responses (:,1) controllib.chart.response.ImpulseResponse
            end
            timeFocus = repmat({[NaN NaN]},this.NRows,this.NColumns);
            amplitudeFocus = repmat({[NaN NaN]},this.NRows,this.NColumns);
            if ~isempty(responses)
                data = [responses.ResponseData];
                crVisible =  isfield(this.CharacteristicsVisibility,'ConfidenceRegion') && this.CharacteristicsVisibility.ConfidenceRegion;
                brVisible =  isfield(this.CharacteristicsVisibility,'BoundaryRegion') && this.CharacteristicsVisibility.BoundaryRegion;
                [timeFocus_, amplitudeFocus_, timeUnit] = getCommonFocusForMultipleData(data,crVisible,brVisible,{responses.ArrayVisible},...
                    ShowMagnitude=this.ShowMagnitude,ShowReal=this.ShowReal,ShowImaginary=this.ShowImaginary);
                timeFocus(1:size(timeFocus_,1),1:size(timeFocus_,2)) = timeFocus_;
                amplitudeFocus(1:size(amplitudeFocus_,1),1:size(amplitudeFocus_,2)) = amplitudeFocus_;
                timeConversionFcn = getTimeUnitConversionFcn(this,timeUnit,this.TimeUnit);
                for ko = 1:this.NRows
                    for ki = 1:this.NColumns
                        timeFocus{ko,ki} = timeConversionFcn(timeFocus{ko,ki});
                    end
                end
            end
        end

        function postUpdateCharacteristic(this,characteristicType,~)
            if characteristicType=="ConfidenceRegion" || characteristicType=="BoundaryRegion"
                updateFocus(this);
            end
        end

        function cbAxesGridXLimitsChanged(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.ImpulseAxesView
            end
            cbAxesGridXLimitsChanged@controllib.chart.internal.view.axes.TimeRowColumnAxesView(this);
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
                this (1,1) controllib.chart.internal.view.axes.ImpulseAxesView
            end
            cbAxesGridYLimitsChanged@controllib.chart.internal.view.axes.TimeRowColumnAxesView(this);
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

