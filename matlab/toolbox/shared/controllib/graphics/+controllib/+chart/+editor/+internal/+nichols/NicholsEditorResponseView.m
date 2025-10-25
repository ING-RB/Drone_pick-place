classdef NicholsEditorResponseView < controllib.chart.internal.view.wave.NicholsResponseView
    % BodeEditorResponseView

    % Copyright 2024 The MathWorks, Inc.

    %% Properties
    properties (Dependent,AbortSet,SetObservable)
        InteractionMode
    end

    properties (SetAccess = protected)
        FixedPlantPoles
        FixedPlantZeros
    end

    properties (Access=private,Transient,NonCopyable)
        PZGroupListeners
        InteractionMode_I = "default"
    end

    %% Events
    events
        CompensatorChanged
    end

    %% Constructor
    methods
        function this = NicholsEditorResponseView(response,bodeOptionalInputs,optionalInputs)
            arguments
                response (1,1) controllib.chart.editor.response.NicholsEditorResponse
                bodeOptionalInputs.PhaseWrappingEnabled (1,1) logical = false
                bodeOptionalInputs.PhaseMatchingEnabled (1,1) logical = false
                optionalInputs.ColumnVisible (1,:) logical = true(1,response.NInputs);
                optionalInputs.RowVisible (:,1) logical = true(response.NOutputs,1);
                optionalInputs.ArrayVisible logical = response.ArrayVisible
            end
            magPhaseInputs = namedargs2cell(bodeOptionalInputs);
            optionalInputs = namedargs2cell(optionalInputs);
            this@controllib.chart.internal.view.wave.NicholsResponseView(response,magPhaseInputs{:},optionalInputs{:});
        end
    end

    %% Get/Set
    methods
        % InteractionMode        
        function InteractionMode = get.InteractionMode(this)
            InteractionMode = this.InteractionMode_I;
        end

        function set.InteractionMode(this,InteractionMode)
            for ii = 1:length(this.Characteristics)
                this.Characteristics(ii).InteractionMode = InteractionMode;
            end
            switch InteractionMode
                case "default"          
                    set(this.ResponseLines,HitTest='on');
                otherwise
                    set(this.ResponseLines,HitTest='off');
            end
            this.InteractionMode_I = InteractionMode;
        end
    end

    %% Public methods
    methods
        function fNew = getNewFreq(this,newPoint)
            responseLine = this.ResponseLines(1,1,this.Response.NominalIndex);
            phases = responseLine.XData;
            mags = responseLine.YData;
            freqs = responseLine.UserData.Frequency;
            ax = responseLine.Parent;
            fNew = this.scaledProject2(phases,mags,freqs,newPoint,ax.XLim,ax.YLim,ax.XScale,ax.YScale);
        end
    end

    %% Protected methods
    methods (Access=protected)
        function createCharacteristics(this,data)
            createCharacteristics@controllib.chart.internal.view.wave.NicholsResponseView(this,data);
            c1 = controllib.chart.editor.internal.nichols.NicholsEditorCompensatorZeroView(this,data.NicholsCompensatorZeros);
            c2 = controllib.chart.editor.internal.nichols.NicholsEditorCompensatorPoleView(this,data.NicholsCompensatorPoles);
            c3 = controllib.chart.editor.internal.nichols.NicholsEditorCompensatorComplexConjugateZeroView(this,data.NicholsCompensatorComplexConjugateZeros);
            c4 = controllib.chart.editor.internal.nichols.NicholsEditorCompensatorComplexConjugatePoleView(this,data.NicholsCompensatorComplexConjugatePoles);
            weakThis = matlab.lang.WeakReference(this);
            L1 = addlistener(c1,'ZeroChanged',@(es,ed) cbPZGroupChanged(weakThis.Handle,ed));
            L2 = addlistener(c2,'PoleChanged',@(es,ed) cbPZGroupChanged(weakThis.Handle,ed));
            L3 = addlistener(c3,'ZeroChanged',@(es,ed) cbPZGroupChanged(weakThis.Handle,ed));
            L4 = addlistener(c4,'PoleChanged',@(es,ed) cbPZGroupChanged(weakThis.Handle,ed));
            this.PZGroupListeners = [L1;L2;L3;L4];
            this.Characteristics = [this.Characteristics;c1;c2;c3;c4];
        end

        function createResponseObjects(this)
            createResponseObjects@controllib.chart.internal.view.wave.NicholsResponseView(this);
            weakThis = matlab.lang.WeakReference(this);
            set(this.ResponseLines(:,:,this.Response.NominalIndex),ButtonDownFcn=@(es,ed) moveGain(weakThis.Handle,es,'init'));
            % Fixed PZs
            this.FixedPlantPoles = createGraphicsObjects(this,"scatter",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,Tag='NicholsPolesScatter',HitTest='off');
            this.FixedPlantZeros = createGraphicsObjects(this,"scatter",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,Tag='NicholsZerosScatter',HitTest='off');
            this.disableDataTipInteraction(this.FixedPlantPoles);
            this.disableDataTipInteraction(this.FixedPlantZeros);
        end

        function cbResponseNominalIndexChanged(this)
            cbResponseNominalIndexChanged@controllib.chart.internal.view.wave.NicholsResponseView(this)
            set(this.ResponseLines,ButtonDownFcn=[]);
            weakThis = matlab.lang.WeakReference(this);
            if this.Response.NominalIndex <= size(this.ResponseLines,3)
                set(this.ResponseLines(:,:,this.Response.NominalIndex),ButtonDownFcn=@(es,ed) moveGain(weakThis.Handle,es,'init'));
            end
        end

        function responseObjects = getResponseObjects_(this,ko,ki,ka)
            responseObjects = cat(3,this.ResponseLines(ko,ki,ka),...
                this.FixedPlantPoles(ko,ki,ka),this.FixedPlantZeros(ko,ki,ka));
        end

        function updateResponseData(this)
            arguments
                this (1,1) controllib.chart.editor.internal.nichols.NicholsEditorResponseView
            end
            updateResponseData@controllib.chart.internal.view.wave.NicholsResponseView(this);
            freqConversionFcn = getFrequencyUnitConversionFcn(this,this.Response.FrequencyUnit,this.FrequencyUnit);
            for ko = 1:this.Response.NRows
                for ki = 1:this.Response.NColumns
                    for ka = 1:this.Response.NResponses
                        f = freqConversionFcn(this.Response.ResponseData.PoleFrequencies{ko,ki,ka});
                        [mag,phase] = getMagPhaseValuesFromFrequencies(this,f,ko,ki,ka);
                        this.FixedPlantPoles(ko,ki,ka).XData = phase;
                        this.FixedPlantPoles(ko,ki,ka).YData = mag;

                        f = freqConversionFcn(this.Response.ResponseData.ZeroFrequencies{ko,ki,ka});
                        [mag,phase] = getMagPhaseValuesFromFrequencies(this,f,ko,ki,ka);
                        this.FixedPlantZeros(ko,ki,ka).XData = phase;
                        this.FixedPlantZeros(ko,ki,ka).YData = mag;
                    end
                end
            end
        end

        function updateResponseStyle_(this,~,ko,ki,ka)
            this.FixedPlantPoles(ko,ki,ka).Marker = 'x';
            this.FixedPlantZeros(ko,ki,ka).Marker = 'o';
        end

        function cbMagnitudeUnitChanged(this,conversionFcn)
            cbMagnitudeUnitChanged@controllib.chart.internal.view.wave.NicholsResponseView(this,conversionFcn);
            for ko = 1:this.Response.NRows
                for ki = 1:this.Response.NColumns
                    for ka = 1:this.Response.NResponses
                        this.FixedPlantPoles(ko,ki,ka).YData = ...
                            conversionFcn(this.FixedPlantPoles(ko,ki,ka).YData);
                        this.FixedPlantZeros(ko,ki,ka).YData = ...
                            conversionFcn(this.FixedPlantZeros(ko,ki,ka).YData);
                    end
                end
            end
        end

        function cbPhaseUnitChanged(this,conversionFcn)
            cbPhaseUnitChanged@controllib.chart.internal.view.wave.NicholsResponseView(this,conversionFcn);
            for ko = 1:this.Response.NRows
                for ki = 1:this.Response.NColumns
                    for ka = 1:this.Response.NResponses
                        this.FixedPlantPoles(ko,ki,ka).XData = ...
                            conversionFcn(this.FixedPlantPoles(ko,ki,ka).XData);
                        this.FixedPlantZeros(ko,ki,ka).XData = ...
                            conversionFcn(this.FixedPlantZeros(ko,ki,ka).XData);
                    end
                end
            end
        end
    end

    %% Private methods
    methods (Access=private)
        function cbPZGroupChanged(this,ed)
            ed = controllib.chart.internal.utils.GenericEventData(ed.Data);
            notify(this,'CompensatorChanged',ed)
        end

        function [magValues,phaseValues] = getMagPhaseValuesFromFrequencies(this,freqs,ko,ki,ka)
            magFreqs = this.ResponseLines(ko,ki,ka).UserData.Frequency;
            mags = this.ResponseLines(ko,ki,ka).YData;
            ax = this.ResponseLines(ko,ki,ka).Parent;
            if isempty(ax)
                magScale = "linear";
            else
                magScale = ax.YScale;
            end
            magValues = this.scaledInterp1(magFreqs,mags,freqs,magScale,magScale);
            phaseFreqs = this.ResponseLines(ko,ki,ka).UserData.Frequency;
            phases = this.ResponseLines(ko,ki,ka).XData;
            phaseValues = this.scaledInterp1(phaseFreqs,phases,freqs);
        end

        function moveGain(this,source,action,optionalInputs)
            arguments
                this (1,1) controllib.chart.editor.internal.nichols.NicholsEditorResponseView
                source (1,1) matlab.graphics.primitive.Data
                action (1,1) string {mustBeMember(action,["init";"move";"finish"])}
                optionalInputs.StartLocation = []
                optionalInputs.EndLocation = []
            end
            persistent WML WBMClear gain ptr idx;

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
                        fig.Pointer = "top";
                        if isempty(optionalInputs.StartLocation)
                            selectedPoint = ax.CurrentPoint(1,1:2)';
                        else
                            selectedPoint = optionalInputs.StartLocation';
                        end
                        diff = selectedPoint-[source.XData;source.YData];
                        dist = sqrt(diff(1,:).^2+diff(2,:).^2);
                        [~,idx] = min(dist);
                        gain = response.Compensator.K;
                        Data = struct('OldValue',gain,'NewValue',gain,'Status','Init','Property','K');
                        ed = controllib.chart.internal.utils.GenericEventData(Data);
                        notify(this,'CompensatorChanged',ed)
                    case 'move'
                        if isempty(optionalInputs.EndLocation)
                            newPoint = ax.CurrentPoint(1,1:2);
                        else
                            newPoint = optionalInputs.EndLocation;
                        end
                        oldGain = gain;
                        gain = computeNewGain(this,source,idx,newPoint,oldGain);
                        response.Compensator.K = gain;
                        Data = struct('OldValue',oldGain,'NewValue',gain,'Status','InProgress','Property','K');
                        ed = controllib.chart.internal.utils.GenericEventData(Data);
                        notify(this,'CompensatorChanged',ed)
                    case 'finish'
                        delete(WML);
                        if WBMClear
                            fig.WindowButtonMotionFcn = [];
                        end
                        fig.Pointer = ptr;
                        Data = struct('OldValue',gain,'NewValue',gain,'Status','Finished','Property','K');
                        ed = controllib.chart.internal.utils.GenericEventData(Data);
                        notify(this,'CompensatorChanged',ed)
                end
            end
        end

        function gain = computeNewGain(this,source,idx,newPoint,gain)
            magOld = source.YData(idx);
            switch this.MagnitudeUnit
                case "dB"
                    gain = gain*db2mag(newPoint(2)-magOld);
                case "abs"
                    magNew = max(newPoint(2),realmin);
                    gain = gain*10^(log10(magNew)-log10(magOld));
            end
        end
    end

    %% Hidden methods
    methods (Hidden)
        function qeDrag(this,type,startLoc,endLoc,ko,ki)
            arguments
                this (1,1) controllib.chart.editor.internal.nichols.NicholsEditorResponseView
                type (1,1) string {mustBeMember(type,["gain";"zero";"pole";"complexConjugateZero";"complexConjugatePole"])}
                startLoc (1,2) double
                endLoc (1,2) double
                ko (1,1) double {mustBePositive,mustBeInteger} = 1
                ki (1,1) double {mustBePositive,mustBeInteger} = 1
            end
            switch type
                case "gain"
                    source = this.ResponseLines(ko,ki,this.Response.NominalIndex);
                    moveGain(this,source,'init',StartLocation=startLoc,EndLocation=endLoc);
                    moveGain(this,source,'move',StartLocation=startLoc,EndLocation=endLoc);
                    moveGain(this,source,'finish',StartLocation=startLoc,EndLocation=endLoc);
                case "zero"
                    c = getCharacteristic(this,"CompensatorZeros");
                    qeDrag(c,startLoc,endLoc)
                case "pole"
                    c = getCharacteristic(this,"CompensatorPoles");
                    qeDrag(c,startLoc,endLoc)
                case "complexConjugateZero"
                    c = getCharacteristic(this,"CompensatorComplexConjugateZeros");
                    qeDrag(c,startLoc,endLoc)
                case "complexConjugatePole"
                    c = getCharacteristic(this,"CompensatorComplexConjugatePoles");
                    qeDrag(c,startLoc,endLoc)
            end
        end
    end
end



