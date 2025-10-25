classdef TimeOutputAxesView < controllib.chart.internal.view.axes.OutputAxesView & ...
        controllib.chart.internal.foundation.MixInTimeUnit
    % TimeOutputView

    % Copyright 2023 The MathWorks, Inc.

    %% Properties
    properties (Dependent, AbortSet)
        Normalize
        ShowMagnitude
        ShowReal
        ShowImaginary
    end

    properties (Access = private)
        XLabelWithoutUnits string = ""
        Normalize_I (1,1) matlab.lang.OnOffSwitchState = false
        ShowMagnitude_I (1,1) matlab.lang.OnOffSwitchState = false
        ShowReal_I (1,1) matlab.lang.OnOffSwitchState = true
        ShowImaginary_I (1,1) matlab.lang.OnOffSwitchState = true
        YLimitsSharingBeforeNormalize
    end

    %% Constructor
    methods
        function this = TimeOutputAxesView(chart,varargin)
            arguments
                chart (1,1) controllib.chart.internal.foundation.OutputPlot
            end

            arguments (Repeating)
                varargin
            end
            this@controllib.chart.internal.foundation.MixInTimeUnit(chart.TimeUnit);
            this@controllib.chart.internal.view.axes.OutputAxesView(chart,varargin{:});
        end
    end

    %% Public methods
    methods
        function updateResponseView(this,response)
            arguments
                this (1,1) controllib.chart.internal.view.axes.TimeOutputAxesView
                response (1,1) controllib.chart.internal.foundation.BaseResponse ...
                    {controllib.chart.internal.view.axes.TimeOutputAxesView.mustBeRowResponse(response)}
            end
            idx = find(arrayfun(@(x) x.Response.Tag == response.Tag,this.ResponseViews),1);
            responseView = this.ResponseViews(idx);
            hasDifferentCharacteristics = ~isempty(setdiff(...
                union(responseView.CharacteristicTypes,response.CharacteristicTypes),...
                intersect(responseView.CharacteristicTypes,response.CharacteristicTypes)));
            isOldResponseReal = all(responseView.IsReal);
            isNewResponseReal = all(response.IsReal);
            if responseView.Response.NResponses ~= response.NResponses ||...
                    responseView.Response.NRows ~= response.NOutputs ||...
                    ~isequal(responseView.PlotRowIdx,response.ResponseData.PlotOutputIdx) || ...
                    responseView.IsDiscrete ~= response.IsDiscrete ||...
                    hasDifferentCharacteristics || ...
                    isOldResponseReal ~= isNewResponseReal
                delete(responseView);
                this.ResponseViews = this.ResponseViews(isvalid(this.ResponseViews));
                responseView = createResponseView(this,response);
                responseView.OutputNames = this.RowNames;
                createResponseDataTips(responseView);
                this.ResponseViews = [this.ResponseViews(1:idx-1); responseView; this.ResponseViews(idx:end)];
                parentResponseViews(this);
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
                this (1,1) controllib.chart.internal.view.axes.TimeOutputAxesView
            end
            Normalize = this.Normalize_I;
        end

        function set.Normalize(this,Normalize)
            arguments
                this (1,1) controllib.chart.internal.view.axes.TimeOutputAxesView
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
                this (1,1) controllib.chart.internal.view.axes.TimeOutputAxesView
            end
            ShowMagnitudeResponse = this.ShowMagnitude_I;
        end

        function set.ShowMagnitude(this,ShowMagnitudeResponse)
            arguments
                this (1,1) controllib.chart.internal.view.axes.TimeOutputAxesView
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
                this (1,1) controllib.chart.internal.view.axes.TimeOutputAxesView
            end
            ShowReal = this.ShowReal_I;
        end

        function set.ShowReal(this,ShowReal)
            arguments
                this (1,1) controllib.chart.internal.view.axes.TimeOutputAxesView
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
                this (1,1) controllib.chart.internal.view.axes.TimeOutputAxesView
            end
            ShowImaginary = this.ShowImaginary_I;
        end

        function set.ShowImaginary(this,ShowImaginary)
            arguments
                this (1,1) controllib.chart.internal.view.axes.TimeOutputAxesView
                ShowImaginary (1,1) matlab.lang.OnOffSwitchState
            end
            for k = 1:length(this.ResponseViews)
                this.ResponseViews(k).ShowImaginary = ShowImaginary;
            end
            this.ShowImaginary_I = ShowImaginary;
            updateFocus(this);            
        end
    end

    methods (Access = protected)
        function [timeFocus, amplitudeFocus] = updateFocus_(this,responses)
            arguments
                this (1,1) controllib.chart.internal.view.axes.TimeOutputAxesView
                responses (:,1) controllib.chart.internal.foundation.BaseResponse ...
                    {controllib.chart.internal.view.axes.TimeOutputAxesView.mustBeRowResponse(responses)}
            end
            % Compute focus
            [timeFocus, amplitudeFocus] = computeFocus(this,responses);
        end
        
        function cbTimeUnitChanged(this,conversionFcn)
            arguments
                this (1,1) controllib.chart.internal.view.axes.TimeOutputAxesView
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
                this (1,1) controllib.chart.internal.view.axes.TimeOutputAxesView
            end
            XLabel = this.XLabelWithoutUnits;
        end

        function setXLabelString(this,XLabel)
            arguments
                this (1,1) controllib.chart.internal.view.axes.TimeOutputAxesView
                XLabel (1,1) string
            end
            this.XLabelWithoutUnits = XLabel;
            this.AxesGrid.XLabel = this.XLabelWithoutUnits + " (" + this.TimeUnitLabel + ")";
        end

        function [timeFocus, amplitudeFocus] = computeFocus(this,responses)
            arguments
                this (1,1) controllib.chart.internal.view.axes.TimeOutputAxesView
                responses (:,1) controllib.chart.internal.foundation.BaseResponse ...
                    {controllib.chart.internal.view.axes.TimeOutputAxesView.mustBeRowResponse(responses)}
            end
            timeFocus = repmat({[NaN NaN]},this.NRows,1);
            amplitudeFocus = repmat({[NaN NaN]},this.NRows,1);
            if ~isempty(responses)
                data = [responses.ResponseData];
                [timeFocus_, amplitudeFocus_, timeUnit] = getCommonFocusForMultipleData(data,...
                    {responses.ArrayVisible},...
                    ShowMagnitude=this.ShowMagnitude,...
                    ShowReal=this.ShowReal,...
                    ShowImaginary=this.ShowImaginary);
                timeConversionFcn = getTimeUnitConversionFcn(this,timeUnit,this.TimeUnit);
                for ko = 1:length(timeFocus_)
                    timeFocus_{ko} = timeConversionFcn(timeFocus_{ko});
                end
                timeFocus(1:length(timeFocus_)) = timeFocus_;
                amplitudeFocus(1:length(amplitudeFocus_)) = amplitudeFocus_;
            end
        end
    end
end

