classdef BodeEditorResponseView < controllib.chart.internal.view.wave.BodeResponseView
    % BodeEditorResponseView

    % Copyright 2024 The MathWorks, Inc.

    %% Properties
    properties (Dependent,AbortSet,SetObservable)
        InteractionMode
    end

    properties (SetAccess = protected)
        MagnitudeFixedPlantPoles
        MagnitudeFixedPlantZeros
        PhaseFixedPlantPoles
        PhaseFixedPlantZeros
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
        function this = BodeEditorResponseView(response,bodeOptionalInputs,optionalInputs)
            arguments
                response (1,1) controllib.chart.editor.response.BodeEditorResponse
                bodeOptionalInputs.MinimumGainEnabled (1,1) logical = false
                bodeOptionalInputs.PhaseWrappingEnabled (1,1) logical = false
                bodeOptionalInputs.PhaseMatchingEnabled (1,1) logical = false
                bodeOptionalInputs.FrequencyScale (1,1) string = "log"
                optionalInputs.ColumnVisible (1,:) logical = true(1,response.NInputs);
                optionalInputs.RowVisible (:,1) logical = true(response.NOutputs,1);
                optionalInputs.ArrayVisible logical = response.ArrayVisible
            end
            magPhaseInputs = namedargs2cell(bodeOptionalInputs);
            optionalInputs = namedargs2cell(optionalInputs);
            this@controllib.chart.internal.view.wave.BodeResponseView(response,magPhaseInputs{:},optionalInputs{:});
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
                    set(this.MagnitudeResponseLines,HitTest='on');
                    set(this.PhaseResponseLines,HitTest='on');
                otherwise
                    set(this.MagnitudeResponseLines,HitTest='off');
                    set(this.PhaseResponseLines,HitTest='off');
            end
            this.InteractionMode_I = InteractionMode;
        end
    end

    %% Public methods
    methods
        function zetaNew = getNewZeta(this,fNew,magNew,isPole)
            magConversionFcn = getMagnitudeUnitConversionFcn(this,this.MagnitudeUnit,"abs");
            magResponseLine = this.MagnitudeResponseLines(1,1,this.Response.NominalIndex);
            ax = magResponseLine.Parent;
            if isempty(ax)
                magScale = "linear";
            else
                magScale = ax.YScale;
            end
            mag = this.scaledInterp1(magResponseLine.XData,magResponseLine.YData,fNew,this.FrequencyScale,magScale);
            mag = magConversionFcn(mag);
            magNew = magConversionFcn(magNew);
            if isPole
                zetaNew = mag/(magNew*2*fNew^2);
            else
                zetaNew = magNew/(mag*2*fNew^2);
            end
            zetaNew = min(zetaNew,1-sqrt(eps));
        end
    end

    %% Protected methods
    methods (Access=protected)
        function createCharacteristics(this,data)
            createCharacteristics@controllib.chart.internal.view.wave.BodeResponseView(this,data);
            c1 = controllib.chart.editor.internal.bode.BodeEditorCompensatorZeroView(this,data.BodeCompensatorZeros);
            c2 = controllib.chart.editor.internal.bode.BodeEditorCompensatorPoleView(this,data.BodeCompensatorPoles);
            c3 = controllib.chart.editor.internal.bode.BodeEditorCompensatorComplexConjugateZeroView(this,data.BodeCompensatorComplexConjugateZeros);
            c4 = controllib.chart.editor.internal.bode.BodeEditorCompensatorComplexConjugatePoleView(this,data.BodeCompensatorComplexConjugatePoles);
            weakThis = matlab.lang.WeakReference(this);
            L1 = addlistener(c1,'ZeroChanged',@(es,ed) cbPZGroupChanged(weakThis.Handle,ed));
            L2 = addlistener(c2,'PoleChanged',@(es,ed) cbPZGroupChanged(weakThis.Handle,ed));
            L3 = addlistener(c3,'ZeroChanged',@(es,ed) cbPZGroupChanged(weakThis.Handle,ed));
            L4 = addlistener(c4,'PoleChanged',@(es,ed) cbPZGroupChanged(weakThis.Handle,ed));
            this.PZGroupListeners = [L1;L2;L3;L4];
            this.Characteristics = [this.Characteristics;c1;c2;c3;c4];
        end

        function createResponseObjects(this)
            createResponseObjects@controllib.chart.internal.view.wave.BodeResponseView(this);
            weakThis = matlab.lang.WeakReference(this);
            set(this.MagnitudeResponseLines(:,:,this.Response.NominalIndex),ButtonDownFcn=@(es,ed) moveGain(weakThis.Handle,es,'init'));
            % Fixed PZs
            this.MagnitudeFixedPlantPoles = createGraphicsObjects(this,"scatter",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,Tag='BodeMagnitudePolesScatter',HitTest='off');
            this.MagnitudeFixedPlantZeros = createGraphicsObjects(this,"scatter",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,Tag='BodeMagnitudeZerosScatter',HitTest='off');
            this.PhaseFixedPlantPoles = createGraphicsObjects(this,"scatter",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,Tag='BodePhasePolesScatter',HitTest='off');
            this.PhaseFixedPlantZeros = createGraphicsObjects(this,"scatter",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,Tag='BodePhaseZerosScatter',HitTest='off');
        end

        function cbResponseNominalIndexChanged(this)
            cbResponseNominalIndexChanged@controllib.chart.internal.view.wave.BodeResponseView(this)
            set(this.MagnitudeResponseLines,ButtonDownFcn=[]);
            weakThis = matlab.lang.WeakReference(this);
            if this.Response.NominalIndex <= size(this.MagnitudeResponseLines,3)
                set(this.MagnitudeResponseLines(:,:,this.Response.NominalIndex),ButtonDownFcn=@(es,ed) moveGain(weakThis.Handle,es,'init'));
            end
        end

        function responseObjects = getResponseObjects_(this,ko,ki,ka)
            responseObjects = [cat(3,this.MagnitudeResponseLines(ko,ki,ka),...
                this.MagnitudePositiveArrows(ko,ki,ka),this.MagnitudeNegativeArrows(ko,ki,ka),...
                this.MagnitudeFixedPlantPoles(ko,ki,ka),this.MagnitudeFixedPlantZeros(ko,ki,ka));
                cat(3,this.PhaseResponseLines(ko,ki,ka),...
                this.PhasePositiveArrows(ko,ki,ka),this.PhaseNegativeArrows(ko,ki,ka),...
                this.PhaseFixedPlantPoles(ko,ki,ka),this.PhaseFixedPlantZeros(ko,ki,ka))];
        end

        function updateResponseData(this,optionalInputs)
            arguments
                this (1,1) controllib.chart.editor.internal.bode.BodeEditorResponseView
                optionalInputs.UpdateArrows (1,1) logical = true
            end
            optionalInputs = namedargs2cell(optionalInputs);
            updateResponseData@controllib.chart.internal.view.wave.BodeResponseView(this,optionalInputs{:})
            freqConversionFcn = getFrequencyUnitConversionFcn(this,this.Response.FrequencyUnit,this.FrequencyUnit);
            for ko = 1:this.Response.NRows
                for ki = 1:this.Response.NColumns
                    for ka = 1:this.Response.NResponses
                        f = freqConversionFcn(this.Response.ResponseData.PoleFrequencies{ko,ki,ka});
                        magResponseLine = this.MagnitudeResponseLines(ko,ki,ka);
                        phaseResponseLine = this.PhaseResponseLines(ko,ki,ka);
                        ax = magResponseLine.Parent;
                        if isempty(ax)
                            magScale = "linear";
                        else
                            magScale = ax.YScale;
                        end
                        mag = this.scaledInterp1(magResponseLine.XData,magResponseLine.YData,f,this.FrequencyScale,magScale);
                        phase = this.scaledInterp1(phaseResponseLine.XData,phaseResponseLine.YData,f,this.FrequencyScale,"linear");
                        this.MagnitudeFixedPlantPoles(ko,ki,ka).XData = f;
                        this.MagnitudeFixedPlantPoles(ko,ki,ka).YData = mag;
                        this.PhaseFixedPlantPoles(ko,ki,ka).XData = f;
                        this.PhaseFixedPlantPoles(ko,ki,ka).YData = phase;

                        f = freqConversionFcn(this.Response.ResponseData.ZeroFrequencies{ko,ki,ka});
                        ax = magResponseLine.Parent;
                        if isempty(ax)
                            magScale = "linear";
                        else
                            magScale = ax.YScale;
                        end
                        mag = this.scaledInterp1(magResponseLine.XData,magResponseLine.YData,f,this.FrequencyScale,magScale);
                        phase = this.scaledInterp1(phaseResponseLine.XData,phaseResponseLine.YData,f,this.FrequencyScale,"linear");
                        this.MagnitudeFixedPlantZeros(ko,ki,ka).XData = f;
                        this.MagnitudeFixedPlantZeros(ko,ki,ka).YData = mag;
                        this.PhaseFixedPlantZeros(ko,ki,ka).XData = f;
                        this.PhaseFixedPlantZeros(ko,ki,ka).YData = phase;
                    end
                end
            end
        end

        function updateResponseStyle_(this,~,ko,ki,ka)
            this.MagnitudeFixedPlantPoles(ko,ki,ka).Marker = 'x';
            this.MagnitudeFixedPlantZeros(ko,ki,ka).Marker = 'o';
            this.PhaseFixedPlantPoles(ko,ki,ka).Marker = 'x';
            this.PhaseFixedPlantZeros(ko,ki,ka).Marker = 'o';
        end

        function cbFrequencyUnitChanged(this,conversionFcn)
            cbFrequencyUnitChanged@controllib.chart.internal.view.wave.BodeResponseView(this,conversionFcn);
            for ko = 1:this.Response.NRows
                for ki = 1:this.Response.NColumns
                    for ka = 1:this.Response.NResponses
                        this.MagnitudeFixedPlantPoles(ko,ki,ka).XData = ...
                            conversionFcn(this.MagnitudeFixedPlantPoles(ko,ki,ka).XData);
                        this.MagnitudeFixedPlantZeros(ko,ki,ka).XData = ...
                            conversionFcn(this.MagnitudeFixedPlantZeros(ko,ki,ka).XData);
                        this.PhaseFixedPlantPoles(ko,ki,ka).XData = ...
                            conversionFcn(this.PhaseFixedPlantPoles(ko,ki,ka).XData);
                        this.PhaseFixedPlantZeros(ko,ki,ka).XData = ...
                            conversionFcn(this.PhaseFixedPlantZeros(ko,ki,ka).XData);
                    end
                end
            end
        end

        function cbMagnitudeUnitChanged(this,conversionFcn)
            cbMagnitudeUnitChanged@controllib.chart.internal.view.wave.BodeResponseView(this,conversionFcn);
            for ko = 1:this.Response.NRows
                for ki = 1:this.Response.NColumns
                    for ka = 1:this.Response.NResponses
                        this.MagnitudeFixedPlantPoles(ko,ki,ka).YData = ...
                            conversionFcn(this.MagnitudeFixedPlantPoles(ko,ki,ka).YData);
                        this.MagnitudeFixedPlantZeros(ko,ki,ka).YData = ...
                            conversionFcn(this.MagnitudeFixedPlantZeros(ko,ki,ka).YData);
                    end
                end
            end
        end

        function cbPhaseUnitChanged(this,conversionFcn)
            cbPhaseUnitChanged@controllib.chart.internal.view.wave.BodeResponseView(this,conversionFcn);
            for ko = 1:this.Response.NRows
                for ki = 1:this.Response.NColumns
                    for ka = 1:this.Response.NResponses
                        this.PhaseFixedPlantPoles(ko,ki,ka).YData = ...
                            conversionFcn(this.PhaseFixedPlantPoles(ko,ki,ka).YData);
                        this.PhaseFixedPlantZeros(ko,ki,ka).YData = ...
                            conversionFcn(this.PhaseFixedPlantZeros(ko,ki,ka).YData);
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

        function moveGain(this,source,action,optionalInputs)
            arguments
                this (1,1) controllib.chart.editor.internal.bode.BodeEditorResponseView
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
                        dist = diff(1,:).^2+diff(2,:).^2;
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
        function qeDrag(this,type,startLoc,endLoc,axType,ko,ki)
            arguments
                this (1,1) controllib.chart.editor.internal.bode.BodeEditorResponseView
                type (1,1) string {mustBeMember(type,["gain";"zero";"pole";"complexConjugateZero";"complexConjugatePole"])}
                startLoc (1,2) double
                endLoc (1,2) double
                axType (1,1) string {mustBeMember(axType,["Magnitude";"Phase"])}
                ko (1,1) double {mustBePositive,mustBeInteger} = 1
                ki (1,1) double {mustBePositive,mustBeInteger} = 1
            end
            switch type
                case "gain"
                    if axType == "Phase"
                        error("Cannot drag gain from phase axes")
                    end
                    source = this.MagnitudeResponseLines(ko,ki,this.Response.NominalIndex);
                    moveGain(this,source,'init',StartLocation=startLoc,EndLocation=endLoc);
                    moveGain(this,source,'move',StartLocation=startLoc,EndLocation=endLoc);
                    moveGain(this,source,'finish',StartLocation=startLoc,EndLocation=endLoc);
                case "zero"
                    c = getCharacteristic(this,"CompensatorZeros");
                    qeDrag(c,startLoc,endLoc,axType)
                case "pole"
                    c = getCharacteristic(this,"CompensatorPoles");
                    qeDrag(c,startLoc,endLoc,axType)
                case "complexConjugateZero"
                    c = getCharacteristic(this,"CompensatorComplexConjugateZeros");
                    qeDrag(c,startLoc,endLoc,axType)
                case "complexConjugatePole"
                    c = getCharacteristic(this,"CompensatorComplexConjugatePoles");
                    qeDrag(c,startLoc,endLoc,axType)
            end
        end
    end
end



