classdef BodeEditorCompensatorComplexConjugatePoleView < controllib.chart.internal.view.characteristic.FrequencyCharacteristicView & ...
                                               controllib.chart.internal.foundation.MixInMagnitudeUnit & ...
                                              controllib.chart.internal.foundation.MixInPhaseUnit
    % this = controllib.chart.internal.view.characteristic.TimePeakResponseView(data)
    %
    % Copyright 2021 The MathWorks, Inc.
    
    %% Properties
    properties (Dependent,AbortSet,SetObservable)
        InteractionMode
    end

    properties (SetAccess = protected)
        MagnitudePoleMarkers
        PhasePoleMarkers
        StabilityYLines
    end

    properties (Access=private)
        DummyYLines
        InteractionMode_I = "default"
    end

    %% Events
    events
        PoleChanged
    end
    
    %% Constructor
    methods
        function this = BodeEditorCompensatorComplexConjugatePoleView(responseView,data)
            this@controllib.chart.internal.view.characteristic.FrequencyCharacteristicView(responseView,data);
            this@controllib.chart.internal.foundation.MixInMagnitudeUnit(responseView.MagnitudeUnit);
            this@controllib.chart.internal.foundation.MixInPhaseUnit(responseView.PhaseUnit);
            this.ResponseLineIdx = [1 2];
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
                    set(this.MagnitudePoleMarkers,HitTest='on');
                    set(this.PhasePoleMarkers,HitTest='on');
                    weakThis = matlab.lang.WeakReference(this);
                    set(this.MagnitudePoleMarkers,ButtonDownFcn=@(es,ed) movePole(weakThis.Handle,es,'init',true));
                    set(this.PhasePoleMarkers,ButtonDownFcn=@(es,ed) movePole(weakThis.Handle,es,'init',false));
                case "removepz"
                    set(this.MagnitudePoleMarkers,HitTest='on');
                    set(this.PhasePoleMarkers,HitTest='on');
                    weakThis = matlab.lang.WeakReference(this);
                    set(this.MagnitudePoleMarkers,ButtonDownFcn=@(es,ed) removePole(weakThis.Handle,es,true));
                    set(this.PhasePoleMarkers,ButtonDownFcn=@(es,ed) removePole(weakThis.Handle,es,false));
                otherwise
                    set(this.MagnitudePoleMarkers,HitTest='off');
                    set(this.PhasePoleMarkers,HitTest='off');
            end
            this.InteractionMode_I = InteractionMode;
        end
    end

    %% Protected methods
    methods (Access = protected)
        function build_(this)
            this.MagnitudePoleMarkers = createGraphicsObjects(this,"scatter",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,Tag='BodeMagnitudeTunableCCPoleScatter');
            this.PhasePoleMarkers = createGraphicsObjects(this,"scatter",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,Tag='BodePhaseTunableCCPoleScatter');
            this.StabilityYLines = createGraphicsObjects(this,"constantLine",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,Tag='BodePhaseTunableCCPoleStabilityLine',HitTest='off');
            this.DummyYLines = createGraphicsObjects(this,"line",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses);
            weakThis = matlab.lang.WeakReference(this);
            set(this.MagnitudePoleMarkers,ButtonDownFcn=@(es,ed) movePole(weakThis.Handle,es,'init',true));
            set(this.PhasePoleMarkers,ButtonDownFcn=@(es,ed) movePole(weakThis.Handle,es,'init',false));
            this.disableDataTipInteraction(this.MagnitudePoleMarkers);
            this.disableDataTipInteraction(this.PhasePoleMarkers);
            set(this.StabilityYLines,InterceptAxis='y',LineStyle='--');
            controllib.plot.internal.utils.setColorProperty(this.StabilityYLines,...
                "Color","--mw-graphics-colorOrder-10-primary");
        end

        function updateData(this,ko,ki,ka)
            pzData = this.Response.ResponseData.BodeCompensatorComplexConjugatePoles;

            responseObjects = getResponseObjects(this.ResponseView,ko,ki,ka);
            magResponseLine = responseObjects{1}(1);
            phaseResponseLine = responseObjects{1}(2);
            frequencyConversionFcn = getFrequencyUnitConversionFcn(this,this.Response.FrequencyUnit,this.FrequencyUnit);
            f = frequencyConversionFcn(pzData.Frequencies{ko,ki});
            if isempty(f)
                f = NaN;
            end
            ax = magResponseLine.Parent;
            if isempty(ax)
                freqScale = "log";
                magScale = "linear";
            else
                freqScale = ax.XScale;
                magScale = ax.YScale;
            end
            mag = this.scaledInterp1(magResponseLine.XData,magResponseLine.YData,f,freqScale,magScale);
            phase = this.scaledInterp1(phaseResponseLine.XData,phaseResponseLine.YData,f,freqScale,"linear");
            this.MagnitudePoleMarkers(ko,ki,ka).XData = f;
            this.MagnitudePoleMarkers(ko,ki,ka).YData = mag;
            this.PhasePoleMarkers(ko,ki,ka).XData = f;
            this.PhasePoleMarkers(ko,ki,ka).YData = phase;
        end

        function cbFrequencyUnitChanged(this,conversionFcn)
            if this.IsInitialized
                for ko = 1:this.Response.NRows
                    for ki = 1:this.Response.NColumns
                        for ka = 1:this.Response.NResponses
                            this.MagnitudePoleMarkers(ko,ki,ka).XData = conversionFcn(this.MagnitudePoleMarkers(ko,ki,ka).XData);
                            this.PhasePoleMarkers(ko,ki,ka).XData = conversionFcn(this.PhasePoleMarkers(ko,ki,ka).XData);
                        end
                    end
                end
            end
        end

        function cbMagnitudeUnitChanged(this,conversionFcn)
            if this.IsInitialized
                for ko = 1:this.Response.NRows
                    for ki = 1:this.Response.NColumns
                        for ka = 1:this.Response.NResponses
                            this.MagnitudePoleMarkers(ko,ki,ka).YData = conversionFcn(this.MagnitudePoleMarkers(ko,ki,ka).YData);
                        end
                    end
                end
            end
        end

        function cbPhaseUnitChanged(this,conversionFcn)
            if this.IsInitialized
                for ko = 1:this.Response.NRows
                    for ki = 1:this.Response.NColumns
                        for ka = 1:this.Response.NResponses
                            this.PhasePoleMarkers(ko,ki,ka).YData = conversionFcn(this.PhasePoleMarkers(ko,ki,ka).YData);
                        end
                    end
                end
            end
        end

        function c = getMarkerObjects_(this,ko,ki,ka)
            c = [this.MagnitudePoleMarkers(ko,ki,ka);this.PhasePoleMarkers(ko,ki,ka)];
        end

        function l = getSupportingObjects_(this,ko,ki,ka)
            l = [this.DummyYLines(ko,ki,ka);this.StabilityYLines(ko,ki,ka)];
        end

        function updateStyle_(this,~,ko,ki,ka)
            if this.IsInitialized
                set(this.MagnitudePoleMarkers(ko,ki,ka),Marker='x',LineWidth=1.5*get(groot,"DefaultLineLineWidth"));
                set(this.PhasePoleMarkers(ko,ki,ka),Marker='x',LineWidth=1.5*get(groot,"DefaultLineLineWidth"));
                controllib.plot.internal.utils.setColorProperty(this.MagnitudePoleMarkers(ko,ki,ka),...
                    "MarkerEdgeColor","--mw-graphics-colorOrder-10-primary");
                controllib.plot.internal.utils.setColorProperty(this.PhasePoleMarkers(ko,ki,ka),...
                    "MarkerEdgeColor","--mw-graphics-colorOrder-10-primary");
            end
        end

        function removePole(this,source,isMag)
            arguments
                this (1,1) controllib.chart.editor.internal.bode.BodeEditorCompensatorComplexConjugatePoleView
                source (1,1) matlab.graphics.primitive.Data
                isMag (1,1) logical = true
            end
            ax = ancestor(source,'axes');
            fig = ancestor(ax,'figure');
            if strcmp(fig.SelectionType,"normal")
                response = getResponse(this.Response);
                poleData = this.Response.ResponseData.BodeCompensatorComplexConjugatePoles;
                selectedPoint = ax.CurrentPoint(1,1:2)';
                diff = selectedPoint-[source.XData;source.YData];
                dist = diff(1,:).^2+diff(2,:).^2;
                [~,idx] = min(dist);
                if isMag
                    midx = find(source == this.MagnitudePoleMarkers,1);
                else
                    midx = find(source == this.PhasePoleMarkers,1);
                end
                [ko,ki,~] = ind2sub([this.Response.NRows this.Response.NColumns this.Response.NResponses],midx);
                pc = find(response.Compensator.P{ko,ki} ~= real(response.Compensator.P{ko,ki}));
                pidx = pc(idx);
                pcidx = pc(poleData.PairIdx{ko,ki}(idx));
                pole = response.Compensator.P{ko,ki}(pidx);
                response.Compensator.P{ko,ki}([pidx pcidx]) = [];
                if this.Response.IsDiscrete
                    response.Compensator.K(ko,ki) = response.Compensator.K(ko,ki)/abs((1-pole))^2;
                else
                    response.Compensator.K(ko,ki) = response.Compensator.K(ko,ki)/abs(pole)^2;
                end
                Data = struct('OldValue',pole,'NewValue',[],'Status','Finished','Property','P');
                ed = controllib.chart.internal.utils.GenericEventData(Data);
                notify(this,'PoleChanged',ed)
            end
        end

        function movePole(this,source,action,isMag,optionalInputs)
            arguments
                this (1,1) controllib.chart.editor.internal.bode.BodeEditorCompensatorComplexConjugatePoleView
                source (1,1) matlab.graphics.primitive.Data
                action (1,1) string {mustBeMember(action,["init";"move";"finish"])}
                isMag (1,1) logical = true
                optionalInputs.StartLocation = []
                optionalInputs.EndLocation = []
            end
            persistent WML WBMClear location stabValue ptr ko ki idx pidx pcidx;
            ax = ancestor(source,'axes');
            fig = ancestor(ax,'figure');
            if strcmp(fig.SelectionType,"normal")
                response = getResponse(this.Response);
                poleData = this.Response.ResponseData.BodeCompensatorComplexConjugatePoles;
                switch action
                    case 'init'
                        optionalInputsCell = namedargs2cell(optionalInputs);
                        L1 = addlistener(fig,'WindowMouseMotion',@(es,ed) movePole(this,source,'move',isMag,optionalInputsCell{:}));
                        L2 = addlistener(fig,'WindowMouseRelease',@(es,ed) movePole(this,source,'finish',isMag,optionalInputsCell{:}));
                        WML = [L1;L2];
                        WBMClear = isempty(fig.WindowButtonMotionFcn);
                        if WBMClear
                            fig.WindowButtonMotionFcn = @(es,ed) []; %needs func to update CurrentPoint
                        end
                        ptr = fig.Pointer;
                        if isMag
                            fig.Pointer = "fleur";
                        else
                            fig.Pointer = "left";
                        end
                        if isempty(optionalInputs.StartLocation)
                            selectedPoint = ax.CurrentPoint(1,1:2)';
                        else
                            selectedPoint = optionalInputs.StartLocation';
                        end
                        diff = selectedPoint-[source.XData;source.YData];
                        dist = diff(1,:).^2+diff(2,:).^2;
                        [~,idx] = min(dist);
                        if isMag
                            midx = find(source == this.MagnitudePoleMarkers,1);
                        else
                            midx = find(source == this.PhasePoleMarkers,1);
                        end
                        [ko,ki,~] = ind2sub([this.Response.NRows this.Response.NColumns this.Response.NResponses],midx);
                        pc = find(response.Compensator.P{ko,ki} ~= real(response.Compensator.P{ko,ki}));
                        pidx = pc(idx);
                        pcidx = pc(poleData.PairIdx{ko,ki}(idx));
                        location = poleData.Locations{ko,ki}(idx);
                        w = poleData.Frequencies{ko,ki}(idx);
                        zeta = poleData.Dampings{ko,ki}(idx);
                        if isMag
                            stabValue = [];
                        else
                            stabValue = computeStabilityBound(this,w,zeta,ko,ki);
                        end
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
                        location = computeNewLocation(this,newPoint,location,stabValue,ko,ki);
                        response.Compensator.P{ko,ki}([pidx pcidx]) = [location conj(location)];
                        if this.Response.IsDiscrete
                            response.Compensator.K(ko,ki) = abs((1-location)/(1-oldLocation))^2*response.Compensator.K(ko,ki);
                        else
                            response.Compensator.K(ko,ki) = abs(location/oldLocation)^2*response.Compensator.K(ko,ki);
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
                        this.StabilityYLines(ko,ki,this.Response.NominalIndex).Visible = false;
                        Data = struct('OldValue',location,'NewValue',location,'Status','Finished','Property','P');
                        ed = controllib.chart.internal.utils.GenericEventData(Data);
                        notify(this,'PoleChanged',ed)
                end
            end
        end

        function stabValue = computeStabilityBound(this,w,zeta,ko,ki)
            responseObjects = getResponseObjects(this.ResponseView,ko,ki,this.Response.NominalIndex);
            phaseResponseLine = responseObjects{1}(2);
            freqConversionFcn = getFrequencyUnitConversionFcn(this,this.Response.FrequencyUnit,this.FrequencyUnit);
            w = freqConversionFcn(w);
            ax = phaseResponseLine.Parent;
            if isempty(ax)
                freqScale = "log";
            else
                freqScale = ax.XScale;
            end
            phase = this.scaledInterp1(phaseResponseLine.XData,phaseResponseLine.YData,w,freqScale,"linear");
            phaseConversionFcn = getPhaseUnitConversionFcn(this,"deg",this.PhaseUnit);
            threshold = phaseConversionFcn(90);
            if zeta > 0 %stable
                stabValue = phase+threshold;
            else %unstable
                stabValue = phase-threshold;
            end
            this.StabilityYLines(ko,ki,this.Response.NominalIndex).Value = stabValue;
            this.StabilityYLines(ko,ki,this.Response.NominalIndex).Visible = true;
        end

        function location = computeNewLocation(this,newPoint,location,stabValue,ko,ki)
            responseObjects = getResponseObjects(this.ResponseView,ko,ki,this.Response.NominalIndex);
            magResponseLine = responseObjects{1}(1);
            freqConversionFcn = getFrequencyUnitConversionFcn(this,this.FrequencyUnit,this.Response.FrequencyUnit);
            fNew = freqConversionFcn(abs(newPoint(1)));
            Ts = abs(this.Response.SourceData.Model.Ts);
            if isa(this.Response.SourceData.Model,'FRDModel') %FRD cannot drag past data
                fNew = max(fNew,min(this.Response.SourceData.Model.Frequency));
                fNew = min(fNew,max(this.Response.SourceData.Model.Frequency));
            end
            if this.Response.IsDiscrete %discrete cannot drag past nyquist
                fNew = min(fNew,pi/Ts-eps(pi/Ts));
                zetaNew = -cos(angle(log(location)/Ts));
            else 
                zetaNew = -cos(angle(location));
            end
            if isempty(stabValue)
                magConversionFcn = getMagnitudeUnitConversionFcn(this,this.MagnitudeUnit,"abs");
                freqs = magResponseLine.XData;
                mags = magResponseLine.YData;
                if this.Response.IsDiscrete
                    wn = abs(log(location)/Ts);
                else
                    wn = abs(location);
                end
                freqConversionFcn = getFrequencyUnitConversionFcn(this,"rad/s",this.FrequencyUnit);
                wn = freqConversionFcn(wn);

                % Recompute mags with pole at new freq
                mags = magConversionFcn(mags).*sqrt((1-(freqs/wn).^2).^2+(2*zetaNew*freqs/wn).^2);
                magConversionFcnInv = getMagnitudeUnitConversionFcn(this,"abs",this.MagnitudeUnit);
                mags = magConversionFcnInv(mags);

                ax = magResponseLine.Parent;
                if isempty(ax)
                    freqScale = "log";
                    magScale = "linear";
                else
                    freqScale = ax.XScale;
                    magScale = ax.YScale;
                end
                w = abs(newPoint(1));
                mag = this.scaledInterp1(freqs,mags,w,freqScale,magScale);
                magNew = newPoint(2);
                mag = magConversionFcn(mag);
                magNew = magConversionFcn(magNew);
                zetaNew = mag/(magNew*2)*sign(zetaNew);
                if zetaNew < 0
                    zetaNew = max(zetaNew,-1+sqrt(eps));
                else
                    zetaNew = min(zetaNew,1-sqrt(eps));
                end
            end
            locReal = -zetaNew*fNew;
            locImag = sqrt(fNew^2-locReal^2)*sign(imag(location));
            location = locReal+1j*locImag;
            if ~isempty(stabValue)
                if (zetaNew > 0 && newPoint(2) > stabValue) || ...
                        (zetaNew < 0 && newPoint(2) < stabValue)
                    location = -locReal+1j*locImag;
                end
            end
            if this.Response.IsDiscrete
                location = exp(location*Ts);
            end
        end
    end

    %% Hidden methods
    methods (Hidden)
        function qeDrag(this,startLoc,endLoc,axType,ko,ki)
            arguments
                this (1,1) controllib.chart.editor.internal.bode.BodeEditorCompensatorComplexConjugatePoleView
                startLoc (1,2) double
                endLoc (1,2) double
                axType (1,1) string {mustBeMember(axType,["Magnitude";"Phase"])}
                ko (1,1) double {mustBePositive,mustBeInteger} = 1
                ki (1,1) double {mustBePositive,mustBeInteger} = 1
            end
            isMag = axType == "Magnitude";
            if isMag
                source = this.MagnitudePoleMarkers(ko,ki,this.Response.NominalIndex);
            else
                source = this.PhasePoleMarkers(ko,ki,this.Response.NominalIndex);
            end
            movePole(this,source,'init',isMag,StartLocation=startLoc,EndLocation=endLoc);
            movePole(this,source,'move',isMag,StartLocation=startLoc,EndLocation=endLoc);
            movePole(this,source,'finish',isMag,StartLocation=startLoc,EndLocation=endLoc);
        end
    end
end