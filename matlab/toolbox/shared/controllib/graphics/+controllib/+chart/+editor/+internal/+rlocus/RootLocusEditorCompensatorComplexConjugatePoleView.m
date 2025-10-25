classdef RootLocusEditorCompensatorComplexConjugatePoleView < controllib.chart.internal.view.characteristic.BaseCharacteristicView & ...
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
        PoleMarkers
    end

    properties (Access=private)
        InteractionMode_I = "default"
    end

    %% Events
    events
        PoleChanged
    end

    %% Constructor
    methods
        function this = RootLocusEditorCompensatorComplexConjugatePoleView(responseView,data)
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
                    set(this.PoleMarkers,HitTest='on');
                    weakThis = matlab.lang.WeakReference(this);
                    set(this.PoleMarkers,ButtonDownFcn=@(es,ed) movePole(weakThis.Handle,es,'init'));
                case "removepz"
                    set(this.PoleMarkers,HitTest='on');
                    weakThis = matlab.lang.WeakReference(this);
                    set(this.PoleMarkers,ButtonDownFcn=@(es,ed) removePole(weakThis.Handle,es));
                otherwise
                    set(this.PoleMarkers,HitTest='off');
            end
            this.InteractionMode_I = InteractionMode;
        end
    end

    %% Protected methods
    methods (Access = protected)
        function build_(this)
            this.PoleMarkers = createGraphicsObjects(this,"scatter",1,1,this.Response.NResponses,Tag='RootLocusTunableCCPoleScatter');
            this.disableDataTipInteraction(this.PoleMarkers);
            weakThis = matlab.lang.WeakReference(this);
            switch this.InteractionMode
                case "default"          
                    set(this.PoleMarkers,ButtonDownFcn=@(es,ed) movePole(weakThis.Handle,es,'init'));
                case "removepz"
                    set(this.PoleMarkers,ButtonDownFcn=@(es,ed) removePole(weakThis.Handle,es));
                otherwise
                    set(this.PoleMarkers,ButtonDownFcn=@(es,ed) movePole(weakThis.Handle,es,'init'));
                    set(this.PoleMarkers,HitTest='off');
            end
        end

        function updateData(this,~,~,ka)
            conversionFcn = getTimeUnitConversionFcn(this,this.TimeUnit,this.Response.TimeUnit);
            pzData = this.Response.ResponseData.RootLocusCompensatorComplexConjugatePoles;
            L = pzData.Locations{1,1};
            this.PoleMarkers(1,1,ka).XData = 1./conversionFcn(1./real(L));
            this.PoleMarkers(1,1,ka).YData = 1./conversionFcn(1./imag(L));
        end

        function cbTimeUnitChanged(this,conversionFcn)
            if this.IsInitialized
                for ka = 1:this.Response.NResponses
                    this.PoleMarkers(1,1,ka).XData = 1./(conversionFcn(1./this.PoleMarkers(1,1,ka).XData));
                    this.PoleMarkers(1,1,ka).YData = 1./(conversionFcn(1./this.PoleMarkers(1,1,ka).YData));
                end
            end
        end

        function c = getMarkerObjects_(this,~,~,ka)
            c = this.PoleMarkers(1,1,ka);
        end

        function updateStyle_(this,~,~,~,ka)
            if this.IsInitialized
                set(this.PoleMarkers(1,1,ka),Marker='x');
                controllib.plot.internal.utils.setColorProperty(this.PoleMarkers(1,1,ka),...
                    "MarkerEdgeColor","--mw-graphics-colorOrder-10-primary");
            end
        end

        function removePole(this,source)
            arguments
                this (1,1) controllib.chart.editor.internal.rlocus.RootLocusEditorCompensatorComplexConjugatePoleView
                source (1,1) matlab.graphics.primitive.Data
            end
            ax = ancestor(source,'axes');
            fig = ancestor(ax,'figure');
            if strcmp(fig.SelectionType,"normal")
                response = getResponse(this.Response);
                poleData = this.Response.ResponseData.RootLocusCompensatorComplexConjugatePoles;
                selectedPoint = ax.CurrentPoint(1,1:2)';
                diff = selectedPoint-[source.XData;source.YData];
                dist = diff(1,:).^2+diff(2,:).^2;
                [~,idx] = min(dist);
                pc = find(response.Compensator.P{1,1} ~= real(response.Compensator.P{1,1}));
                pidx = pc(idx);
                pcidx = pc(poleData.PairIdx{1,1}(idx));
                pole = response.Compensator.P{1,1}(pidx);
                response.Compensator.P{1,1}([pidx pcidx]) = [];
                if this.Response.IsDiscrete
                    response.Compensator.K(1,1) = response.Compensator.K(1,1)/abs((1-pole))^2;
                else
                    response.Compensator.K(1,1) = response.Compensator.K(1,1)/abs(pole)^2;
                end
                Data = struct('OldValue',pole,'NewValue',[],'Status','Finished','Property','P');
                ed = controllib.chart.internal.utils.GenericEventData(Data);
                notify(this,'PoleChanged',ed)
            end
        end

        function movePole(this,source,action,optionalInputs)
            arguments
                this (1,1) controllib.chart.editor.internal.rlocus.RootLocusEditorCompensatorComplexConjugatePoleView
                source (1,1) matlab.graphics.primitive.Data
                action (1,1) string {mustBeMember(action,["init";"move";"finish"])}
                optionalInputs.StartLocation = []
                optionalInputs.EndLocation = []
            end
            persistent WML WBMClear location ptr idx pidx pcidx;
            ax = ancestor(source,'axes');
            fig = ancestor(ax,'figure');
            if strcmp(fig.SelectionType,"normal")
                response = getResponse(this.Response);
                poleData = this.Response.ResponseData.RootLocusCompensatorComplexConjugatePoles;
                switch action
                    case 'init'
                        optionalInputsCell = namedargs2cell(optionalInputs);
                        L1 = addlistener(fig,'WindowMouseMotion',@(es,ed) movePole(this,source,'move',optionalInputsCell{:}));
                        L2 = addlistener(fig,'WindowMouseRelease',@(es,ed) movePole(this,source,'finish',optionalInputsCell{:}));                        
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
                        pc = find(response.Compensator.P{1,1} ~= real(response.Compensator.P{1,1}));
                        pidx = pc(idx);
                        pcidx = pc(poleData.PairIdx{1,1}(idx));
                        location = poleData.Locations{1,1}(idx);
                        Data = struct('OldValue',location,'NewValue',location,'Status','Init','Property','P');
                        ed = controllib.chart.internal.utils.GenericEventData(Data);
                        notify(this,'PoleChanged',ed)
                    case 'move'
                        if isempty(optionalInputs.EndLocation)
                            newPoint = ax.CurrentPoint(1,1:2);
                        else
                            newPoint = optionalInputs.EndLocation;
                        end
                        oldLocation = location;
                        timeConversionFcn = getTimeUnitConversionFcn(this,this.Response.TimeUnit,this.TimeUnit);
                        location = 1/timeConversionFcn(1/(newPoint(1)+newPoint(2)*1j));
                        response.Compensator.P{1,1}([pidx pcidx]) = [location conj(location)];
                        if this.Response.IsDiscrete
                            response.Compensator.K(1,1) = abs((1-location)/(1-oldLocation))^2*response.Compensator.K(1,1);
                        else
                            response.Compensator.K(1,1) = abs(location/oldLocation)^2*response.Compensator.K(1,1);
                        end
                        Data = struct('OldValue',oldLocation,'NewValue',location,'Status','InProgress','Property','P');
                        ed = controllib.chart.internal.utils.GenericEventData(Data);
                        notify(this,'PoleChanged',ed)
                    case 'finish'
                        delete(WML);
                        if WBMClear
                            fig.WindowButtonMotionFcn = [];
                        end
                        fig.Pointer = ptr;
                        Data = struct('OldValue',location,'NewValue',location,'Status','Finished','Property','P');
                        ed = controllib.chart.internal.utils.GenericEventData(Data);
                        notify(this,'PoleChanged',ed)
                end
            end
        end
    end

    %% Hidden methods
    methods (Hidden)
        function qeDrag(this,startLoc,endLoc)
            arguments
                this (1,1) controllib.chart.editor.internal.rlocus.RootLocusEditorCompensatorComplexConjugatePoleView
                startLoc (1,2) double
                endLoc (1,2) double
            end
            source = this.PoleMarkers(1,1,this.Response.NominalIndex);
            movePole(this,source,'init',StartLocation=startLoc,EndLocation=endLoc);
            movePole(this,source,'move',StartLocation=startLoc,EndLocation=endLoc);
            movePole(this,source,'finish',StartLocation=startLoc,EndLocation=endLoc);
        end
    end
end