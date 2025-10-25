classdef NicholsEditorResponseDataSource < controllib.chart.internal.data.response.NicholsResponseDataSource
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
    end

    properties (Dependent,SetAccess=private)
        NicholsCompensatorZeros
        NicholsCompensatorPoles
        NicholsCompensatorComplexConjugateZeros
        NicholsCompensatorComplexConjugatePoles
    end

    properties (Dependent,Access=private)
        Compensator
    end

    %% Constructor
    methods
        function this = NicholsEditorResponseDataSource(model,nicholsEditorResponseOptionalArguments,nicholsResponseOptionalArguments)
            arguments
                model
                nicholsEditorResponseOptionalArguments.CompensatorZeros = []
                nicholsEditorResponseOptionalArguments.CompensatorPoles = []
                nicholsEditorResponseOptionalArguments.CompensatorGain = 1
                nicholsResponseOptionalArguments.Frequency = []
            end
            nicholsResponseOptionalArguments = namedargs2cell(nicholsResponseOptionalArguments);            
            this@controllib.chart.internal.data.response.NicholsResponseDataSource(model,nicholsResponseOptionalArguments{:});

            this.Type = "NicholsEditorResponse";
            this.CompensatorZeros = nicholsEditorResponseOptionalArguments.CompensatorZeros;
            this.CompensatorPoles = nicholsEditorResponseOptionalArguments.CompensatorPoles;
            this.CompensatorGain = nicholsEditorResponseOptionalArguments.CompensatorGain;
            updateFixedPlantModelDataAndSources(this);

            % Update response
            update(this);
        end
    end

    %% Get/Set
    methods
        % NicholsCompensatorZeros
        function NicholsCompensatorZeros = get.NicholsCompensatorZeros(this)
            arguments
                this (1,1) controllib.chart.editor.internal.nichols.NicholsEditorResponseDataSource
            end            
            NicholsCompensatorZeros = getCharacteristics(this,"CompensatorZeros");
        end

        % NicholsCompensatorPoles
        function NicholsCompensatorPoles = get.NicholsCompensatorPoles(this)
            arguments
                this (1,1) controllib.chart.editor.internal.nichols.NicholsEditorResponseDataSource
            end            
            NicholsCompensatorPoles = getCharacteristics(this,"CompensatorPoles");
        end

        % NicholsCompensatorComplexConjugatePoles
        function NicholsCompensatorComplexConjugatePoles = get.NicholsCompensatorComplexConjugatePoles(this)
            arguments
                this (1,1) controllib.chart.editor.internal.nichols.NicholsEditorResponseDataSource
            end            
            NicholsCompensatorComplexConjugatePoles = getCharacteristics(this,"CompensatorComplexConjugatePoles");
        end

        % NicholsCompensatorComplexConjugateZeros
        function NicholsCompensatorComplexConjugateZeros = get.NicholsCompensatorComplexConjugateZeros(this)
            arguments
                this (1,1) controllib.chart.editor.internal.nichols.NicholsEditorResponseDataSource
            end            
            NicholsCompensatorComplexConjugateZeros = getCharacteristics(this,"CompensatorComplexConjugateZeros");
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

        function updateData(this,nicholsEditorResponseOptionalArguments,frequencyResponseOptionalArguments)
            arguments
                this (1,1) controllib.chart.editor.internal.nichols.NicholsEditorResponseDataSource
                nicholsEditorResponseOptionalArguments.CompensatorZeros = this.CompensatorZeros
                nicholsEditorResponseOptionalArguments.CompensatorPoles = this.CompensatorPoles
                nicholsEditorResponseOptionalArguments.CompensatorGain = this.CompensatorGain
                frequencyResponseOptionalArguments.Model = this.Model
                frequencyResponseOptionalArguments.Frequency = this.FrequencyInput
            end
            if this.Type ~= "NicholsEditorResponse" %wait til comp defined
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
            this.CompensatorZeros = nicholsEditorResponseOptionalArguments.CompensatorZeros;
            this.CompensatorPoles = nicholsEditorResponseOptionalArguments.CompensatorPoles;
            this.CompensatorGain = nicholsEditorResponseOptionalArguments.CompensatorGain;
            updateData@controllib.chart.internal.data.response.FrequencyResponseDataSource(this,frequencyResponseOptionalArguments{:});
            this.Magnitude = repmat({NaN(this.NOutputs,this.NInputs)},this.NResponses,1);
            this.Phase = repmat({NaN(this.NOutputs,this.NInputs)},this.NResponses,1);
            this.Frequency = repmat({NaN},this.NResponses,1);
            this.PoleFrequencies = repmat({NaN},this.NOutputs,this.NInputs,this.NResponses);
            this.ZeroFrequencies = repmat({NaN},this.NOutputs,this.NInputs,this.NResponses);
            focus = repmat({[NaN NaN]},this.NOutputs,this.NInputs);
            this.FrequencyFocus = repmat({focus},this.NResponses,1);
            this.MagnitudeFocus = repmat({focus},this.NResponses,1);
            if ~isempty(this.DataException)
                return;
            end
            updateFixedPlantModelDataAndSources(this);
            try
                for ka = 1:this.NResponses
                    [mag,phase,w,focus] = getMagPhaseData_(this.ModelValue,...
                                        this.FrequencyInput,"nichols",ka);
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
                    if isempty(this.FrequencyInput)
                        roundedFocus(1) = 10^floor(log10(roundedFocus(1)));
                        roundedFocus(2) = 10^ceil(log10(roundedFocus(2)));
                    end

                    % Remove NaNs from focus
                    if any(isnan(roundedFocus))
                        % Check if focus contains NaN
                        roundedFocus = [1 10];
                    elseif roundedFocus(1) >= roundedFocus(2)
                        % Check if focus is not monotonically increasing
                        roundedFocus(1) = roundedFocus(1) - 0.1*abs(roundedFocus(1));
                        roundedFocus(2) = roundedFocus(2) + 0.1*abs(roundedFocus(2));
                    end

                    % Include tunable PZGroups in focus
                    pzGroups = [this.NicholsCompensatorZeros;this.NicholsCompensatorPoles;...
                        this.NicholsCompensatorComplexConjugateZeros;this.NicholsCompensatorComplexConjugatePoles];
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
                            end
                        end
                    end
                    this.FrequencyFocus{ka} = repmat({roundedFocus},this.NOutputs,this.NInputs);

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
                this.MagnitudeFocus = computeMagnitudeFocus(this);
            catch ME
                this.DataException = ME;
            end
        end
        
        function characteristics = createCharacteristics_(this)
            arguments
                this (1,1) controllib.chart.editor.internal.nichols.NicholsEditorResponseDataSource
            end
            characteristics = createCharacteristics_@controllib.chart.internal.data.response.NicholsResponseDataSource(this);
            c1 = controllib.chart.editor.internal.compensator.ZeroData(this);
            c2 = controllib.chart.editor.internal.compensator.PoleData(this);
            c3 = controllib.chart.editor.internal.compensator.ComplexConjugateZeroData(this);
            c4 = controllib.chart.editor.internal.compensator.ComplexConjugatePoleData(this);
            characteristics = [characteristics,c1,c2,c3,c4];
        end
    end
end


