classdef RootLocusAxesView < controllib.chart.internal.view.axes.PZAxesView

    % Copyright 2021-2023 The MathWorks, Inc.

    %% Constructor
    methods
        function this = RootLocusAxesView(varargin)
            this@controllib.chart.internal.view.axes.PZAxesView(varargin{:});
        end
    end

    %% Public methods
    methods
        function updateResponseView(this,response)
            arguments
                this (1,1) controllib.chart.internal.view.axes.RootLocusAxesView
                response (:,1) controllib.chart.response.RootLocusResponse
            end
            idx = find(arrayfun(@(x) x.Response.Tag == response.Tag,this.ResponseViews),1);
            responseView = this.ResponseViews(idx);
            hasDifferentCharacteristics = ~isempty(setdiff(...
                union(responseView.CharacteristicTypes,response.CharacteristicTypes),...
                intersect(responseView.CharacteristicTypes,response.CharacteristicTypes)));
            hasDifferentNumLines = responseView.NLines ~= size(response.ResponseData.Roots{1},2);
            if responseView.Response.NResponses ~= response.NResponses ||...
                    hasDifferentCharacteristics || hasDifferentNumLines
                delete(responseView);
                this.ResponseViews = this.ResponseViews(isvalid(this.ResponseViews));
                responseView = createResponseView(this,response);
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
                this (1,1) controllib.chart.internal.view.axes.RootLocusAxesView
                response (1,1) controllib.chart.response.RootLocusResponse
            end
            responseView = controllib.chart.internal.view.wave.RootLocusResponseView(response);
            responseView.TimeUnit = this.TimeUnit;
        end

        function [realAxisFocus, imaginaryAxisFocus] = computeFocus(this,responses)
            arguments
                this (1,1) controllib.chart.internal.view.axes.RootLocusAxesView
                responses (:,1) controllib.chart.response.RootLocusResponse
            end
            realAxisFocus = {[NaN NaN]};
            imaginaryAxisFocus = {[NaN NaN]};
            if ~isempty(responses)
                data = [responses.ResponseData];
                [realAxisFocus, imaginaryAxisFocus, timeUnit] = getCommonFocusForMultipleData(data,{responses.ArrayVisible});
            end
            timeConversionFcn = getTimeUnitConversionFcn(this,timeUnit,this.TimeUnit);
            realAxisFocus{1} = timeConversionFcn(realAxisFocus{1});
            imaginaryAxisFocus{1} = timeConversionFcn(imaginaryAxisFocus{1});
        end
    end
end