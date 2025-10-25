classdef RootLocusEditorResponseDataSource < controllib.chart.internal.data.response.RootLocusResponseDataSource
    % controllib.editor.internal.bode.RootLocusEditorResponseDataSource

    % Copyright 2024 The MathWorks, Inc.

    %% Properties
    properties (SetAccess = protected)
        CompensatorZeros
        CompensatorPoles
        CompensatorGain
        FixedPlantModelSource
        FixedPlantModelData
    end

    properties (Dependent,SetAccess=private)
        RootLocusCompensatorGain
        RootLocusCompensatorZeros
        RootLocusCompensatorPoles
        RootLocusCompensatorComplexConjugateZeros
        RootLocusCompensatorComplexConjugatePoles
    end

    properties (Dependent,Access=private)
        Compensator
    end

    %% Constructor
    methods
        function this = RootLocusEditorResponseDataSource(model,rootLocusEditorResponseOptionalArguments,rootLocusOptionalArguments)
            arguments
                model
                rootLocusEditorResponseOptionalArguments.CompensatorZeros = []
                rootLocusEditorResponseOptionalArguments.CompensatorPoles = []
                rootLocusEditorResponseOptionalArguments.CompensatorGain = 1
                rootLocusOptionalArguments.FeedbackGains = []
            end
            rootLocusOptionalArguments = namedargs2cell(rootLocusOptionalArguments);            
            this@controllib.chart.internal.data.response.RootLocusResponseDataSource(model,rootLocusOptionalArguments{:});

            this.Type = "RootLocusEditorResponse";
            this.CompensatorZeros = rootLocusEditorResponseOptionalArguments.CompensatorZeros;
            this.CompensatorPoles = rootLocusEditorResponseOptionalArguments.CompensatorPoles;
            this.CompensatorGain = rootLocusEditorResponseOptionalArguments.CompensatorGain;
            updateFixedPlantModelDataAndSources(this);

            % Update response
            update(this);
        end
    end

    %% Get/Set
    methods
        % RootLocusCompensatorGain
        function RootLocusCompensatorGain = get.RootLocusCompensatorGain(this)
            arguments
                this (1,1) controllib.chart.editor.internal.rlocus.RootLocusEditorResponseDataSource
            end            
            RootLocusCompensatorGain = getCharacteristics(this,"CompensatorGain");
        end

        % RootLocusCompensatorZeros
        function RootLocusCompensatorZeros = get.RootLocusCompensatorZeros(this)
            arguments
                this (1,1) controllib.chart.editor.internal.rlocus.RootLocusEditorResponseDataSource
            end            
            RootLocusCompensatorZeros = getCharacteristics(this,"CompensatorZeros");
        end

        % RootLocusCompensatorPoles
        function RootLocusCompensatorPoles = get.RootLocusCompensatorPoles(this)
            arguments
                this (1,1) controllib.chart.editor.internal.rlocus.RootLocusEditorResponseDataSource
            end            
            RootLocusCompensatorPoles = getCharacteristics(this,"CompensatorPoles");
        end

        % RootLocusCompensatorComplexConjugatePoles
        function RootLocusCompensatorComplexConjugatePoles = get.RootLocusCompensatorComplexConjugatePoles(this)
            arguments
                this (1,1) controllib.chart.editor.internal.rlocus.RootLocusEditorResponseDataSource
            end            
            RootLocusCompensatorComplexConjugatePoles = getCharacteristics(this,"CompensatorComplexConjugatePoles");
        end

        % RootLocusCompensatorComplexConjugateZeros
        function RootLocusCompensatorComplexConjugateZeros = get.RootLocusCompensatorComplexConjugateZeros(this)
            arguments
                this (1,1) controllib.chart.editor.internal.rlocus.RootLocusEditorResponseDataSource
            end            
            RootLocusCompensatorComplexConjugateZeros = getCharacteristics(this,"CompensatorComplexConjugateZeros");
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
            if isempty(this.CompensatorGain)
                compNoGain = zpk(1); %init
            else
                compNoGain = this.Compensator*zpk([],[],1/this.CompensatorGain,this.Model.Ts,TimeUnit=this.Model.TimeUnit);
            end
            model = this.Model*compNoGain;
            modelValue = getValue(model,'usample');
        end

        function updateFixedPlantModelDataAndSources(this)
            %^ Get model source and data
            this.FixedPlantModelSource = getPlotSource(this.Model,this.Model.Name);
            this.FixedPlantModelData = getModelData(this.FixedPlantModelSource);
        end

        function updateData(this,rootLocusEditorResponseOptionalArguments,modelResponseOptionalInputs,rootLocusOptionalArguments)
            arguments
                this (1,1) controllib.chart.editor.internal.rlocus.RootLocusEditorResponseDataSource
                rootLocusEditorResponseOptionalArguments.CompensatorZeros = this.CompensatorZeros
                rootLocusEditorResponseOptionalArguments.CompensatorPoles = this.CompensatorPoles
                rootLocusEditorResponseOptionalArguments.CompensatorGain = this.CompensatorGain
                modelResponseOptionalInputs.Model = this.Model
                rootLocusOptionalArguments.FeedbackGains = this.FeedbackGainsInput
            end
            if this.Type ~= "RootLocusEditorResponse" %wait til comp defined
                return;
            end
            try
                sysList.System = modelResponseOptionalInputs.Model;
                ParamList = {rootLocusOptionalArguments.FeedbackGains};
                [sysList,gains] =  DynamicSystem.checkRootLocusInputs(sysList,ParamList);
                modelResponseOptionalInputs.Model = sysList.System;
                rootLocusOptionalArguments.FeedbackGains = gains;
                if isempty(sysList.System)
                    error(message('Controllib:plots:PlotEmptyModel'))
                end
            catch ME
                this.DataException = ME;
            end
            this.FeedbackGainsInput = rootLocusOptionalArguments.FeedbackGains;
            this.CompensatorZeros = rootLocusEditorResponseOptionalArguments.CompensatorZeros;
            this.CompensatorPoles = rootLocusEditorResponseOptionalArguments.CompensatorPoles;
            this.CompensatorGain = rootLocusEditorResponseOptionalArguments.CompensatorGain;
            updateData@controllib.chart.internal.data.response.ModelResponseDataSource(this,Model=modelResponseOptionalInputs.Model)
            
            % Pole/zero map for individual I/O pairs
            this.SystemPoles = repmat({NaN},this.NResponses,1);
            this.SystemZeros = repmat({NaN},this.NResponses,1);
            this.Gains = repmat({NaN},this.NResponses,1);
            this.Roots = repmat({NaN},this.NResponses,1);
            this.SystemGains = repmat({NaN},this.NResponses,1);
            % Focus
            this.RealAxisFocus = repmat({{[NaN NaN]}},this.NResponses,1);
            this.ImaginaryAxisFocus = repmat({{[NaN NaN]}},this.NResponses,1);
            if ~isempty(this.DataException)
                return;
            end

            updateFixedPlantModelDataAndSources(this);
            try
                for ka = 1:this.NResponses
                    [rk,gk,xfocus,yfocus,info] = getRootLocusData_(this.ModelValue,...
                                                        this.FeedbackGainsInput,ka);
                    if ~all(isnan(rk))
                        % model is finite
                        rk = rk.';
                        gk = gk(:);
                        if info.InverseFlag
                            sz = info.Pole;
                            sp = info.Zero;
                            g = 1/info.Gain;
                        else
                            sz = info.Zero;
                            sp = info.Pole;
                            g = info.Gain;
                        end
                        % Compute system gains
                        gains = zeros(size(rk));
                        for ii = 1:size(rk,1)
                            for jj = 1:size(rk,2)
                                z = rk(ii,jj);
                                den = g*prod(sz-z);
                                if den == 0
                                    gains(ii,jj) = Inf;
                                else
                                    gains(ii,jj) = abs(prod(sp-z)/den);
                                end
                                sn = sign(gk(ii));
                                if sn~=0
                                    gains(ii,jj) = gains(ii,jj)*sn;
                                end
                            end
                        end
                    else
                        % model is infinite
                        gains = NaN;
                        sz = NaN;
                        sp = NaN;
                    end
                    this.Gains{ka} = gk;
                    this.Roots{ka} = rk;
                    this.SystemZeros{ka} = sz;
                    this.SystemPoles{ka} = sp;
                    this.SystemGains{ka} = gains;

                    % Include tunable PZGroups in focus
                    pzGroups = [this.RootLocusCompensatorZeros;this.RootLocusCompensatorPoles;...
                        this.RootLocusCompensatorComplexConjugateZeros;this.RootLocusCompensatorComplexConjugatePoles];
                    for ii = 1:length(pzGroups)
                        Ls = pzGroups(ii).Locations;
                        for jj = 1:numel(Ls)
                            L = Ls{jj};
                            if ~isempty(L)
                                xfocus(1) = min(xfocus(1),min(real(L)));
                                xfocus(2) = max(xfocus(2),max(real(L)));
                                yfocus(1) = min(yfocus(1),min(imag(L)));
                                yfocus(2) = max(yfocus(2),max(imag(L)));
                            end
                        end
                    end

                    this.RealAxisFocus{ka} = {xfocus};
                    this.ImaginaryAxisFocus{ka} = {yfocus};
                end
            catch ME
                this.DataException = ME;
            end
        end

        function characteristics = createCharacteristics_(this)
            arguments
                this (1,1) controllib.chart.editor.internal.rlocus.RootLocusEditorResponseDataSource
            end
            characteristics = createCharacteristics_@controllib.chart.internal.data.response.RootLocusResponseDataSource(this);
            c1 = controllib.chart.editor.internal.compensator.GainData(this);
            c2 = controllib.chart.editor.internal.compensator.ZeroData(this);
            c3 = controllib.chart.editor.internal.compensator.PoleData(this);
            c4 = controllib.chart.editor.internal.compensator.ComplexConjugateZeroData(this);
            c5 = controllib.chart.editor.internal.compensator.ComplexConjugatePoleData(this);
            characteristics = [characteristics,c1,c2,c3,c4,c5];
        end
    end
end


