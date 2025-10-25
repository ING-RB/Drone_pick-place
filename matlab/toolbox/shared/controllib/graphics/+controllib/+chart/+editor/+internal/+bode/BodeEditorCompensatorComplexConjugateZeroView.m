classdef BodeEditorCompensatorComplexConjugateZeroView < controllib.chart.internal.view.characteristic.FrequencyCharacteristicView & ...
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
        MagnitudeZeroMarkers
        PhaseZeroMarkers
        StabilityYLines
    end

    properties (Access=private)
        DummyYLines
        InteractionMode_I = "default"
    end

    %% Events
    events
        ZeroChanged
    end

    %% Constructor
    methods
        function this = BodeEditorCompensatorComplexConjugateZeroView(responseView,data)
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
                    set(this.MagnitudeZeroMarkers,HitTest='on');
                    set(this.PhaseZeroMarkers,HitTest='on');
                    weakThis = matlab.lang.WeakReference(this);
                    set(this.MagnitudeZeroMarkers,ButtonDownFcn=@(es,ed) moveZero(weakThis.Handle,es,'init',true));
                    set(this.PhaseZeroMarkers,ButtonDownFcn=@(es,ed) moveZero(weakThis.Handle,es,'init',false));
                case "removepz"
                    set(this.MagnitudeZeroMarkers,HitTest='on');
                    set(this.PhaseZeroMarkers,HitTest='on');
                    weakThis = matlab.lang.WeakReference(this);
                    set(this.MagnitudeZeroMarkers,ButtonDownFcn=@(es,ed) removeZero(weakThis.Handle,es,true));
                    set(this.PhaseZeroMarkers,ButtonDownFcn=@(es,ed) removeZero(weakThis.Handle,es,false));
                otherwise
                    set(this.MagnitudeZeroMarkers,HitTest='off');
                    set(this.PhaseZeroMarkers,HitTest='off');
            end
            this.InteractionMode_I = InteractionMode;
        end
    end

    %% Protected methods
    methods (Access = protected)
        function build_(this)
            this.MagnitudeZeroMarkers = createGraphicsObjects(this,"scatter",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,Tag='BodeMagnitudeTunableCCZeroScatter');
            this.PhaseZeroMarkers = createGraphicsObjects(this,"scatter",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,Tag='BodePhaseTunableCCZeroScatter');
            this.StabilityYLines = createGraphicsObjects(this,"constantLine",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,Tag='BodePhaseTunableCCZeroStabilityLine',HitTest='off');
            this.DummyYLines = createGraphicsObjects(this,"line",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses);
            weakThis = matlab.lang.WeakReference(this);
            set(this.MagnitudeZeroMarkers,ButtonDownFcn=@(es,ed) moveZero(weakThis.Handle,es,'init',true));
            set(this.PhaseZeroMarkers,ButtonDownFcn=@(es,ed) moveZero(weakThis.Handle,es,'init',false));
            this.disableDataTipInteraction(this.MagnitudeZeroMarkers);
            this.disableDataTipInteraction(this.PhaseZeroMarkers);
            set(this.StabilityYLines,InterceptAxis='y',LineStyle='--');
            controllib.plot.internal.utils.setColorProperty(this.StabilityYLines,...
                "Color","--mw-graphics-colorOrder-10-primary");
        end

        function updateData(this,ko,ki,ka)
            pzData = this.Response.ResponseData.BodeCompensatorComplexConjugateZeros;

            responseObjects = getResponseObjects(this.ResponseView,ko,ki,ka);
            magResponseLine = responseObjects{1}(1);
            phaseResponseLine = responseObjects{1}(2);
            frequencyConversionFcn = getFrequencyUnitConversionFcn(this,this.Response.FrequencyUnit,this.FrequencyUnit);
            f = frequencyConversionFcn(pzData.Frequencies{ko,ki});
            f = f(f~=0);
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
            this.MagnitudeZeroMarkers(ko,ki,ka).XData = f;
            this.MagnitudeZeroMarkers(ko,ki,ka).YData = mag;
            this.PhaseZeroMarkers(ko,ki,ka).XData = f;
            this.PhaseZeroMarkers(ko,ki,ka).YData = phase;
        end

        function cbFrequencyUnitChanged(this,conversionFcn)
            if this.IsInitialized
                for ko = 1:this.Response.NRows
                    for ki = 1:this.Response.NColumns
                        for ka = 1:this.Response.NResponses
                            this.MagnitudeZeroMarkers(ko,ki,ka).XData = conversionFcn(this.MagnitudeZeroMarkers(ko,ki,ka).XData);
                            this.PhaseZeroMarkers(ko,ki,ka).XData = conversionFcn(this.PhaseZeroMarkers(ko,ki,ka).XData);
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
                            this.MagnitudeZeroMarkers(ko,ki,ka).YData = conversionFcn(this.MagnitudeZeroMarkers(ko,ki,ka).YData);
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
                            this.PhaseZeroMarkers(ko,ki,ka).YData = conversionFcn(this.PhaseZeroMarkers(ko,ki,ka).YData);
                        end
                    end
                end
            end
        end

        function c = getMarkerObjects_(this,ko,ki,ka)
            c = [this.MagnitudeZeroMarkers(ko,ki,ka);this.PhaseZeroMarkers(ko,ki,ka)];
        end

        function l = getSupportingObjects_(this,ko,ki,ka)
            l = [this.DummyYLines(ko,ki,ka);this.StabilityYLines(ko,ki,ka)];
        end

        function updateStyle_(this,~,ko,ki,ka)
            if this.IsInitialized
                set(this.MagnitudeZeroMarkers(ko,ki,ka),Marker='o',LineWidth=1.5*get(groot,"DefaultLineLineWidth"),MarkerFaceColor='none');
                set(this.PhaseZeroMarkers(ko,ki,ka),Marker='o',LineWidth=1.5*get(groot,"DefaultLineLineWidth"),MarkerFaceColor='none');
                controllib.plot.internal.utils.setColorProperty(this.MagnitudeZeroMarkers(ko,ki,ka),...
                    "MarkerEdgeColor","--mw-graphics-colorOrder-10-primary");
                controllib.plot.internal.utils.setColorProperty(this.PhaseZeroMarkers(ko,ki,ka),...
                    "MarkerEdgeColor","--mw-graphics-colorOrder-10-primary");
            end
        end

        function removeZero(this,source,isMag)
            arguments
                this (1,1) controllib.chart.editor.internal.bode.BodeEditorCompensatorComplexConjugateZeroView
                source (1,1) matlab.graphics.primitive.Data
                isMag (1,1) logical = true
            end
            ax = ancestor(source,'axes');
            fig = ancestor(ax,'figure');
            if strcmp(fig.SelectionType,"normal")
                response = getResponse(this.Response);
                zeroData = this.Response.ResponseData.BodeCompensatorComplexConjugateZeros;
                selectedPoint = ax.CurrentPoint(1,1:2)';
                diff = selectedPoint-[source.XData;source.YData];
                dist = diff(1,:).^2+diff(2,:).^2;
                [~,idx] = min(dist);
                if isMag
                    midx = find(source == this.MagnitudeZeroMarkers,1);
                else
                    midx = find(source == this.PhaseZeroMarkers,1);
                end
                [ko,ki,~] = ind2sub([this.Response.NRows this.Response.NColumns this.Response.NResponses],midx);
                zc = find(response.Compensator.Z{ko,ki} ~= real(response.Compensator.Z{ko,ki}));
                zidx = zc(idx);
                zcidx = zc(zeroData.PairIdx{ko,ki}(idx));
                zero = response.Compensator.Z{ko,ki}(zidx);
                response.Compensator.Z{ko,ki}([zidx zcidx]) = [];
                if this.Response.IsDiscrete
                    response.Compensator.K(ko,ki) = response.Compensator.K(ko,ki)*abs((1-zero))^2;
                else
                    response.Compensator.K(ko,ki) = response.Compensator.K(ko,ki)*abs(zero)^2;
                end
                Data = struct('OldValue',zero,'NewValue',[],'Status','Finished','Property','Z');
                ed = controllib.chart.internal.utils.GenericEventData(Data);
                notify(this,'ZeroChanged',ed)
            end
        end

        function moveZero(this,source,action,isMag,optionalInputs)
            arguments
                this (1,1) controllib.chart.editor.internal.bode.BodeEditorCompensatorComplexConjugateZeroView
                source (1,1) matlab.graphics.primitive.Data
                action (1,1) string {mustBeMember(action,["init";"move";"finish"])}
                isMag (1,1) logical = true
                optionalInputs.StartLocation = []
                optionalInputs.EndLocation = []
            end
            persistent WML WBMClear location stabValue ptr ko ki idx zidx zcidx;
            ax = ancestor(source,'axes');
            fig = ancestor(ax,'figure');
            if strcmp(fig.SelectionType,"normal")
                response = getResponse(this.Response);
                zeroData = this.Response.ResponseData.BodeCompensatorComplexConjugateZeros;
                switch action
                    case 'init'
                        optionalInputsCell = namedargs2cell(optionalInputs);
                        L1 = addlistener(fig,'WindowMouseMotion',@(es,ed) moveZero(this,source,'move',isMag,optionalInputsCell{:}));
                        L2 = addlistener(fig,'WindowMouseRelease',@(es,ed) moveZero(this,source,'finish',isMag,optionalInputsCell{:}));
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
                            midx = find(source == this.MagnitudeZeroMarkers,1);
                        else
                            midx = find(source == this.PhaseZeroMarkers,1);
                        end
                        [ko,ki,~] = ind2sub([this.Response.NRows this.Response.NColumns this.Response.NResponses],midx);
                        zc = find(response.Compensator.Z{ko,ki} ~= real(response.Compensator.Z{ko,ki}));
                        zidx = zc(idx);
                        zcidx = zc(zeroData.PairIdx{ko,ki}(idx));
                        location = zeroData.Locations{ko,ki}(idx);
                        w = zeroData.Frequencies{ko,ki}(idx);
                        zeta = zeroData.Dampings{ko,ki}(idx);
                        if isMag
                            stabValue = [];
                        else
                            stabValue = computeStabilityBound(this,w,zeta,ko,ki);
                        end
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
                        location = computeNewLocation(this,newPoint,location,stabValue,ko,ki);
                        response.Compensator.Z{ko,ki}([zidx zcidx]) = [location conj(location)];
                        if this.Response.IsDiscrete
                            response.Compensator.K(ko,ki) = abs((1-oldLocation)/(1-location))^2*response.Compensator.K(ko,ki);
                        else
                            response.Compensator.K(ko,ki) = abs(oldLocation/location)^2*response.Compensator.K(ko,ki);
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
                        this.StabilityYLines(ko,ki,this.Response.NominalIndex).Visible = false;
                        Data = struct('OldValue',location,'NewValue',location,'Status','Finished','Property','Z');
                        ed = controllib.chart.internal.utils.GenericEventData(Data);
                        notify(this,'ZeroChanged',ed)
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
                stabValue = phase-threshold;
            else %unstable
                stabValue = phase+threshold;
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
                mags = magConversionFcn(mags)./sqrt((1-(freqs/wn).^2).^2+(2*zetaNew*freqs/wn).^2);
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
                zetaNew = magNew/(mag*2)*sign(zetaNew);
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
                if (zetaNew > 0 && newPoint(2) < stabValue) || ...
                        (zetaNew < 0 && newPoint(2) > stabValue)
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
                this (1,1) controllib.chart.editor.internal.bode.BodeEditorCompensatorComplexConjugateZeroView
                startLoc (1,2) double
                endLoc (1,2) double
                axType (1,1) string {mustBeMember(axType,["Magnitude";"Phase"])}
                ko (1,1) double {mustBePositive,mustBeInteger} = 1
                ki (1,1) double {mustBePositive,mustBeInteger} = 1
            end
            isMag = axType == "Magnitude";
            if isMag
                source = this.MagnitudeZeroMarkers(ko,ki,this.Response.NominalIndex);
            else
                source = this.PhaseZeroMarkers(ko,ki,this.Response.NominalIndex);
            end
            moveZero(this,source,'init',isMag,StartLocation=startLoc,EndLocation=endLoc);
            moveZero(this,source,'move',isMag,StartLocation=startLoc,EndLocation=endLoc);
            moveZero(this,source,'finish',isMag,StartLocation=startLoc,EndLocation=endLoc);
        end
    end
end