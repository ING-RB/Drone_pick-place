classdef RootLocusEditorCompensatorGainView < controllib.chart.internal.view.characteristic.BaseCharacteristicView & ...
        controllib.chart.internal.foundation.MixInFrequencyUnit & ...
        controllib.chart.internal.foundation.MixInTimeUnit
    % this = controllib.chart.internal.view.characteristic.TimePeakResponseView(data)
    %
    % Copyright 2021 The MathWorks, Inc.

    %% Properties
    properties (Dependent,AbortSet,SetObservable)
        InteractionMode
    end

    properties (SetAccess = protected)
        GainMarkers
    end

    properties (Dependent,SetAccess=private)
        NLines
    end

    properties (Access=private)
        InteractionMode_I = "default"
    end

    %% Events
    events
        GainChanged
    end
    
    %% Constructor
    methods
        function this = RootLocusEditorCompensatorGainView(responseView,data)
            this@controllib.chart.internal.view.characteristic.BaseCharacteristicView(responseView,data);
            this@controllib.chart.internal.foundation.MixInFrequencyUnit(responseView.FrequencyUnit);
            this@controllib.chart.internal.foundation.MixInTimeUnit(responseView.TimeUnit);
        end
    end

    %% Get/Set
    methods
        % NLines
        function NLines = get.NLines(this)
            NLines = this.ResponseView.NLines;
        end

        % InteractionMode        
        function InteractionMode = get.InteractionMode(this)
            InteractionMode = this.InteractionMode_I;
        end

        function set.InteractionMode(this,InteractionMode)
            switch InteractionMode
                case "default"          
                    set(this.GainMarkers,HitTest='on');
                otherwise
                    set(this.GainMarkers,HitTest='off');
            end
            this.InteractionMode_I = InteractionMode;
        end
    end
    
    %% Protected methods
    methods (Access = protected)
        function build_(this)
            % Gain markers
            this.GainMarkers = createGraphicsObjects(this,"scatter",this.NLines,...
                1,this.Response.NResponses,Tag='RootLocusTunableGainScatter');
            this.disableDataTipInteraction(this.GainMarkers);
            weakThis = matlab.lang.WeakReference(this);
            set(this.GainMarkers,ButtonDownFcn=@(es,ed) moveGain(weakThis.Handle,es,'init'));
            switch this.InteractionMode
                case "default"          
                    set(this.GainMarkers,HitTest='on');
                otherwise
                    set(this.GainMarkers,HitTest='off');
            end
        end

        function updateData(this,~,~,ka)
            K = abs(this.Response.ResponseData.RootLocusCompensatorGain.Value);
            responseObjects = getResponseObjects(this.ResponseView,1,1,ka);
            for k = 1:this.NLines
                gains = this.Response.ResponseData.SystemGains{ka}(:,k)';
                % Map Inf gain to big number
                gains(isinf(gains) & gains > 0) = realmax;
                gains(isinf(gains) & gains < 0) = -realmax;
                [~,kidx] = min(abs(gains-K));
                idx = [kidx-1 kidx kidx+1];
                if kidx == 1
                    idx = idx(2:end);
                end
                if kidx == length(gains)
                    idx = idx(1:end-1);
                end
                locusLine = responseObjects{1}(2+k);
                if isscalar(idx)
                    x = locusLine.XData(idx);
                    y = locusLine.YData(idx);
                else
                    x = this.scaledInterp1(gains(idx),locusLine.XData(idx),K);
                    y = this.scaledInterp1(gains(idx),locusLine.YData(idx),K);
                end
                this.GainMarkers(k,1,ka).XData = x;
                this.GainMarkers(k,1,ka).YData = y;
                this.GainMarkers(k,1,ka).UserData.LocusLine = locusLine;
            end
        end

        function cbTimeUnitChanged(this,conversionFcn)
            if this.IsInitialized
                for ka = 1:this.Response.NResponses
                    for k = 1:this.NLines
                        this.GainMarkers(k,1,ka).XData = 1./(conversionFcn(1./this.GainMarkers(k,1,ka).XData));
                        this.GainMarkers(k,1,ka).YData = 1./(conversionFcn(1./this.GainMarkers(k,1,ka).YData));
                    end
                end
            end
        end

        function c = getMarkerObjects_(this,~,~,ka)
            c = reshape(this.GainMarkers(:,1,ka),1,1,this.NLines);
        end

        function updateStyle_(this,~,~,~,ka)
            if this.IsInitialized
                set(this.GainMarkers(:,1,ka),Marker='square');
                controllib.plot.internal.utils.setColorProperty(this.GainMarkers(:,1,ka),...
                    ["MarkerFaceColor";"MarkerEdgeColor"],"--mw-graphics-colorOrder-9-primary");
            end
        end

        function moveGain(this,source,action,optionalInputs)
            arguments
                this (1,1) controllib.chart.editor.internal.rlocus.RootLocusEditorCompensatorGainView
                source (1,1) matlab.graphics.primitive.Data
                action (1,1) string {mustBeMember(action,["init";"move";"finish"])}
                optionalInputs.StartLocation = []
                optionalInputs.EndLocation = []
            end

            persistent WML WBMClear gain ptr;

            ax = ancestor(source,'axes');
            fig = ancestor(ax,'figure');
            if strcmp(fig.SelectionType,"normal")
                response = getResponse(this.Response);
                switch action
                    case 'init'
                        optionalInputsCell = namedargs2cell(optionalInputs);
                        L1 = addlistener(fig,'WindowMouseMotion',@(es,ed) moveGain(this,source,'move',optionalInputsCell{:}));
                        L2 = addlistener(fig,'WindowMouseRelease',@(es,ed) moveGain(this,source,'finish',optionalInputsCell{:}));                        
                        WML = [L1;L2];
                        WBMClear = isempty(fig.WindowButtonMotionFcn);
                        if WBMClear
                            fig.WindowButtonMotionFcn = @(es,ed) []; %needs func to update CurrentPoint
                        end
                        ptr = fig.Pointer;
                        fig.Pointer = "fleur";
                        gain = response.Compensator.K;
                        Data = struct('OldValue',gain,'NewValue',gain,'Status','Init','Property','K');
                        ed = controllib.chart.internal.utils.GenericEventData(Data);
                        notify(this,'GainChanged',ed)
                    case 'move'
                        if isempty(optionalInputs.EndLocation)
                            newPoint = ax.CurrentPoint(1,1:2);
                        else
                            newPoint = optionalInputs.EndLocation;
                        end
                        oldGain = gain;
                        gain = computeNewGain(this,source,newPoint)*sign(gain);
                        response.Compensator.K = gain;
                        Data = struct('OldValue',oldGain,'NewValue',gain,'Status','InProgress','Property','K');
                        ed = controllib.chart.internal.utils.GenericEventData(Data);
                        notify(this,'GainChanged',ed)
                    case 'finish'
                        delete(WML);
                        if WBMClear
                            fig.WindowButtonMotionFcn = [];
                        end
                        fig.Pointer = ptr;
                        Data = struct('OldValue',gain,'NewValue',gain,'Status','Finished','Property','K');
                        ed = controllib.chart.internal.utils.GenericEventData(Data);
                        notify(this,'GainChanged',ed)
                end
            end
        end

        function newGain = computeNewGain(this,source,newPoint)
            locusLine = source.UserData.LocusLine;
            xData = locusLine.XData;
            yData = locusLine.YData;
            gains = locusLine.UserData.SystemGains;
            % Account for inf and zero gains
            gains(isinf(gains) & gains > 0) = realmax;
            gains(isinf(gains) & gains < 0) = -realmax;
            gains(gains==0) = realmin;
            ax = source.Parent;
            newGain = this.scaledProject2(xData,yData,gains,newPoint,ax.XLim,ax.YLim,ax.XScale,ax.YScale);
        end
    end

    %% Hidden methods
    methods (Hidden)
        function qeDrag(this,startLoc,endLoc)
            arguments
                this (1,1) controllib.chart.editor.internal.rlocus.RootLocusEditorCompensatorGainView
                startLoc (1,2) double
                endLoc (1,2) double
            end
            locusGains = this.GainMarkers(:,1,this.Response.NominalIndex);
            locations = zeros(2,length(locusGains));
            for ii = 1:length(locusGains)
                locations(1,ii) = locusGains(ii).XData;
                locations(2,ii) = locusGains(ii).XData;
            end
            diff = startLoc'-locations;
            dist = diff(1,:).^2+diff(2,:).^2;
            [~,ind] = min(dist);
            source = locusGains(ind);
            moveGain(this,source,'init',StartLocation=startLoc,EndLocation=endLoc);
            moveGain(this,source,'move',StartLocation=startLoc,EndLocation=endLoc);
            moveGain(this,source,'finish',StartLocation=startLoc,EndLocation=endLoc);
        end
    end
end