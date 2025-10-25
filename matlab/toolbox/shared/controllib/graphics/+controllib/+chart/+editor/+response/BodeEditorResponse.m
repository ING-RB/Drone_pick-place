classdef BodeEditorResponse < controllib.chart.response.BodeResponse
    % controllib.editor.response.BodeEditorResponse

    % Copyright 2024 The MathWorks, Inc.

    %% Properties
    properties (Dependent, AbortSet, SetObservable)
        % "Compensator": struct
        % Values used to generate data
        Compensator
    end

    properties (Access=protected)
        CompensatorZeros
        CompensatorPoles
        CompensatorGain
    end
    
    %% Constructor
    methods
        function this = BodeEditorResponse(plant,compensator,bodeResponseOptionalInputs,baseResponseOptionalInputs)
            arguments
                plant DynamicSystem
                compensator (1,1) zpk
                bodeResponseOptionalInputs.Frequency (:,1) ...
                    {controllib.chart.internal.utils.validators.mustBeFrequencySpec} = []
                bodeResponseOptionalInputs.NumberOfStandardDeviations (1,1) double = get(bodeoptions('cstprefs'),'ConfidenceRegionNumberSD')
                baseResponseOptionalInputs.?controllib.chart.internal.foundation.BaseResponseOptionalInputs
            end

            % Create model source if model provided as first argument
            plant = controllib.chart.internal.utils.ModelSource(plant);

            bodeResponseOptionalInputs = namedargs2cell(bodeResponseOptionalInputs);
            baseResponseOptionalInputs = namedargs2cell(baseResponseOptionalInputs);
            this@controllib.chart.response.BodeResponse(plant,baseResponseOptionalInputs{:},bodeResponseOptionalInputs{:});

            this.Type = "bodeeditor";
            this.CompensatorZeros = compensator.Z;
            this.CompensatorPoles = compensator.P;
            this.CompensatorGain = compensator.K;

            build(this);
        end
    end

    %% Get/Set
    methods
        % Compensator
        function Compensator = get.Compensator(this)
            Compensator = zpk(this.CompensatorZeros,this.CompensatorPoles,this.CompensatorGain,this.Model.Ts,TimeUnit=this.Model.TimeUnit);
        end

        function set.Compensator(this,Compensator)
            arguments
                this (1,1) controllib.chart.editor.response.BodeEditorResponse
                Compensator (1,1) zpk
            end
            this.CompensatorZeros = Compensator.Z;
            this.CompensatorPoles = Compensator.P;
            this.CompensatorGain = Compensator.K;

            markDirtyAndUpdate(this);
        end
    end

    %% Static methods
    methods (Static)
        function modifyIncomingSerializationContent(thisSerialized)
            modifyIncomingSerializationContent@controllib.chart.response.BodeResponse(thisSerialized);
        end

        function this = finalizeIncomingObject(this)
            this = finalizeIncomingObject@controllib.chart.response.BodeResponse(this);
        end

        function modifyOutgoingSerializationContent(thisSerialized,this)
            modifyOutgoingSerializationContent@controllib.chart.response.BodeResponse(thisSerialized,this);
        end
    end

    %% Protected methods (override in subclass)
    methods (Access = protected)
        function initializeData(this)
            arguments
                this (1,1) controllib.chart.editor.response.BodeEditorResponse
            end
            if this.Type == "bodeeditor" %build after comp defined
                this.ResponseData = controllib.chart.editor.internal.bode.BodeEditorResponseDataSource(this.Model,...
                    CompensatorZeros=this.CompensatorZeros,CompensatorPoles=this.CompensatorPoles,...
                    CompensatorGain=this.CompensatorGain,Frequency=this.FrequencySpec,...
                    NumberOfStandardDeviations=this.NumberOfStandardDeviations_I);
            end
        end

        function updateData(this)
            arguments
                this (1,1) controllib.chart.editor.response.BodeEditorResponse
            end
            options.CompensatorZeros = this.CompensatorZeros;
            options.CompensatorPoles = this.CompensatorPoles;
            options.CompensatorGain = this.CompensatorGain;
            optionsCell = namedargs2cell(options);
            updateData@controllib.chart.response.BodeResponse(this,optionsCell{:});
        end
    end

    %% Hidden static methods
    methods (Hidden,Static)
        function dataProperties = getDataProperties()
            dataProperties = ["SourceData","Compensator"];
        end
    end
end

