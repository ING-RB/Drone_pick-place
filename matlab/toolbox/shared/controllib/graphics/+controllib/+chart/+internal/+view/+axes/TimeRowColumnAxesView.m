classdef (Abstract) TimeRowColumnAxesView < controllib.chart.internal.view.axes.RowColumnAxesView & ...
        controllib.chart.internal.foundation.MixInTimeUnit
    % TimeView

    % Copyright 2021-2022 The MathWorks, Inc.

    %% Properties
    properties (Dependent,SetObservable,AbortSet)
        Normalize
        ShowMagnitude
        ShowReal
        ShowImaginary
    end

    properties (Access = private)
        XLabelWithoutUnits = ""
        Normalize_I (1,1) matlab.lang.OnOffSwitchState = false
        ShowMagnitude_I (1,1) matlab.lang.OnOffSwitchState = false
        ShowReal_I (1,1) matlab.lang.OnOffSwitchState = true
        ShowImaginary_I (1,1) matlab.lang.OnOffSwitchState = true
        YLimitsSharingBeforeNormalize
    end

    %% Constructor
    methods
        function this = TimeRowColumnAxesView(chart,varargin)
            arguments
                chart (1,1) controllib.chart.internal.foundation.RowColumnPlot
            end

            arguments (Repeating)
                varargin
            end
            this@controllib.chart.internal.foundation.MixInTimeUnit(chart.TimeUnit);
            this@controllib.chart.internal.view.axes.RowColumnAxesView(chart,varargin{:});
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
            isOldResponseReal = all(responseView.IsReal(:));
            isNewResponseReal = all(response.IsReal(:));
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

    %% Get/Set
    methods
        % Normalize
        function Normalize = get.Normalize(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.TimeRowColumnAxesView
            end
            Normalize = this.Normalize_I;
        end

        function set.Normalize(this,Normalize)
            arguments
                this (1,1) controllib.chart.internal.view.axes.TimeRowColumnAxesView
                Normalize (1,1) matlab.lang.OnOffSwitchState
            end
            this.Normalize_I = Normalize;
            this.AxesGrid.ShowYTickLabels = ~Normalize;
            if Normalize
                this.YLimitsSharingBeforeNormalize = this.AxesGrid.YLimitsSharing;
                this.AxesGrid.YLimitsSharing = "none";
                this.AxesGrid.YLimitsMode = "auto";
            else
                this.AxesGrid.YLimitsSharing = this.YLimitsSharingBeforeNormalize;
            end
            update(this.AxesGrid);
        end

        % ShowMagnitudeResponse
        function ShowMagnitudeResponse = get.ShowMagnitude(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.TimeRowColumnAxesView
            end
            ShowMagnitudeResponse = this.ShowMagnitude_I;
        end

        function set.ShowMagnitude(this,ShowMagnitudeResponse)
            arguments
                this (1,1) controllib.chart.internal.view.axes.TimeRowColumnAxesView
                ShowMagnitudeResponse (1,1) matlab.lang.OnOffSwitchState
            end
            for k = 1:length(this.ResponseViews)
                this.ResponseViews(k).ShowMagnitudeResponse = ShowMagnitudeResponse;
            end
            this.ShowMagnitude_I = ShowMagnitudeResponse;
            updateFocus(this);            
        end

        % ShowReal
        function ShowReal = get.ShowReal(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.TimeRowColumnAxesView
            end
            ShowReal = this.ShowReal_I;
        end

        function set.ShowReal(this,ShowReal)
            arguments
                this (1,1) controllib.chart.internal.view.axes.TimeRowColumnAxesView
                ShowReal (1,1) matlab.lang.OnOffSwitchState
            end
            for k = 1:length(this.ResponseViews)
                this.ResponseViews(k).ShowReal = ShowReal;
            end
            this.ShowReal_I = ShowReal;
            updateFocus(this);            
        end

        % ShowImaginary
        function ShowImaginary = get.ShowImaginary(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.TimeRowColumnAxesView
            end
            ShowImaginary = this.ShowImaginary_I;
        end

        function set.ShowImaginary(this,ShowImaginary)
            arguments
                this (1,1) controllib.chart.internal.view.axes.TimeRowColumnAxesView
                ShowImaginary (1,1) matlab.lang.OnOffSwitchState
            end
            for k = 1:length(this.ResponseViews)
                this.ResponseViews(k).ShowImaginary = ShowImaginary;
            end
            this.ShowImaginary_I = ShowImaginary;
            updateFocus(this);            
        end
    end

    %% Protected methods
    methods (Access = protected)
        function [timeFocus, amplitudeFocus] = updateFocus_(this,responses)
            arguments
                this (1,1) controllib.chart.internal.view.axes.TimeRowColumnAxesView
                responses (:,1) controllib.chart.internal.foundation.BaseResponse ...
                    {controllib.chart.internal.view.axes.TimeRowColumnAxesView.mustBeRowColumnResponse(responses)}
            end
            % Compute focus
            [timeFocus, amplitudeFocus] = computeFocus(this,responses);
        end

        function cbTimeUnitChanged(this,conversionFcn)
            arguments
                this (1,1) controllib.chart.internal.view.axes.TimeRowColumnAxesView
                conversionFcn (1,1) function_handle
            end
            % Change TimeUnit on each response
            for n = 1:length(this.ResponseViews)
                this.ResponseViews(n).TimeUnit = this.TimeUnit;
            end

            % Convert Limits
            for ii = 1:numel(this.AxesGrid.XLimitsFocus)
                this.AxesGrid.XLimitsFocus{ii} = conversionFcn(this.AxesGrid.XLimitsFocus{ii});
            end

            for ii = 1:numel(this.AxesGrid.XLimits)
                if strcmp(this.AxesGrid.XLimitsMode{ii},'manual')
                    this.AxesGrid.XLimits{ii} = conversionFcn(this.AxesGrid.XLimits{ii});
                end
            end

            update(this.AxesGrid);

            % Modify Label
            setXLabelString(this,this.XLabelWithoutUnits);
        end

        function XLabel = getXLabelString(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.TimeRowColumnAxesView
            end
            XLabel = this.XLabelWithoutUnits;
        end

        function setXLabelString(this,XLabel)
            arguments
                this (1,1) controllib.chart.internal.view.axes.TimeRowColumnAxesView
                XLabel (1,1) string
            end
            this.XLabelWithoutUnits = XLabel;
            this.AxesGrid.XLabel = this.XLabelWithoutUnits + " (" + this.TimeUnitLabel + ")";
        end
        
        function [timeFocus, amplitudeFocus] = computeFocus(this,responses)
            arguments
                this (1,1) controllib.chart.internal.view.axes.TimeRowColumnAxesView
                responses (:,1) controllib.chart.internal.foundation.BaseResponse ...
                    {controllib.chart.internal.view.axes.TimeRowColumnAxesView.mustBeRowColumnResponse(responses)}
            end
            timeFocus = repmat({[NaN NaN]},this.NRows,this.NColumns);
            amplitudeFocus = repmat({[NaN NaN]},this.NRows,this.NColumns);
            if ~isempty(responses)
                data = [responses.ResponseData];
                [timeFocus_, amplitudeFocus_, timeUnit] = getCommonFocusForMultipleData(data,{responses.ArrayVisible});
                timeConversionFcn = getTimeUnitConversionFcn(this,timeUnit,this.TimeUnit);
                for ko = 1:size(timeFocus_,1)
                    for ki = 1:size(timeFocus_,2)
                        timeFocus_{ko,ki} = timeConversionFcn(timeFocus_{ko,ki});
                    end
                end
                timeFocus(1:size(timeFocus_,1),1:size(timeFocus_,2)) = timeFocus_;
                amplitudeFocus(1:size(amplitudeFocus_,1),1:size(amplitudeFocus_,2)) = amplitudeFocus_;
            end
        end
    end
end

