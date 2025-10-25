classdef RootLocusEditorResponseView < controllib.chart.internal.view.wave.RootLocusResponseView
    % RootLocusEditorResponseView

    % Copyright 2024 The MathWorks, Inc.

    %% Properties
    properties (Dependent,AbortSet,SetObservable)
        InteractionMode
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
        function this = RootLocusEditorResponseView(response,optionalInputs)
            arguments
                response (1,1) controllib.chart.editor.response.RootLocusEditorResponse
                optionalInputs.ArrayVisible logical = response.ArrayVisible
            end
            optionalInputs = namedargs2cell(optionalInputs);
            this@controllib.chart.internal.view.wave.RootLocusResponseView(response,optionalInputs{:});
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
                    set(this.PoleMarkers,HitTest='on');
                    set(this.ZeroMarkers,HitTest='on');
                    set(this.LocusLines,HitTest='on');
                otherwise
                    set(this.PoleMarkers,HitTest='off');
                    set(this.ZeroMarkers,HitTest='off');
                    set(this.LocusLines,HitTest='off');
            end
            this.InteractionMode_I = InteractionMode;
        end
    end

    %% Protected methods
    methods (Access=protected)
        function createCharacteristics(this,data)
            createCharacteristics@controllib.chart.internal.view.wave.RootLocusResponseView(this,data);
            c1 = controllib.chart.editor.internal.rlocus.RootLocusEditorCompensatorGainView(this,data.RootLocusCompensatorGain);
            c2 = controllib.chart.editor.internal.rlocus.RootLocusEditorCompensatorZeroView(this,data.RootLocusCompensatorZeros);
            c3 = controllib.chart.editor.internal.rlocus.RootLocusEditorCompensatorPoleView(this,data.RootLocusCompensatorPoles);
            c4 = controllib.chart.editor.internal.rlocus.RootLocusEditorCompensatorComplexConjugateZeroView(this,data.RootLocusCompensatorComplexConjugateZeros);
            c5 = controllib.chart.editor.internal.rlocus.RootLocusEditorCompensatorComplexConjugatePoleView(this,data.RootLocusCompensatorComplexConjugatePoles);
            weakThis = matlab.lang.WeakReference(this);
            L1 = addlistener(c1,'GainChanged',@(es,ed) cbPZGroupChanged(weakThis.Handle,ed));
            L2 = addlistener(c2,'ZeroChanged',@(es,ed) cbPZGroupChanged(weakThis.Handle,ed));
            L3 = addlistener(c3,'PoleChanged',@(es,ed) cbPZGroupChanged(weakThis.Handle,ed));
            L4 = addlistener(c4,'ZeroChanged',@(es,ed) cbPZGroupChanged(weakThis.Handle,ed));
            L5 = addlistener(c5,'PoleChanged',@(es,ed) cbPZGroupChanged(weakThis.Handle,ed));
            this.PZGroupListeners = [L1;L2;L3;L4;L5];
            this.Characteristics = [this.Characteristics;c1;c2;c3;c4;c5];
        end
    end

    %% Private methods
    methods (Access=private)
        function cbPZGroupChanged(this,ed)
            ed = controllib.chart.internal.utils.GenericEventData(ed.Data);
            notify(this,'CompensatorChanged',ed)
        end
    end

    %% Hidden methods
    methods (Hidden)
        function qeDrag(this,type,startLoc,endLoc)
            arguments
                this (1,1) controllib.chart.editor.internal.rlocus.RootLocusEditorResponseView
                type (1,1) string {mustBeMember(type,["gain";"zero";"pole";"complexConjugateZero";"complexConjugatePole"])}
                startLoc (1,2) double
                endLoc (1,2) double
            end
            switch type
                case "gain"
                    c = getCharacteristic(this,"CompensatorGain");
                    qeDrag(c,startLoc,endLoc)
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



