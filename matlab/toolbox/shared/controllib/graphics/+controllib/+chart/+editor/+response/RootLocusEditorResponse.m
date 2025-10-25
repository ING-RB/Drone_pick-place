classdef RootLocusEditorResponse < controllib.chart.response.RootLocusResponse
    % controllib.editor.response.RootLocusEditorResponse

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
        function this = RootLocusEditorResponse(plant,compensator,rootLocusOptionalInputs,baseResponseOptionalInputs)
            arguments
                plant DynamicSystem
                compensator (1,1) zpk
                rootLocusOptionalInputs.FeedbackGains (:,1) double = []
                baseResponseOptionalInputs.?controllib.chart.internal.foundation.BaseResponseOptionalInputs
            end

            % Create model source if model provided as first argument
            plant = controllib.chart.internal.utils.ModelSource(plant);

            rootLocusOptionalInputs = namedargs2cell(rootLocusOptionalInputs);
            baseResponseOptionalInputs = namedargs2cell(baseResponseOptionalInputs);
            this@controllib.chart.response.RootLocusResponse(plant,baseResponseOptionalInputs{:},rootLocusOptionalInputs{:});

            this.Type = "rlocuseditor";
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
                this (1,1) controllib.chart.editor.response.RootLocusEditorResponse
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
            modifyIncomingSerializationContent@controllib.chart.response.RootLocusResponse(thisSerialized);
        end

        function this = finalizeIncomingObject(this)
            this = finalizeIncomingObject@controllib.chart.response.RootLocusResponse(this);
        end

        function modifyOutgoingSerializationContent(thisSerialized,this)
            modifyOutgoingSerializationContent@controllib.chart.response.RootLocusResponse(thisSerialized,this);
        end
    end

    %% Protected methods (override in subclass)
    methods (Access = protected)
        function initializeData(this)
            arguments
                this (1,1) controllib.chart.editor.response.RootLocusEditorResponse
            end
            if this.Type == "rlocuseditor" %build after comp defined
                this.ResponseData = controllib.chart.editor.internal.rlocus.RootLocusEditorResponseDataSource(this.Model,...
                    CompensatorZeros=this.CompensatorZeros,CompensatorPoles=this.CompensatorPoles,...
                    CompensatorGain=this.CompensatorGain,FeedbackGains=this.FeedbackGains);
            end
        end

        function updateData(this)
            arguments
                this (1,1) controllib.chart.editor.response.RootLocusEditorResponse
            end
            options.CompensatorZeros = this.CompensatorZeros;
            options.CompensatorPoles = this.CompensatorPoles;
            options.CompensatorGain = this.CompensatorGain;
            optionsCell = namedargs2cell(options);
            updateData@controllib.chart.response.RootLocusResponse(this,optionsCell{:});
        end
    end

    %% Hidden static methods
    methods (Hidden,Static)
        function dataProperties = getDataProperties()
            dataProperties = ["SourceData","Compensator"];
        end
    end
end

