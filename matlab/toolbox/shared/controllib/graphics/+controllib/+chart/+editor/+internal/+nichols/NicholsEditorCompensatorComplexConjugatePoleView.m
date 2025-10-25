classdef NicholsEditorCompensatorComplexConjugatePoleView < controllib.chart.internal.view.characteristic.FrequencyCharacteristicView & ...
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
        PoleMarkers
        PoleLocus
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
        function this = NicholsEditorCompensatorComplexConjugatePoleView(responseView,data)
            this@controllib.chart.internal.view.characteristic.FrequencyCharacteristicView(responseView,data);
            this@controllib.chart.internal.foundation.MixInMagnitudeUnit(responseView.MagnitudeUnit);
            this@controllib.chart.internal.foundation.MixInPhaseUnit(responseView.PhaseUnit);
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
            this.PoleMarkers = createGraphicsObjects(this,"scatter",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,Tag='NicholsTunableCCPoleScatter');
            weakThis = matlab.lang.WeakReference(this);
            set(this.PoleMarkers,ButtonDownFcn=@(es,ed) movePole(weakThis.Handle,es,'init'));
            this.disableDataTipInteraction(this.PoleMarkers);
            this.PoleLocus = createGraphicsObjects(this,"line",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,Tag='NicholsTunableCCPoleLocusLine',HitTest='off');
            set(this.PoleLocus,LineStyle=':');
            controllib.plot.internal.utils.setColorProperty(this.PoleLocus,...
                "Color","--mw-graphics-colorOrder-10-primary");
        end

        function updateData(this,ko,ki,ka)
            pzData = this.Response.ResponseData.NicholsCompensatorComplexConjugatePoles;

            responseObjects = getResponseObjects(this.ResponseView,ko,ki,ka);
            responseLine = responseObjects{1}(1);
            frequencyConversionFcn = getFrequencyUnitConversionFcn(this,this.Response.FrequencyUnit,this.FrequencyUnit);
            f = frequencyConversionFcn(pzData.Frequencies{ko,ki});
            f = f(f~=0);
            if isempty(f)
                f = NaN;
            end
            ax = responseLine.Parent;
            if isempty(ax)
                magScale = "linear";
            else
                magScale = ax.YScale;
            end
            mag = this.scaledInterp1(responseLine.UserData.Frequency,responseLine.YData,f,magScale,magScale);
            phase = this.scaledInterp1(responseLine.UserData.Frequency,responseLine.XData,f);
            this.PoleMarkers(ko,ki,ka).XData = phase;
            this.PoleMarkers(ko,ki,ka).YData = mag;
        end

        function cbPhaseUnitChanged(this,conversionFcn)
            if this.IsInitialized
                for ko = 1:this.Response.NRows
                    for ki = 1:this.Response.NColumns
                        for ka = 1:this.Response.NResponses
                            this.PoleMarkers(ko,ki,ka).XData = conversionFcn(this.PoleMarkers(ko,ki,ka).XData);
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
                            this.PoleMarkers(ko,ki,ka).YData = conversionFcn(this.PoleMarkers(ko,ki,ka).YData);
                        end
                    end
                end
            end
        end

        function c = getMarkerObjects_(this,ko,ki,ka)
            c = this.PoleMarkers(ko,ki,ka);
        end

        function l = getSupportingObjects_(this,ko,ki,ka)
            l = this.PoleLocus(ko,ki,ka);
        end

        function updateStyle_(this,~,ko,ki,ka)
            if this.IsInitialized
                set(this.PoleMarkers(ko,ki,ka),Marker='x',LineWidth=1.5*get(groot,"DefaultLineLineWidth"));
                controllib.plot.internal.utils.setColorProperty(this.PoleMarkers(ko,ki,ka),...
                    "MarkerEdgeColor","--mw-graphics-colorOrder-10-primary");
            end
        end

        function removePole(this,source)
            arguments
                this (1,1) controllib.chart.editor.internal.nichols.NicholsEditorCompensatorComplexConjugatePoleView
                source (1,1) matlab.graphics.primitive.Data
            end
            ax = ancestor(source,'axes');
            fig = ancestor(ax,'figure');
            if strcmp(fig.SelectionType,"normal")
                response = getResponse(this.Response);
                poleData = this.Response.ResponseData.NicholsCompensatorComplexConjugatePoles;
                selectedPoint = ax.CurrentPoint(1,1:2)';
                diff = selectedPoint-[source.XData;source.YData];
                dist = diff(1,:).^2+diff(2,:).^2;
                [~,idx] = min(dist);
                midx = find(source == this.PoleMarkers,1);
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

        function movePole(this,source,action,optionalInputs)
            arguments
                this (1,1) controllib.chart.editor.internal.nichols.NicholsEditorCompensatorComplexConjugatePoleView
                source (1,1) matlab.graphics.primitive.Data
                action (1,1) string {mustBeMember(action,["init";"move";"finish"])}
                optionalInputs.StartLocation = []
                optionalInputs.EndLocation = []
            end
            persistent WML WBMClear location ptr ko ki idx pidx pcidx;
            ax = ancestor(source,'axes');
            fig = ancestor(ax,'figure');
            if strcmp(fig.SelectionType,"normal")
                response = getResponse(this.Response);
                poleData = this.Response.ResponseData.NicholsCompensatorComplexConjugatePoles;
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
                        midx = find(source == this.PoleMarkers,1);
                        [ko,ki,~] = ind2sub([this.Response.NRows this.Response.NColumns this.Response.NResponses],midx);
                        pc = find(response.Compensator.P{ko,ki} ~= real(response.Compensator.P{ko,ki}));
                        pidx = pc(idx);
                        pcidx = pc(poleData.PairIdx{ko,ki}(idx));
                        location = poleData.Locations{ko,ki}(idx);
                        w = poleData.Frequencies{ko,ki}(idx);
                        zeta = poleData.Dampings{ko,ki}(idx);
                        computePoleLocus(this,w,zeta,ko,ki,pidx);
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
                        location = computeNewLocation(this,source,newPoint,location,ko,ki);
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
                        this.PoleLocus(ko,ki,this.Response.NominalIndex).Visible = false;
                        Data = struct('OldValue',location,'NewValue',location,'Status','Finished','Property','P');
                        ed = controllib.chart.internal.utils.GenericEventData(Data);
                        notify(this,'PoleChanged',ed)
                end
            end
        end

        function computePoleLocus(this,w,zeta,ko,ki,pidx)
            responseObjects = getResponseObjects(this.ResponseView,ko,ki,this.Response.NominalIndex);
            responseLine = responseObjects{1}(1);
            phaseConversionFcn = getPhaseUnitConversionFcn(this,"rad",this.PhaseUnit);
            magConversionFcn = getMagnitudeUnitConversionFcn(this,"abs",this.MagnitudeUnit);
            magConversionFcnInv = getMagnitudeUnitConversionFcn(this,this.MagnitudeUnit,"abs");
            freqConversionFcn = getFrequencyUnitConversionFcn(this,this.FrequencyUnit,this.Response.FrequencyUnit);
            % Frequency locus
            freqs = freqConversionFcn(responseLine.UserData.Frequency');
            Hshift = (w^2+2*zeta*w*freqs*1j-freqs.^2)./(2*zeta*w^2*1j);
            ph = phaseConversionFcn(angle(Hshift));
            m = abs(Hshift);
            phaseLociFreq = responseLine.XData+ph;
            mags = magConversionFcnInv(responseLine.YData);
            magLociFreq = magConversionFcn(mags.*m);
            % Damping locus
            damps = linspace(realmin,1-sqrt(eps),numel(freqs))*sign(zeta);
            Hshift = zeta./damps;
            ph = phaseConversionFcn(angle(Hshift));
            m = abs(Hshift);            
            phaseLociDamp = this.PoleMarkers(ko,ki,this.Response.NominalIndex).XData(pidx)+ph;
            mags = magConversionFcnInv(this.PoleMarkers(ko,ki,this.Response.NominalIndex).YData(pidx));
            magLociDamp = magConversionFcn(mags.*m);

            this.PoleLocus(ko,ki,this.Response.NominalIndex).XData = [phaseLociFreq NaN phaseLociDamp];
            this.PoleLocus(ko,ki,this.Response.NominalIndex).YData = [magLociFreq NaN magLociDamp];
            this.PoleLocus(ko,ki,this.Response.NominalIndex).UserData.Frequency = [freqs NaN w*ones(size(freqs))];
            this.PoleLocus(ko,ki,this.Response.NominalIndex).UserData.Damping = [zeta*ones(size(freqs)) NaN damps];
            this.PoleLocus(ko,ki,this.Response.NominalIndex).Visible = true;
        end

        function location = computeNewLocation(this,source,newPoint,location,ko,ki)
            ax = source.Parent;
            locusLine = this.PoleLocus(ko,ki,this.Response.NominalIndex);
            phases = locusLine.XData;
            mags = locusLine.YData;
            freqs = locusLine.UserData.Frequency;
            damps = locusLine.UserData.Damping;
            freqs(isinf(freqs) & freqs > 0) = realmax;
            freqs(isinf(freqs) & freqs < 0) = -realmax;
            if isa(this.Response.SourceData.Model,'FRDModel') %FRD cannot drag past data
                validFreqs = freqs>=min(this.Response.SourceData.Model.Frequency) &...
                    freqs<=max(this.Response.SourceData.Model.Frequency);
                freqs = freqs(validFreqs);
                damps = damps(validFreqs);
                phases = phases(validFreqs);
                mags = mags(validFreqs);
            end
            Ts = abs(this.Response.SourceData.Model.Ts);
            if this.Response.IsDiscrete %discrete cannot drag past nyquist
                validFreqs = freqs <= pi/Ts-eps(pi/Ts);
                freqs = freqs(validFreqs);
                damps = damps(validFreqs);
                phases = phases(validFreqs);
                mags = mags(validFreqs);
            end
            fNew = this.scaledProject2(phases,mags,freqs,newPoint,ax.XLim,ax.YLim,ax.XScale,ax.YScale);
            zetaNew = this.scaledProject2(phases,mags,damps,newPoint,ax.XLim,ax.YLim,ax.XScale,ax.YScale);
            fNew = max(fNew,eps);
            locReal = -zetaNew*fNew;
            locImag = sqrt(fNew^2-locReal^2)*sign(imag(location));
            location = locReal+1j*locImag;
            if this.Response.IsDiscrete
                location = exp(location*Ts);
            end
        end
    end

    %% Hidden methods
    methods (Hidden)
        function qeDrag(this,startLoc,endLoc,ko,ki)
            arguments
                this (1,1) controllib.chart.editor.internal.nichols.NicholsEditorCompensatorComplexConjugatePoleView
                startLoc (1,2) double
                endLoc (1,2) double
                ko (1,1) double {mustBePositive,mustBeInteger} = 1
                ki (1,1) double {mustBePositive,mustBeInteger} = 1
            end
            source = this.PoleMarkers(ko,ki,this.Response.NominalIndex);
            movePole(this,source,'init',StartLocation=startLoc,EndLocation=endLoc);
            movePole(this,source,'move',StartLocation=startLoc,EndLocation=endLoc);
            movePole(this,source,'finish',StartLocation=startLoc,EndLocation=endLoc);
        end
    end
end