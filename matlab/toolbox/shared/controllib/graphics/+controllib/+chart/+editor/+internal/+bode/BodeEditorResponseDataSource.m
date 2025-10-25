classdef BodeEditorResponseDataSource < controllib.chart.internal.data.response.BodeResponseDataSource
    % controllib.editor.internal.bode.BodeEditorResponseDataSource

    % Copyright 2024 The MathWorks, Inc.

    %% Properties
    properties (SetAccess = protected)
        PoleFrequencies
        ZeroFrequencies
        CompensatorZeros
        CompensatorPoles
        CompensatorGain
        FixedPlantModelSource
        FixedPlantModelData
        PZGroupPhaseFocus
    end

    properties (Dependent,SetAccess=private)
        BodeCompensatorZeros
        BodeCompensatorPoles
        BodeCompensatorComplexConjugateZeros
        BodeCompensatorComplexConjugatePoles
    end

    properties (Dependent,Access=private)
        Compensator
    end

    %% Constructor
    methods
        function this = BodeEditorResponseDataSource(model,bodeEditorResponseOptionalArguments,bodeResponseOptionalArguments)
            arguments
                model
                bodeEditorResponseOptionalArguments.CompensatorZeros = []
                bodeEditorResponseOptionalArguments.CompensatorPoles = []
                bodeEditorResponseOptionalArguments.CompensatorGain = 1
                bodeResponseOptionalArguments.NumberOfStandardDeviations = 1
                bodeResponseOptionalArguments.Frequency = []
            end
            bodeResponseOptionalArguments = namedargs2cell(bodeResponseOptionalArguments);            
            this@controllib.chart.internal.data.response.BodeResponseDataSource(model,bodeResponseOptionalArguments{:});

            this.Type = "BodeEditorResponse";
            this.CompensatorZeros = bodeEditorResponseOptionalArguments.CompensatorZeros;
            this.CompensatorPoles = bodeEditorResponseOptionalArguments.CompensatorPoles;
            this.CompensatorGain = bodeEditorResponseOptionalArguments.CompensatorGain;
            updateFixedPlantModelDataAndSources(this);

            % Update response
            update(this);
        end
    end

    %% Public methods
    methods
        function [commonPhaseFocus,phaseUnit] = getCommonPhaseFocus(this,commonFrequencyFocus,optionalInputs)
            arguments
                this (:,1) controllib.chart.editor.internal.bode.BodeEditorResponseDataSource
                commonFrequencyFocus (:,:) cell
                optionalInputs.ConfidenceRegionVisible (1,1) logical = false
                optionalInputs.BoundaryRegionVisible (1,1) logical = false
                optionalInputs.ArrayVisible (:,1) cell = arrayfun(@(x) {true(x.NResponses,1)},this)
                optionalInputs.PhaseWrappingEnabled (1,1) logical = false
                optionalInputs.PhaseMatchingEnabled (1,1) logical = false
            end
            optionalInputsCell = namedargs2cell(optionalInputs);
            [commonPhaseFocus,phaseUnit] = getCommonPhaseFocus@controllib.chart.internal.data.response.BodeResponseDataSource(this,commonFrequencyFocus,optionalInputsCell{:});
            % Include tunable PZGroups in focus
            for k = 1:length(this) % loop for number of data objects
                for ka = 1:this(k).NResponses % loop for system array
                    if optionalInputs.ArrayVisible{k}(ka)
                        for ko = 1:this(k).NOutputs % loop for outputs
                            for ki = 1:this(k).NInputs % loop for inputs
                                commonPhaseFocus{ko,ki}(1) = min(commonPhaseFocus{ko,ki}(1),this(k).PZGroupPhaseFocus{ka}{ko,ki}(1));
                                commonPhaseFocus{ko,ki}(2) = max(commonPhaseFocus{ko,ki}(2),this(k).PZGroupPhaseFocus{ka}{ko,ki}(2));
                            end
                        end
                    end
                end
            end
        end
    end

    %% Get/Set
    methods
        % BodeCompensatorZeros
        function BodeCompensatorZeros = get.BodeCompensatorZeros(this)
            arguments
                this (1,1) controllib.chart.editor.internal.bode.BodeEditorResponseDataSource
            end            
            BodeCompensatorZeros = getCharacteristics(this,"CompensatorZeros");
        end

        % BodeCompensatorPoles
        function BodeCompensatorPoles = get.BodeCompensatorPoles(this)
            arguments
                this (1,1) controllib.chart.editor.internal.bode.BodeEditorResponseDataSource
            end            
            BodeCompensatorPoles = getCharacteristics(this,"CompensatorPoles");
        end

        % BodeCompensatorComplexConjugatePoles
        function BodeCompensatorComplexConjugatePoles = get.BodeCompensatorComplexConjugatePoles(this)
            arguments
                this (1,1) controllib.chart.editor.internal.bode.BodeEditorResponseDataSource
            end            
            BodeCompensatorComplexConjugatePoles = getCharacteristics(this,"CompensatorComplexConjugatePoles");
        end

        % BodeCompensatorComplexConjugateZeros
        function BodeCompensatorComplexConjugateZeros = get.BodeCompensatorComplexConjugateZeros(this)
            arguments
                this (1,1) controllib.chart.editor.internal.bode.BodeEditorResponseDataSource
            end            
            BodeCompensatorComplexConjugateZeros = getCharacteristics(this,"CompensatorComplexConjugateZeros");
        end

        % Compensator
        function Compensator = get.Compensator(this)
            if isempty(this.CompensatorGain)
                Compensator = zpk(1); %init
            else
                Compensator = zpk(this.CompensatorZeros,this.CompensatorPoles,this.CompensatorGain,this.Model.Ts,TimeUnit=this.Model.TimeUnit);
            end
        end
    end

    %% Protected methods
    methods (Access = protected)
        function modelValue = getModelValue(this)
            model = this.Model*this.Compensator;
            modelValue = getValue(model,'usample');
        end

        function updateFixedPlantModelDataAndSources(this)
            %^ Get model source and data
            this.FixedPlantModelSource = getPlotSource(this.Model,this.Model.Name);
            this.FixedPlantModelData = getModelData(this.FixedPlantModelSource);
        end

        function updateData(this,bodeEditorResponseOptionalArguments,bodeResponseOptionalArguments,frequencyResponseOptionalArguments)
            arguments
                this (1,1) controllib.chart.editor.internal.bode.BodeEditorResponseDataSource
                bodeEditorResponseOptionalArguments.CompensatorZeros = this.CompensatorZeros
                bodeEditorResponseOptionalArguments.CompensatorPoles = this.CompensatorPoles
                bodeEditorResponseOptionalArguments.CompensatorGain = this.CompensatorGain
                bodeResponseOptionalArguments.NumberOfStandardDeviations = this.NumberOfStandardDeviations
                frequencyResponseOptionalArguments.Model = this.Model
                frequencyResponseOptionalArguments.Frequency = this.FrequencyInput
            end
            if this.Type ~= "BodeEditorResponse" %wait til comp defined
                return;
            end
            try
                sysList.System = frequencyResponseOptionalArguments.Model;
                ParamList = {frequencyResponseOptionalArguments.Frequency};
                [sysList,w] = DynamicSystem.checkBodeInputs(sysList,ParamList);
                frequencyResponseOptionalArguments.Model = sysList.System;
                frequencyResponseOptionalArguments.Frequency = w;
            catch ME
                this.DataException = ME;
            end
            frequencyResponseOptionalArguments = namedargs2cell(frequencyResponseOptionalArguments);
            this.CompensatorZeros = bodeEditorResponseOptionalArguments.CompensatorZeros;
            this.CompensatorPoles = bodeEditorResponseOptionalArguments.CompensatorPoles;
            this.CompensatorGain = bodeEditorResponseOptionalArguments.CompensatorGain;
            updateData@controllib.chart.internal.data.response.FrequencyResponseDataSource(this,frequencyResponseOptionalArguments{:});
            this.NumberOfStandardDeviations = bodeResponseOptionalArguments.NumberOfStandardDeviations;
            this.Magnitude = repmat({NaN(this.NOutputs,this.NInputs)},this.NResponses,1);
            this.Phase = repmat({NaN(this.NOutputs,this.NInputs)},this.NResponses,1);
            this.Frequency = repmat({NaN},this.NResponses,1);
            this.PoleFrequencies = repmat({NaN},this.NOutputs,this.NInputs,this.NResponses);
            this.ZeroFrequencies = repmat({NaN},this.NOutputs,this.NInputs,this.NResponses);
            focus = repmat({[NaN NaN]},this.NOutputs,this.NInputs);
            this.FrequencyFocus = repmat({focus},this.NResponses,1);
            this.PZGroupPhaseFocus = repmat({focus},this.NResponses,1);
            isFrequencyFocusSoft = false(this.NOutputs,this.NInputs);
            this.IsFrequencyFocusSoft = repmat({isFrequencyFocusSoft},this.NResponses,1);
            if ~isempty(this.DataException)
                return;
            end
            updateFixedPlantModelDataAndSources(this);
            try
                for ka = 1:this.NResponses
                    [mag,phase,w,focus] = computeResponse(this, ka);
                    if size(mag,3) == 0 %idnlmodel idpoly
                        mag = NaN(size(mag,1),size(mag,2),1);
                        phase = NaN(size(phase,1),size(phase,2),1);
                    end
                    this.Magnitude{ka} = mag;
                    if all(mag(:)==0)
                        this.Phase{ka} = NaN(size(phase));
                    else
                        this.Phase{ka} = phase;
                    end
                    this.Frequency{ka} = w;

                    % Round focus if frequency grid is automatically computed
                    roundedFocus = focus.Focus;
                    roundUpperFocus = false;
                    roundLowerFocus = false;
                    if isempty(this.FrequencyInput) 
                        roundUpperFocus = true;
                        roundLowerFocus = true;
                    elseif iscell(this.FrequencyInput)
                        if isinf(this.FrequencyInput{2})
                            roundUpperFocus = true;
                        else
                            roundedFocus(2) = this.FrequencyInput{2};
                        end
                        if this.FrequencyInput{1} == 0
                            roundLowerFocus = true;
                        else
                            roundedFocus(1) = this.FrequencyInput{1};
                        end
                    end
                    
                    if roundLowerFocus
                        roundedFocus(1) = 10^floor(log10(roundedFocus(1)));
                    end
                    if roundUpperFocus
                        roundedFocus(2) = 10^ceil(log10(roundedFocus(2)));
                    end

                    % Remove NaNs from focus
                    if isequal(isnan(roundedFocus),[true,false])
                        roundedFocus(1) = 10^floor(log10(roundedFocus(2)/10));
                    elseif isequal(isnan(roundedFocus),[false,true])
                        roundedFocus(2) = 10^ceil(log10(roundedFocus(1)*10));
                    elseif isequal(isnan(roundedFocus),[true,true])
                        if this.IsDiscrete
                            nyquistFreq = pi/abs(this.Model.Ts);
                            roundedFocus = [1 10^ceil(log10(nyquistFreq))];
                        else
                            % Check if focus contains NaN
                            roundedFocus = [1 10];
                        end
                    elseif roundedFocus(1) >= roundedFocus(2)
                        if isvector(this.FrequencyInput) && all(this.FrequencyInput==roundedFocus(1))
                            % If frequency vector is just a single
                            % frequency
                            roundedFocus(2) = 2*roundedFocus(1);
                            roundedFocus(1) = roundedFocus(1)/2;
                        else
                            roundedFocus(1) = roundedFocus(1) - 0.1*abs(roundedFocus(1));
                            roundedFocus(2) = roundedFocus(2) + 0.1*abs(roundedFocus(2));
                        end
                    end
                    % Include tunable PZGroups in focus
                    pzGroups = [this.BodeCompensatorZeros;this.BodeCompensatorPoles;...
                        this.BodeCompensatorComplexConjugateZeros;this.BodeCompensatorComplexConjugatePoles];
                    phaseFocus = repmat({[NaN NaN]},this.NOutputs,this.NInputs);
                    for ii = 1:length(pzGroups)
                        fs = pzGroups(ii).Frequencies;
                        for jj = 1:numel(fs)
                            f = fs{jj};
                            if ~isempty(f)
                                fpos = f(f>0);
                                if ~isempty(fpos)
                                    roundedFocus(1) = min(roundedFocus(1),min(fpos));
                                    roundedFocus(2) = max(roundedFocus(2),max(fpos));
                                end
                                for ko = 1:this.NOutputs
                                    for ki = 1:this.NInputs
                                        ph = phase(:,ko,ki);
                                        phF = interp1(w,ph,f);
                                        switch ii
                                            case {1,2}
                                                threshold = pi/4;
                                            case {3,4}
                                                threshold = pi/2;
                                        end
                                        for kk = 1:length(phF)
                                            switch ii
                                                case {1,3}
                                                    if pzGroups(ii).Dampings{jj}(kk) > 0
                                                        phaseFocus{ko,ki}(1) = min(phaseFocus{ko,ki}(1),phF(kk)-threshold);
                                                    elseif pzGroups(ii).Dampings{jj}(kk) < 0
                                                        phaseFocus{ko,ki}(2) = max(phaseFocus{ko,ki}(2),phF(kk)+threshold);
                                                    end
                                                case {2,4}
                                                    if pzGroups(ii).Dampings{jj}(kk) > 0
                                                        phaseFocus{ko,ki}(2) = max(phaseFocus{ko,ki}(2),phF(kk)+threshold);
                                                    elseif pzGroups(ii).Dampings{jj}(kk) < 0
                                                        phaseFocus{ko,ki}(1) = min(phaseFocus{ko,ki}(1),phF(kk)-threshold);
                                                    end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    this.PZGroupPhaseFocus{ka} = phaseFocus;
                    this.FrequencyFocus{ka} = repmat({roundedFocus},this.NOutputs,this.NInputs);
                    this.IsFrequencyFocusSoft{ka} = repmat(focus.Soft,this.NOutputs,this.NInputs);

                    % Add pz locations for non-sparse non-frd
                    try %#ok<TRYNC> 
                        if isfinite(this.FixedPlantModelData(ka))
                            [p,z] = getPoleZeroData_(this.ModelValue,"iopz",ka);
                            for ii = 1:this.NOutputs
                                for jj = 1:this.NInputs
                                    zLoc = z{ii,jj};
                                    pLoc = p{ii,jj};
                                    Ts = abs(this.FixedPlantModelData.Ts);
                                    if Ts ~= 0
                                        zLoc = log(zLoc)/Ts;
                                        pLoc = log(pLoc)/Ts;
                                        zLoc = zLoc(abs(zLoc) < pi/Ts);
                                        pLoc = pLoc(abs(pLoc) < pi/Ts);
                                    end
                                    this.ZeroFrequencies{ii,jj,ka} = abs(zLoc);
                                    this.PoleFrequencies{ii,jj,ka} = abs(pLoc);
                                end
                            end
                        end
                    end
                end
            catch ME
                this.DataException = ME;
            end
        end
        
        function characteristics = createCharacteristics_(this)
            arguments
                this (1,1) controllib.chart.editor.internal.bode.BodeEditorResponseDataSource
            end
            characteristics = createCharacteristics_@controllib.chart.internal.data.response.BodeResponseDataSource(this);
            c1 = controllib.chart.editor.internal.compensator.ZeroData(this);
            c2 = controllib.chart.editor.internal.compensator.PoleData(this);
            c3 = controllib.chart.editor.internal.compensator.ComplexConjugateZeroData(this);
            c4 = controllib.chart.editor.internal.compensator.ComplexConjugatePoleData(this);
            characteristics = [characteristics,c1,c2,c3,c4];
        end
    end
end


