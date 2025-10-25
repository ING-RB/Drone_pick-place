classdef PassiveAxesView < controllib.chart.internal.view.axes.SectorAxesView
    % SIGMAVIEW     Construct view to manage axes and responses for SIGMAPLOT     

    % Copyright 2023 The MathWorks, Inc.
        
    %% Constructor
    methods
        function this = PassiveAxesView(varargin)
            this@controllib.chart.internal.view.axes.SectorAxesView(varargin{:});
        end
    end    
    
    %% Public methods
    methods
        function updateResponseView(this,response)
            arguments
                this (1,1) controllib.chart.internal.view.axes.PassiveAxesView
                response (1,1) controllib.chart.response.PassiveResponse
            end
            updateResponseView@controllib.chart.internal.view.axes.BaseAxesView(this,response);
            idx = find(arrayfun(@(x) x.Response.Tag == response.Tag,this.ResponseViews),1);
            responseView = this.ResponseViews(idx);
            hasDifferentCharacteristics = ~isempty(setdiff(...
                union(responseView.CharacteristicTypes,response.CharacteristicTypes),...
                intersect(responseView.CharacteristicTypes,response.CharacteristicTypes)));
            hasDifferentNumLines = responseView.NLines ~= size(response.ResponseData.RelativeIndex{1},1);
            if responseView.Response.NResponses ~= response.NResponses ||...
                    hasDifferentCharacteristics || hasDifferentNumLines
                delete(responseView);
                this.ResponseViews = this.ResponseViews(isvalid(this.ResponseViews));
                responseView = createResponseView(this,response);
                createResponseDataTips(responseView);
                this.ResponseViews = [this.ResponseViews(1:idx-1); responseView; this.ResponseViews(idx:end)];
                parentResponseViews(this);
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
                this (1,1) controllib.chart.internal.view.axes.PassiveAxesView
                response (1,1) controllib.chart.response.PassiveResponse
            end
            responseView = controllib.chart.internal.view.wave.PassiveResponseView(response);
            responseView.FrequencyUnit = this.FrequencyUnit;
            responseView.MagnitudeUnit = this.MagnitudeUnit;
            responseView.FrequencyScale = this.FrequencyScale;
        end

        function postParentResponseView(this,responseView)
            arguments
                this (1,1) controllib.chart.internal.view.axes.PassiveAxesView
                responseView (1,1) controllib.chart.internal.view.wave.PassiveResponseView
            end
            ax = getAxes(this);
            aspectRatio = ax(1).PlotBoxAspectRatio(1:2);
            updateArrows(responseView,AspectRatio=aspectRatio);
        end
        
        function [frequencyFocus, relativeIndexFocus] = computeFocus(this,responses)
            arguments
                this (1,1) controllib.chart.internal.view.axes.PassiveAxesView
                responses (:,1) controllib.chart.response.PassiveResponse
            end
            frequencyFocus = {[NaN NaN]};
            relativeIndexFocus = {[NaN NaN]};
            if ~isempty(responses)
                data = [responses.ResponseData];
                [frequencyFocus,frequencyUnit] = getCommonFrequencyFocus(data,this.FrequencyScale,{responses.ArrayVisible});
                if strcmp(this.MagnitudeUnit,"dB")
                    indexScale = "log";
                else
                    indexScale = this.IndexScale;
                end
                [relativeIndexFocus,magnitudeUnit] = getCommonIndexFocus(data,frequencyFocus,indexScale,{responses.ArrayVisible});
                frequencyConversionFcn = getFrequencyUnitConversionFcn(this,frequencyUnit,this.FrequencyUnit);
                frequencyFocus{1} = frequencyConversionFcn(frequencyFocus{1});
                magnitudeConversionFcn = getMagnitudeUnitConversionFcn(this,magnitudeUnit,this.MagnitudeUnit);
                relativeIndexFocus{1} = magnitudeConversionFcn(relativeIndexFocus{1});
            end
        end
    end
end

