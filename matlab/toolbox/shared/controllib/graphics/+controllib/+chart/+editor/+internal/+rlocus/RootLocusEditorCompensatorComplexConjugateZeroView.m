classdef RootLocusEditorCompensatorComplexConjugateZeroView < controllib.chart.internal.view.characteristic.BaseCharacteristicView & ...
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
        ZeroMarkers
    end

    properties (Access=private)
        InteractionMode_I = "default"
    end

    %% Events
    events
        ZeroChanged
    end

    %% Constructor
    methods
        function this = RootLocusEditorCompensatorComplexConjugateZeroView(responseView,data)
            this@controllib.chart.internal.view.characteristic.BaseCharacteristicView(responseView,data);
            this@controllib.chart.internal.foundation.MixInFrequencyUnit(responseView.FrequencyUnit);
            this@controllib.chart.internal.foundation.MixInTimeUnit(responseView.TimeUnit);
        end
    end

    %% Get/Set
    methods
        % InteractionMode        
        function InteractionMode = get.InteractionMode(this)
            InteractionMode = this.InteractionMode_I;
        end

        function set.InteractionMode(this,InteractionMode)
            switch InteractionMode
                case "default"          
                    set(this.ZeroMarkers,HitTest='on');
                    weakThis = matlab.lang.WeakReference(this);
                    set(this.ZeroMarkers,ButtonDownFcn=@(es,ed) moveZero(weakThis.Handle,es,'init'));
                case "removepz"
                    set(this.ZeroMarkers,HitTest='on');
                    weakThis = matlab.lang.WeakReference(this);
                    set(this.ZeroMarkers,ButtonDownFcn=@(es,ed) removeZero(weakThis.Handle,es));
                otherwise
                    set(this.ZeroMarkers,HitTest='off');
            end
            this.InteractionMode_I = InteractionMode;
        end
    end

    %% Protected methods
    methods (Access = protected)
        function build_(this)
            this.ZeroMarkers = createGraphicsObjects(this,"scatter",1,1,this.Response.NResponses,Tag='RootLocusTunableCCZeroScatter');
            this.disableDataTipInteraction(this.ZeroMarkers);
            weakThis = matlab.lang.WeakReference(this);
            switch this.InteractionMode
                case "default"          
                    set(this.ZeroMarkers,ButtonDownFcn=@(es,ed) moveZero(weakThis.Handle,es,'init'));
                case "removepz"
                    set(this.ZeroMarkers,ButtonDownFcn=@(es,ed) removeZero(weakThis.Handle,es));
                otherwise
                    set(this.ZeroMarkers,ButtonDownFcn=@(es,ed) moveZero(weakThis.Handle,es,'init'));
                    set(this.ZeroMarkers,HitTest='off');
            end
        end

        function updateData(this,~,~,ka)
            conversionFcn = getTimeUnitConversionFcn(this,this.TimeUnit,this.Response.TimeUnit);
            pzData = this.Response.ResponseData.RootLocusCompensatorComplexConjugateZeros;
            L = pzData.Locations{1,1};
            this.ZeroMarkers(1,1,ka).XData = 1./conversionFcn(1./real(L));
            this.ZeroMarkers(1,1,ka).YData = 1./conversionFcn(1./imag(L));
        end

        function cbTimeUnitChanged(this,conversionFcn)
            if this.IsInitialized
                for ka = 1:this.Response.NResponses
                    this.ZeroMarkers(1,1,ka).XData = 1./(conversionFcn(1./this.ZeroMarkers(1,1,ka).XData));
                    this.ZeroMarkers(1,1,ka).YData = 1./(conversionFcn(1./this.ZeroMarkers(1,1,ka).YData));
                end
            end
        end

        function c = getMarkerObjects_(this,~,~,ka)
            c = this.ZeroMarkers(1,1,ka);
        end

        function updateStyle_(this,~,~,~,ka)
            if this.IsInitialized
                set(this.ZeroMarkers(1,1,ka),Marker='o',MarkerFaceColor='none');
                controllib.plot.internal.utils.setColorProperty(this.ZeroMarkers(1,1,ka),...
                    "MarkerEdgeColor","--mw-graphics-colorOrder-10-primary");
            end
        end

        function removeZero(this,source)
            arguments
                this (1,1) controllib.chart.editor.internal.rlocus.RootLocusEditorCompensatorComplexConjugateZeroView
                source (1,1) matlab.graphics.primitive.Data
            end
            ax = ancestor(source,'axes');
            fig = ancestor(ax,'figure');
            if strcmp(fig.SelectionType,"normal")
                response = getResponse(this.Response);
                zeroData = this.Response.ResponseData.RootLocusCompensatorComplexConjugateZeros;
                selectedPoint = ax.CurrentPoint(1,1:2)';
                diff = selectedPoint-[source.XData;source.YData];
                dist = diff(1,:).^2+diff(2,:).^2;
                [~,idx] = min(dist);
                zc = find(response.Compensator.Z{1,1} ~= real(response.Compensator.Z{1,1}));
                zidx = zc(idx);
                zcidx = zc(zeroData.PairIdx{1,1}(idx));
                zero = response.Compensator.Z{1,1}(zidx);
                response.Compensator.Z{1,1}([zidx zcidx]) = [];
                if this.Response.IsDiscrete
                    response.Compensator.K(1,1) = response.Compensator.K(1,1)*abs((1-zero))^2;
                else
                    response.Compensator.K(1,1) = response.Compensator.K(1,1)*abs(zero)^2;
                end
                Data = struct('OldValue',zero,'NewValue',[],'Status','Finished','Property','Z');
                ed = controllib.chart.internal.utils.GenericEventData(Data);
                notify(this,'ZeroChanged',ed)
            end
        end

        function moveZero(this,source,action,optionalInputs)
            arguments
                this (1,1) controllib.chart.editor.internal.rlocus.RootLocusEditorCompensatorComplexConjugateZeroView
                source (1,1) matlab.graphics.primitive.Data
                action (1,1) string {mustBeMember(action,["init";"move";"finish"])}
                optionalInputs.StartLocation = []
                optionalInputs.EndLocation = []
            end
            persistent WML WBMClear location ptr idx zidx zcidx;
            ax = ancestor(source,'axes');
            fig = ancestor(ax,'figure');
            if strcmp(fig.SelectionType,"normal")
                response = getResponse(this.Response);
                zeroData = this.Response.ResponseData.RootLocusCompensatorComplexConjugateZeros;
                switch action
                    case 'init'
                        optionalInputsCell = namedargs2cell(optionalInputs);
                        L1 = addlistener(fig,'WindowMouseMotion',@(es,ed) moveZero(this,source,'move',optionalInputsCell{:}));
                        L2 = addlistener(fig,'WindowMouseRelease',@(es,ed) moveZero(this,source,'finish',optionalInputsCell{:}));
                        WML = [L1;L2];
                        WBMClear = isempty(fig.WindowButtonMotionFcn);
                        if WBMClear
                            fig.WindowButtonMotionFcn = @(es,ed) []; %needs func to update CurrentPoint
                        end
                        ptr = fig.Pointer;
                        fig.Pointer = "fleur";
                        if isempty(optionalInputs.StartLocation)
                            selectedPoint = ax.CurrentPoint(1,1:2)';
                        else
                            selectedPoint = optionalInputs.StartLocation';
                        end
                        diff = selectedPoint-[source.XData;source.YData];
                        dist = diff(1,:).^2+diff(2,:).^2;
                        [~,idx] = min(dist);
                        zc = find(response.Compensator.Z{1,1} ~= real(response.Compensator.Z{1,1}));
                        zidx = zc(idx);
                        zcidx = zc(zeroData.PairIdx{1,1}(idx));
                        location = zeroData.Locations{1,1}(idx);
                        Data = struct('OldValue',location,'NewValue',location,'Status','Init','Property','Z');
                        ed = controllib.chart.internal.utils.GenericEventData(Data);
                        notify(this,'ZeroChanged',ed)
                    case 'move'
                        if isempty(optionalInputs.EndLocation)
                            newPoint = ax.CurrentPoint(1,1:2);
                        else
                            newPoint = optionalInputs.EndLocation;
                        end
                        oldLocation = location;
                        timeConversionFcn = getTimeUnitConversionFcn(this,this.Response.TimeUnit,this.TimeUnit);
                        location = 1/timeConversionFcn(1/(newPoint(1)+newPoint(2)*1j));
                        response.Compensator.Z{1,1}([zidx zcidx]) = [location conj(location)];
                        if this.Response.IsDiscrete
                            response.Compensator.K(1,1) = abs((1-oldLocation)/(1-location))^2*response.Compensator.K(1,1);
                        else
                            response.Compensator.K(1,1) = abs(oldLocation/location)^2*response.Compensator.K(1,1);
                        end
                        Data = struct('OldValue',oldLocation,'NewValue',location,'Status','InProgress','Property','Z');
                        ed = controllib.chart.internal.utils.GenericEventData(Data);
                        notify(this,'ZeroChanged',ed)
                    case 'finish'
                        delete(WML);
                        if WBMClear
                            fig.WindowButtonMotionFcn = [];
                        end
                        fig.Pointer = ptr;
                        Data = struct('OldValue',location,'NewValue',location,'Status','Finished','Property','Z');
                        ed = controllib.chart.internal.utils.GenericEventData(Data);
                        notify(this,'ZeroChanged',ed)
                end
            end
        end
    end

    %% Hidden methods
    methods (Hidden)
        function qeDrag(this,startLoc,endLoc)
            arguments
                this (1,1) controllib.chart.editor.internal.rlocus.RootLocusEditorCompensatorComplexConjugateZeroView
                startLoc (1,2) double
                endLoc (1,2) double
            end
            source = this.ZeroMarkers(1,1,this.Response.NominalIndex);
            moveZero(this,source,'init',StartLocation=startLoc,EndLocation=endLoc);
            moveZero(this,source,'move',StartLocation=startLoc,EndLocation=endLoc);
            moveZero(this,source,'finish',StartLocation=startLoc,EndLocation=endLoc);
        end
    end
end