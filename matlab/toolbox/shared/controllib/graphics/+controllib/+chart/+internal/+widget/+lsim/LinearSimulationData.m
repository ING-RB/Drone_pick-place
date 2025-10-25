classdef LinearSimulationData < matlab.mixin.SetGet
    % Data class for Linear Simulation Dialog
    
    % Copyright 2023-2024 The MathWorks, Inc.

    %% Properties
    properties (SetObservable,AbortSet)
        StartTimes
        Intervals
        SimulationSamples
        MinimumSignalIntervals
        Interpolations
        InitialStates
    end

    properties (Dependent,SetObservable,AbortSet)
        TimeVectors
    end

    properties (Dependent,SetAccess=private)
        NumSystems
        SystemNames
        StateNames
        ChannelNames
        NInputs
        Responses
    end
    
    properties (Access = private)
        InputSignals_I
        Chart
    end
    
    %% Events
    events
        InputSignalsSynced
    end
    
    %% Constructor
    methods
        function this = LinearSimulationData(chart)
            arguments
                chart (1,1) controllib.chart.internal.foundation.OutputPlot
            end
            this.Chart = chart;
            resetInitialStates(this);
            if isa(this.Chart,'controllib.chart.LSimPlot')
                nInputs = arrayfun(@(x) x.NInputs,this.Chart.Responses);
                if ~isempty(nInputs)
                    this.StartTimes = zeros(length(nInputs),1);
                    this.Intervals = zeros(length(nInputs),1);
                    this.SimulationSamples = zeros(length(nInputs),1);
                    this.MinimumSignalIntervals = zeros(length(nInputs),1);
                    inputSignals = cell(length(nInputs),1);
                    for ii = 1:length(nInputs)
                        signalSpec = controllib.chart.internal.widget.lsim.createEmptySignal();
                        inputSignals{ii} = repmat(signalSpec,nInputs(ii),1);
                    end
                    this.InputSignals_I = inputSignals;
                end
                resetInterpolations(this);
                inputSignals = cell(this.NumSystems,1);
                for ii = 1:this.NumSystems
                    if ~isempty(this.Responses(ii).SourceData.Time)
                        allIntervals = this.Responses(ii).SourceData.Time(2:end)-this.Responses(ii).SourceData.Time(1:end-1);
                        interval = max(allIntervals);
                        tolerance = 10000*eps;
                        n = -floor(log10(tolerance));
                        this.StartTimes(ii) = round(this.Responses(ii).SourceData.Time(1),n);
                        this.Intervals(ii) = round(interval,n);
                        this.SimulationSamples(ii) = length(this.Responses(ii).SourceData.Time);
                        this.MinimumSignalIntervals(ii) = round(min(allIntervals),n) + 1;
                    end
                    if ~isempty(this.Responses(ii).SourceData.InputSignal)
                        inputSignals{ii} = this.createNewInputSignal(this.Responses(ii));
                    else
                        nInputs = this.NInputs(ii);
                        signalSpec = controllib.chart.internal.widget.lsim.createEmptySignal();
                        inputSignals{ii} = repmat(signalSpec,nInputs,1);
                    end
                end
                setInputSignals(this,inputSignals,1:this.NumSystems)               
            end    
        end
    end

    %% Public methods
    methods
        % Responses
        function addResponses(this,responses)
            nSys = length(responses);
            newInitialStates = cell(nSys,1);
            for ii = 1:length(newInitialStates)
                try
                    sz = order(responses(ii).SourceData.Model(:,:,1));
                    states = zeros(sz,1);
                    curStates = responses(ii).InitialState;
                    states(1:min(sz,length(curStates))) = curStates(1:min(sz,length(curStates)));
                catch %frd
                    states = responses(ii).InitialState;
                end
                newInitialStates{ii} = states;
            end
            this.InitialStates = [this.InitialStates;newInitialStates];
            if isa(this.Chart,'controllib.chart.LSimPlot')
                this.StartTimes = [this.StartTimes;zeros(nSys,1)];
                this.Intervals = [this.Intervals;zeros(nSys,1)];
                this.SimulationSamples = [this.SimulationSamples;zeros(nSys,1)];
                this.MinimumSignalIntervals = [this.MinimumSignalIntervals;zeros(nSys,1)];
                inputSignals = cell(nSys,1);
                for ii = 1:nSys
                    if ~isempty(responses(ii).SourceData.Time)
                        this.TimeVectors{this.NumSystems-nSys+ii} = responses(ii).SourceData.Time;
                    end
                    if ~isempty(responses(ii).SourceData.InputSignal)
                        inputSignals{ii} = this.createNewInputSignal(responses(ii));
                    else
                        nInputs = responses(ii).NInputs;
                        signalSpec = controllib.chart.internal.widget.lsim.createEmptySignal();
                        inputSignals{ii} = repmat(signalSpec,nInputs,1);
                    end
                    this.Interpolations{this.NumSystems-nSys+ii} = responses(ii).SourceData.InterpolationMethod;
                end
                setInputSignals(this,inputSignals,this.NumSystems-nSys+1:this.NumSystems);
            end
        end

        function removeResponse(this,idx)
            this.InitialStates(idx) = [];
            if isa(this.Chart,'controllib.chart.LSimPlot')
                this.StartTimes(idx) = [];
                this.Intervals(idx) = [];
                this.SimulationSamples(idx) = [];
                this.MinimumSignalIntervals(idx) = [];
                this.Interpolations(idx) = [];
                removeInputSignals(this,idx);
            end
        end

        function updateResponse(this,idx)
            try
                sz = order(this.Responses(idx).SourceData.Model(:,:,1));
                states = zeros(sz,1);
                curStates = this.Responses(idx).InitialState;
                states(1:min(sz,length(curStates))) = curStates(1:min(sz,length(curStates)));
            catch %frd
                states = this.Responses(idx).InitialState;
            end
            this.InitialStates{idx} = states;
            if isa(this.Chart,'controllib.chart.LSimPlot')
                inputSignals = cell(this.NumSystems,1);
                if ~isempty(this.Responses(idx).SourceData.Time)
                    this.TimeVectors{idx} = this.Responses(idx).SourceData.Time;
                end
                if ~isempty(this.Responses(idx).SourceData.InputSignal)
                    inputSignals{idx} = this.createNewInputSignal(this.Responses(idx));
                else
                    nInputs = this.NInputs(idx);
                    signalSpec = controllib.chart.internal.widget.lsim.createEmptySignal();
                    inputSignals{idx} = repmat(signalSpec,nInputs,1);
                end
                setInputSignals(this,inputSignals,1:this.NumSystems);
                this.Interpolations{idx} = this.Responses(idx).SourceData.InterpolationMethod;
            end
        end
        
        % Reset Signals
        function resetSignal(this,systemIdx,idx)
            if nargin < 3
                idx = 1:length(this.InputSignals{systemIdx});
            end
            signalSpec = controllib.chart.internal.widget.lsim.createEmptySignal();
            signals = repmat(signalSpec,1,length(idx));
            updateInputSignals(this,signals,systemIdx,idx);
        end

        % Update Signals
        function updateInputSignals(this,signals,systemIdx,idx)
            if nargin < 4
                idx = 1:this.getNumberOfInputs(systemIdx);
            end
            this.InputSignals_I{systemIdx}(idx) = signals;
            allIntervals = [this.InputSignals_I{systemIdx}.Interval];
            this.MinimumSignalIntervals(systemIdx) = min(allIntervals(2:2:end) - allIntervals(1:2:end)) + 1;
        end

        % Sync Signals
        function syncInputSignals(this,systemIdx)
            for k=1:length(this.InputSignals_I{systemIdx})
                % Don't modify empty rows
                if length(this.InputSignals_I{systemIdx}(k).Interval)>=2
                    this.InputSignals_I{systemIdx}(k).Interval = [this.InputSignals_I{systemIdx}(k).Interval(1), ...
                        this.InputSignals_I{systemIdx}(k).Interval(1)+this.MinimumSignalIntervals(systemIdx)-1];
                end
            end
            this.SimulationSamples(systemIdx) = this.MinimumSignalIntervals(systemIdx);
            notify(this,'InputSignalsSynced');
        end

        % Resize Signals
        function resizeInputSignals(this)
            for ii = 1:this.NumSystems
                nInputs = this.NInputs(ii);
                if nInputs < length(this.InputSignals_I{ii})
                    this.InputSignals_I{ii} = this.InputSignals_I{ii}(1:nInputs);
                elseif nInputs > length(this.InputSignals_I{ii})
                    signalSpec = controllib.chart.internal.widget.lsim.createEmptySignal();
                    newSignals = repmat(signalSpec,nInputs-length(this.InputSignals_I{ii}),1);
                    this.InputSignals_I{ii} = [this.InputSignals_I{ii};newSignals];
                end
            end
        end

        function resetInitialStates(this)
            this.InitialStates = cell(this.NumSystems,1);
            for ii = 1:this.NumSystems
                try
                    sz = order(this.Responses(ii).SourceData.Model(:,:,1));
                    states = zeros(sz,1);
                    curStates = this.Responses(ii).InitialState;
                    states(1:min(sz,length(curStates))) = curStates(1:min(sz,length(curStates)));
                catch %frd
                    states = this.Responses(ii).InitialState;
                end
                this.InitialStates{ii} = states;
            end
        end

        function resetInterpolations(this)
            isLSimResponse = arrayfun(@(x) isa(x,'controllib.chart.response.LinearSimulationResponse'),this.Responses);
            this.Interpolations = arrayfun(@(x) x.SourceData.InterpolationMethod,this.Responses(isLSimResponse),UniformOutput=false);
        end
    end
    
    %% Get/Set
    methods
        % Responses
        function Responses = get.Responses(this)
            Responses = this.Chart.Responses;
            if ~isempty(Responses)
                Responses = Responses(isvalid(Responses));
            end
        end

        % NumSystems
        function NumSystems = get.NumSystems(this)
            NumSystems = length(this.Responses);
        end

        % SystemNames
        function SystemNames = get.SystemNames(this)
            SystemNames = arrayfun(@(x) x.Name,this.Responses);
        end

        % StateNames
        function StateNames = get.StateNames(this)
            StateNames = cell(this.NumSystems,1);
            for ii = 1:this.NumSystems
                try
                    stateName = this.Responses(ii).Model.StateName;
                catch %sparse,frd
                    try
                        sz = order(this.Responses(ii).Model(:,:,1));
                    catch %frd
                        sz = length(this.Responses(ii).InitialState);
                    end
                    stateName = cell([sz 1]);
                end
                for jj = 1:length(stateName)
                    if isempty(stateName{jj})
                        stateName{jj} = ['state' int2str(jj)];
                    end
                end
                StateNames{ii} = stateName;
            end
        end

        % ChannelNames
        function ChannelNames = get.ChannelNames(this)
            isLSimResponse = arrayfun(@(x) isa(x,'controllib.chart.response.LinearSimulationResponse'),this.Responses);
            ChannelNames = arrayfun(@(x) x.Model(:,:,1).InputName,this.Responses(isLSimResponse),UniformOutput=false);
        end

        % NInputs
        function NInputs = get.NInputs(this)
            isLSimResponse = arrayfun(@(x) isa(x,'controllib.chart.response.LinearSimulationResponse'),this.Responses);
            NInputs = arrayfun(@(x) x.NInputs,this.Responses(isLSimResponse));
        end

        % TimeVector
        function TimeVectors = get.TimeVectors(this)
            TimeVectors = cell(size(this.StartTimes));
            for ii = 1:length(this.StartTimes)
                if this.SimulationSamples(ii) == 0
                    TimeVectors{ii} = [];
                else
                    TimeVectors{ii} = this.StartTimes(ii) + (0:this.SimulationSamples(ii)-1)*this.Intervals(ii);
                end
            end
        end

        function set.TimeVectors(this,TimeVectors)
            % Set time properties based on evenly spaced vector
            initialized = cellfun(@(x) ~isempty(x),this.TimeVectors);
            if any(cellfun(@isempty,TimeVectors(initialized))) ||...
                    ~all(cellfun(@isnumeric,TimeVectors(initialized))) ||...
                    ~all(cellfun(@(x) all(isfinite(x)),TimeVectors(initialized)))
                throw(MException('Control:lsimgui:InvalidTimeVector',...
                    getString(message('Controllib:gui:errTimeVectorRequirement3'))));
            end
            this.StartTimes = zeros(this.NumSystems,1);
            this.Intervals = zeros(this.NumSystems,1);
            this.SimulationSamples = zeros(this.NumSystems,1);
            this.MinimumSignalIntervals = zeros(this.NumSystems,1);
            for ii = 1:length(TimeVectors)
                if initialized(ii)
                    allIntervals = TimeVectors{ii}(2:end)-TimeVectors{ii}(1:end-1);
                    interval = max(allIntervals);
                    tolerance = 10000*eps;
                    if interval-min(allIntervals)<tolerance && interval>0
                        n = -floor(log10(tolerance));
                        this.StartTimes(ii) = round(TimeVectors{ii}(1),n);
                        this.Intervals(ii) = round(interval,n);
                        this.SimulationSamples(ii) = length(TimeVectors{ii});
                        this.MinimumSignalIntervals(ii) = round(min(allIntervals),n) + 1;
                    else
                        throw(MException('Control:lsimgui:InvalidTimeVector',...
                            getString(message('Controllib:gui:errTimeVectorRequirement1'))));
                    end
                end
            end
        end

        % InputSignals
        function InputSignals = getInputSignals(this,systemIdx)
            InputSignals = this.InputSignals_I{systemIdx};
        end

        function setInputSignals(this,InputSignals,systemIdx)
            for ii = 1:length(systemIdx)
                this.InputSignals_I(systemIdx(ii)) = InputSignals(ii);
            end
        end

        function removeInputSignals(this,systemIdx)
            this.InputSignals_I(systemIdx) = [];
        end
    end

    %% Private static methods
    methods (Static, Access = private)
        function InputSignalData = createNewInputSignal(response)
            % Create new input from command line call
            signalSpec = controllib.chart.internal.widget.lsim.createEmptySignal();
            InputSignalData = repmat(signalSpec,response.NInputs,1);
            for ii = 1:response.NInputs
                InputSignalData(ii).Value = response.SourceData.InputSignal;
                InputSignalData(ii).Source = 'ini';
                InputSignalData(ii).Column = ii;
                InputSignalData(ii).Name = 'default';
                InputSignalData(ii).Interval = [1 size(response.SourceData.InputSignal,1)];
                InputSignalData(ii).Size = size(response.SourceData.InputSignal);
            end
        end
    end
end



