classdef TimePhasorInputOutputAxesView < controllib.chart.internal.view.axes.RowColumnAxesView & ...
        controllib.chart.internal.foundation.MixInTimeUnit & ...
        controllib.chart.internal.view.axes.MixInInputOutputAxesViewLabels
    % TimeView

    % Copyright 2021-2022 The MathWorks, Inc.

    %% Constructor
    methods
        function this = TimePhasorInputOutputAxesView(chart,varargin)
            arguments
                chart (1,1) controllib.chart.internal.foundation.AbstractPlot
            end

            arguments (Repeating)
                varargin
            end
            this@controllib.chart.internal.foundation.MixInTimeUnit(chart.TimeUnit);
            this@controllib.chart.internal.view.axes.RowColumnAxesView(chart,varargin{:});
            build(this);
        end
    end

    %% Public methods
    methods        
        function updateResponseView(this,response)
            arguments
                this (1,1) controllib.chart.internal.view.axes.RowColumnAxesView
                response (1,1)  controllib.chart.internal.foundation.BaseResponse ...
                    {controllib.chart.internal.view.axes.TimeRowColumnAxesView.mustBeRowColumnResponse(response)}
            end
            idx = find(arrayfun(@(x) x.Response.Tag == response.Tag,this.ResponseViews),1);
            responseView = this.ResponseViews(idx);
            hasDifferentCharacteristics = ~isempty(setdiff(...
                union(responseView.CharacteristicTypes,response.CharacteristicTypes),...
                intersect(responseView.CharacteristicTypes,response.CharacteristicTypes)));
            isOldResponseReal = all(responseView.IsReal);
            isNewResponseReal = all(response.IsReal);
            if responseView.Response.NResponses ~= response.NResponses ||...
                    responseView.Response.NRows ~= response.NRows ||...
                    responseView.Response.NColumns ~= response.NColumns ||...
                    ~isequal(responseView.PlotColumnIdx,response.ResponseData.PlotInputIdx) || ...
                    ~isequal(responseView.PlotRowIdx,response.ResponseData.PlotOutputIdx) || ...
                    responseView.IsDiscrete ~= response.IsDiscrete ||...
                    hasDifferentCharacteristics || ...
                    isOldResponseReal ~= isNewResponseReal
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
                this (1,1) controllib.chart.internal.view.axes.RowColumnAxesView
                response (1,1) controllib.chart.internal.foundation.ModelResponse
            end
            responseView = controllib.chart.internal.view.wave.TimePhasorInputOutputResponseView(response,...
                ColumnVisible=this.ColumnVisible(1:response.NColumns),...
                RowVisible=this.RowVisible(1:response.NRows));
            responseView.TimeUnit = this.TimeUnit;
        end

        function [realAxisFocus,imaginaryAxisFocus] = updateFocus_(this,responses)
            arguments
                this (1,1) controllib.chart.internal.view.axes.RowColumnAxesView
                responses (:,1) controllib.chart.internal.foundation.BaseResponse ...
                    {controllib.chart.internal.view.axes.TimeRowColumnAxesView.mustBeRowColumnResponse(responses)}
            end
            % Compute focus
            [realAxisFocus,imaginaryAxisFocus] = computeFocus(this,responses);
        end

        function cbTimeUnitChanged(this,conversionFcn)
            arguments
                this (1,1) controllib.chart.internal.view.axes.RowColumnAxesView
                conversionFcn (1,1) function_handle
            end
            % Change TimeUnit on each response
            for n = 1:length(this.ResponseViews)
                this.ResponseViews(n).TimeUnit = this.TimeUnit;
            end
        end

        function postParentResponseView(this,responseView)
            arguments
                this (1,1) controllib.chart.internal.view.axes.TimePhasorInputOutputAxesView
                responseView (1,1) controllib.chart.internal.view.wave.TimePhasorInputOutputResponseView
            end
            updateFocus(this);
            if ~responseView.Response.IsReal
                ax = getAxes(this);
                aspectRatio = ax(1).PlotBoxAspectRatio(1:2);
                updateMarkers(responseView,AspectRatio=aspectRatio);
            end
        end

        function [realAxisFocus, imaginaryAxisFocus] = computeFocus(this,responses)
            arguments
                this (1,1) controllib.chart.internal.view.axes.TimePhasorInputOutputAxesView
                responses (:,1) controllib.chart.internal.foundation.BaseResponse ...
                    {controllib.chart.internal.view.axes.TimeRowColumnAxesView.mustBeRowColumnResponse(responses)}
            end
            realAxisFocus = repmat({[NaN NaN]},this.NRows,this.NColumns);
            imaginaryAxisFocus = repmat({[NaN NaN]},this.NRows,this.NColumns);
            if ~isempty(responses)
                data = [responses.ResponseData];
                [realAxisFocus,imaginaryAxisFocus] = getCommonRealImaginaryFocusForMultipleData(data,...
                    {responses.ArrayVisible});
            end
        end

        function cbAxesGridXLimitsChanged(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.TimePhasorInputOutputAxesView
            end
            cbAxesGridXLimitsChanged@controllib.chart.internal.view.axes.RowColumnAxesView(this);
            ax = getAxes(this);
            isReal = get([this.ResponseViews.Response],'IsReal');
            if iscell(isReal)
                isReal = cell2mat(isReal);
            end
            allIsReal = all(isReal);
            if ~allIsReal
                aspectRatio = ax(1).PlotBoxAspectRatio;
                for k = 1:length(this.ResponseViews)
                    updateMarkers(this.ResponseViews(k),AspectRatio=aspectRatio);
                end
            end
        end

        function cbAxesGridYLimitsChanged(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.TimePhasorInputOutputAxesView
            end
            cbAxesGridYLimitsChanged@controllib.chart.internal.view.axes.RowColumnAxesView(this);
            ax = getAxes(this);
            isReal = get([this.ResponseViews.Response],'IsReal');
            if iscell(isReal)
                isReal = cell2mat(isReal);
            end
            allIsReal = all(isReal);
            if ~allIsReal
                aspectRatio = ax(1).PlotBoxAspectRatio;
                for k = 1:length(this.ResponseViews)
                    updateMarkers(this.ResponseViews(k),AspectRatio=aspectRatio);
                end
            end
        end
    end
end

