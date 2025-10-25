classdef NicholsEditorResponse < controllib.chart.response.NicholsResponse
    % controllib.editor.response.NicholsEditorResponse

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
        function this = NicholsEditorResponse(plant,compensator,nicholsResponseOptionalInputs,baseResponseOptionalInputs)
            arguments
                plant DynamicSystem
                compensator (1,1) zpk
                nicholsResponseOptionalInputs.Frequency (:,1) ...
                    {controllib.chart.internal.utils.validators.mustBeFrequencySpec} = []
                baseResponseOptionalInputs.?controllib.chart.internal.foundation.BaseResponseOptionalInputs
            end

            % Create model source if model provided as first argument
            plant = controllib.chart.internal.utils.ModelSource(plant);

            nicholsResponseOptionalInputs = namedargs2cell(nicholsResponseOptionalInputs);
            baseResponseOptionalInputs = namedargs2cell(baseResponseOptionalInputs);
            this@controllib.chart.response.NicholsResponse(plant,baseResponseOptionalInputs{:},nicholsResponseOptionalInputs{:});

            this.Type = "nicholseditor";
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
                this (1,1) controllib.chart.editor.response.NicholsEditorResponse
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
            modifyIncomingSerializationContent@controllib.chart.response.NicholsResponse(thisSerialized);
        end

        function this = finalizeIncomingObject(this)
            this = finalizeIncomingObject@controllib.chart.response.NicholsResponse(this);
        end

        function modifyOutgoingSerializationContent(thisSerialized,this)
            modifyOutgoingSerializationContent@controllib.chart.response.NicholsResponse(thisSerialized,this);
        end
    end

    %% Protected methods (override in subclass)
    methods (Access = protected)
        function initializeData(this)
            arguments
                this (1,1) controllib.chart.editor.response.NicholsEditorResponse
            end
            if this.Type == "nicholseditor" %build after comp defined
                this.ResponseData = controllib.chart.editor.internal.nichols.NicholsEditorResponseDataSource(this.Model,...
                    CompensatorZeros=this.CompensatorZeros,CompensatorPoles=this.CompensatorPoles,...
                    CompensatorGain=this.CompensatorGain,Frequency=this.FrequencySpec);
            end
        end

        function updateData(this)
            arguments
                this (1,1) controllib.chart.editor.response.NicholsEditorResponse
            end
            options.CompensatorZeros = this.CompensatorZeros;
            options.CompensatorPoles = this.CompensatorPoles;
            options.CompensatorGain = this.CompensatorGain;
            optionsCell = namedargs2cell(options);
            updateData@controllib.chart.response.NicholsResponse(this,optionsCell{:});
        end
    end

    %% Hidden static methods
    methods (Hidden,Static)
        function dataProperties = getDataProperties()
            dataProperties = ["SourceData","Compensator"];
        end
    end
end

