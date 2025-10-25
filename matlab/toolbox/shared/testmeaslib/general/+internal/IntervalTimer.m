classdef (ConstructOnLoad) IntervalTimer < handle
% A simple timer that fires events at a regular interval.
%
% Usages:
%    obj = internal.IntervalTimer(PERIOD);
%
%    PERIOD is the desired period in seconds. It is optional and
%    defaults to 1.0.
%
% Example:
%    t = internal.IntervalTimer(0.002);
%    lh = event.listener(t,'Executing',@(source,data) disp(data));
%    start(t);
%
%    % When done
%    clear lh;
%    clear t;
%
% Notes:
%    This timer is similar to the MATLAB timer configured as:
%        'ExecutionMode' = 'fixedRate'
%        'BusyMode' = 'drop'
%        'StartDelay' = period
%    The major difference is that listeners associated with this
%    object's event fire when MATLAB is idle or during pause or
%    drawnow resulting in more predictable execution of listeners.

% Copyright 2010-2024 The MathWorks, Inc.

%% Public properties/events
    properties(SetAccess='public',GetAccess='public')
        Period
    end

    properties(SetAccess='private',GetAccess='public', Transient)
        % The average period since timer start or a change in Period.
        AveragePeriod = NaN;
    end

    events(NotifyAccess='private')
        Starting
        Executing
        Stopped
    end

    %% Lifetime
    methods
        function obj = IntervalTimer(period)
        % IntervalTimer creates a timer that fires an event at a given interval.

        % If no period, set a reasonable default.
            if nargin == 0
                period = 1.0;
            end

            % Use matlabroot for the base plugin directory instead of toolboxdir.
            % Because the IntervalTimer ships with the MCR it will always be located under matlabroot.
            pluginDir = toolboxdir(fullfile('shared','testmeaslib','general','bin',...
                                            computer('arch')));

            % Initialize channel that is the source of events.
            obj.Channel = matlabshared.asyncio.internal.Channel(fullfile(pluginDir, 'intervaltimer'),...
                                                                fullfile(pluginDir, 'intervaltimermlconverter'),...
                                                                Options = [], StreamLimits = [0 0]);

            % Set the period.
            obj.Period = period;
        end
    end

    methods(Access='private')
        function delete(obj)
            stop(obj);
            delete(obj.Channel);
        end
    end

    %% Getters/Setters
    methods
        function set.Period(obj, value)
            if(~isnumeric(value) || ...
               ~isscalar(value) || ...
               isinf(value) || ...
               isnan(value) || ...
               value < 0.002)
                error(message('testmeaslib:IntervalTimer:invalidPeriod'));
            end

            obj.Period = double(value);

            % Reset stats for calculating AveragePeriod.
            obj.Executions = 0; %#ok<MCSUP>
            obj.StartTime = datetime('now'); %#ok<MCSUP>

            % Update period of underlying object.
            args.Period = obj.Period;
            obj.Channel.execute('SetPeriod',args); %#ok<MCSUP>
        end

        function result = isRunning(obj)
            result = obj.Channel.isOpen();
        end
    end

    %% Operations
    methods
        function start(obj)
        % Already started?
            if obj.isRunning()
                return;
            end

            objWeakRef = matlab.lang.WeakReference(obj);
            % Register listener for timer execution.
            obj.CustomEventListener = event.listener(obj.Channel, 'Custom',...
                                                     @(source,data) objWeakRef.Handle.onCustomEvent(data.Type,data.Data));

            % Notify listeners about timer starting.
            notify(obj, 'Starting', internal.TimerInfo(0));

            % Reset stats for calculating AveragePeriod.
            obj.Executions = 0;
            obj.StartTime = datetime('now');

            % Start the timer.
            obj.Channel.open([]);
        end

        function stop(obj)

        % Already stopped?
            if ~obj.isRunning()
                return;
            end

            % Stop the timer.
            obj.Channel.close();

            % Notify listeners about timer stopped.
            notify(obj, 'Stopped', internal.TimerInfo(0));

            % Unregister listeners.
            delete(obj.CustomEventListener);
        end
    end

    %% Event Handlers
    methods(Access='private')
        function onCustomEvent(obj, ~, eventData)
        % Keep AveragePeriod up-to-date.
            obj.Executions = obj.Executions + 1;
            obj.AveragePeriod = seconds(datetime('now') - obj.StartTime)/obj.Executions;

            % Notify any listeners that want to know about timer events.
            notify(obj, 'Executing', internal.TimerInfo(eventData.ExecutionCount));
        end
    end

    %% Internal properties
    properties(Access = 'protected',Transient)
        Channel
        CustomEventListener
        StartTime
        Executions
    end
end
