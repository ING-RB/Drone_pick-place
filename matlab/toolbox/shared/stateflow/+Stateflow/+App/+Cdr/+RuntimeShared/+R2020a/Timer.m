classdef Timer < handle
%

%   Copyright 2017-2024 The MathWorks, Inc.

    properties
        timerObj
        pending
        active
        lastExpiredTimers
        timersOfCurrentExecutionStep
        exitCount
        queuedTimerEvents
        clockBegin
        referenceTime
        timerSetTime
        precision = 100;
        executingTimerCallbackStep = false;
        runtimeUtils
    end

    properties(WeakHandle)
        % This is a handle to an instance of the auto-generate class
        % from the .sfx file. There is no common base class besides
        % `handle`
        chartObj handle = matlab.lang.HandlePlaceholder.empty;
    end
    methods
        function this = Timer(obj)
            this.chartObj = obj;
            this.clockBegin = clock;
            this.referenceTime = 0;
            this.timersOfCurrentExecutionStep = [];
            this.lastExpiredTimers = [];
            this.active = [];
            this.pending = [];
            this.timerSetTime = 0;
            this.exitCount = containers.Map('KeyType', 'char', 'ValueType', 'double');
            this.queuedTimerEvents = {};
            this.runtimeUtils = Stateflow.App.Cdr.RuntimeShared.R2020a.InstanceIndRuntime.instance;
        end

        function timerCallback(this, src, event)
            this.runtimeUtils.temporalOperatorCallbackRouter(src, event);
        end
        function SetTimerInfo(this, src, ~)
            userData.sfxInstance = this.chartObj;
            userData.eventsActivated = [];
            if ~isempty(src)
                src.UserData = userData;
            end
        end

        function name = operatorMagicNumberToName(~, magicNumber)
            switch magicNumber
              case -1
                name = 'every';
              case -2
                name = 'after';
              otherwise
                assert(magicNumber == -3);
                name = 'at';
            end
        end

        function throwWarning(this, name, event, warnId)
            op = [name '(', num2str(event.dur) ', sec)'];
            SfObjectLink = ['<a href="matlab: Stateflow.App.Cdr.Utils.sfxCustomLink(''' this.chartObj.sfInternalObj.runtimeVar.chartName ''',' num2str( event.ssId) ',' num2str(0) ',' num2str( event.labelStartI) ',' num2str( event.labelEndI) ')">' op '</a>'];
            this.runtimeUtils.throwWarning(warnId,getString(message(warnId,SfObjectLink)));
        end

        function startNewTimer(this, ~)
            clockTm = clock;
            currentTime = etime(clockTm, this.clockBegin);
            if this.chartObj.sfInternalObj.executionTimeForTimers
                this.referenceTime = currentTime;
            end
            addTimersFromCurrentStepToPendingTimers(this);
            lowestPendingTimers = popLowestPendingTimers(this);

            if this.executingTimerCallbackStep
                % step is taken as part of timer callback as opposed to explicit user step
                this.executingTimerCallbackStep = false;
                this.lastExpiredTimers = this.active;
                this.active = lowestPendingTimers;
                deleteValidTimerObj(this);
            elseif ~isempty(this.timerObj) && this.timerObj.isvalid && ~isempty(this.active)
                %explicit user step
                %timer already active
                if isempty(lowestPendingTimers)
                    %no new timers are added during user explicit step
                    return;
                elseif this.active(1).pendingAt > lowestPendingTimers(1).pendingAt
                this.pending = [this.active this.pending];
                this.active = lowestPendingTimers;
                deleteValidTimerObj(this);
                else
                    %active timer still has lowest delay.
                    this.pending = [this.pending lowestPendingTimers];
                    return;
                end
            else
                %timer not active yet
                this.active = lowestPendingTimers;
                deleteValidTimerObj(this);
            end
            if isempty(this.active)
                % does not need timer to be active
                return;
            end
            newTimerDur = this.active(1).pendingAt - this.referenceTime;
            if newTimerDur < 0
                if ~isempty(this.active)
                    name = this.operatorMagicNumberToName(this.active(1).type);
                    warnId ='MATLAB:sfx:TemporalDeferred';
                    this.throwWarning(name, this.active(1), warnId);
                end
                newTimerDur = 0;
            end
            this.timerSetTime = currentTime;
            clearRuntimeH = [];
            if ~this.runtimeUtils.getTestingForMATLABInstall()

                if ~isdeployed
                    if exist(fullfile(matlabroot, 'toolbox', 'stateflow', 'stateflow', '+Stateflow', '+App', 'IsStateflowApp.m'), 'file')
                        if eval('Stateflow.App.Cdr.Utils.isStateflowLoaded()')
                            clearRuntimeH = eval('Stateflow.App.Cdr.Runtime.ClearRuntime.instance');
                        end
                    end
                end
            end
            if isempty(clearRuntimeH)
                clearRuntimeH = Stateflow.App.Cdr.RuntimeShared.R2020a.ClearRuntime.instance;
            end
            clearRuntimeH.activeTimerBasedSFXInstances{end+1} = this.chartObj;
            oldWarningState = warning;
            warning('off');
            this.timerObj = timer('StartDelay', newTimerDur, 'ExecutionMode', 'singleShot', ...
                                  'StartFcn', @ this.SetTimerInfo, ...
                                  'TimerFcn', @ this.timerCallback);
            start(this.timerObj);
            warning(oldWarningState);
        end
        function deleteValidTimerObj(this)
            if ~isempty(this.timerObj) && isvalid(this.timerObj)
                stop(this.timerObj);
            end
            delete(this.timerObj);
        end
        function removePendingTimer(this, name)
            if isKey(this.exitCount, name)
                this.exitCount(name) = this.exitCount(name) + 1;
            else
                this.exitCount(name) = 1;
            end
            %stop active and pending timers associated with name
            for i=length(this.active):-1:1
                if strcmp(name, this.active(i).name)
                    this.active(i) = [];
                end
            end
            for i=length(this.pending):-1:1
                if strcmp(name, this.pending(i).name)
                    this.pending(i) = [];
                end
            end

            %update the timer obj
            if isempty(this.active)
                deleteValidTimerObj(this);
            end
        end

        function addTimersFromCurrentStepToPendingTimers(this)
            for i=1:length(this.timersOfCurrentExecutionStep)
                curr = this.timersOfCurrentExecutionStep(i);
                if curr.pendingAt == 0 %for after and every in entry (not for every in during)
                    curr.pendingAt = curr.dur + this.referenceTime;
                    curr.referenceTime = this.referenceTime;
                end
                this.pending = [this.pending curr];
            end
            this.timersOfCurrentExecutionStep = [];
        end

        function lowestPending = popLowestPendingTimers(this)
            lowestPending = [];
            minVal = 100000000;
            tempPending = [];
            for i = 1:length(this.pending)
                if this.pending(i).pendingAt < minVal
                    minVal = this.pending(i).pendingAt;
                    lowestPending = this.pending(i);
                    if i ~= 1
                        tempPending = this.pending(1:i-1);
                    end
                elseif this.pending(i).pendingAt == minVal
                lowestPending = [lowestPending this.pending(i)]; %#ok<AGROW>
                else
                    tempPending = [tempPending this.pending(i)]; %#ok<AGROW>
                end
            end
            this.pending = tempPending;
        end
        function addPendingTimer(this, name, dur, eventVar, type, isDuring, ssId, labelStartI, labelEndI)
            curr.pendingAt = 0; %%absolute time. will be set correctly at the end of execution step.
            if isempty(dur)
                dur = 0;
            end
            curr.dur = dur / this.chartObj.sfInternalObj.clockSpeedUp;     %%relative time to the this.referenceTime
            curr.name = name;
            curr.eventVar = eventVar;
            curr.referenceTime = 0;
            curr.type = type;
            curr.isDuring = isDuring;
            curr.ssId = ssId;
            curr.labelStartI = labelStartI;
            curr.labelEndI = labelEndI;
            curr.exitCount = 0;
            if ~isfloat(curr.dur)
                curr.dur = double(curr.dur);
            end
            if round(curr.dur,3) ~= curr.dur %this is true if curr.dur has precision less than millisecond(i.e. < 10^-3)
                warnId = 'MATLAB:sfx:TimerPrecisionLost';
                name = this.operatorMagicNumberToName(type);
                this.throwWarning(name, curr, warnId);
                curr.dur = round(curr.dur,3);
            end
            this.timersOfCurrentExecutionStep = [curr this.timersOfCurrentExecutionStep];
        end
        function enableActiveEvents(this)
            for counterVar_SFX_67=1:length(this.active)
                eval(['this.chartObj.' this.active(counterVar_SFX_67).eventVar '.valid = true;';]);
            end
        end
        function enableQueuedEvents(this)
            if isempty(this.queuedTimerEvents)
                return;
            end
            queuedEvent = this.queuedTimerEvents{1};
            assert(~isempty(this.queuedTimerEvents), 'queue should not be empty');
            for counterVar_SFX_67=1:length(queuedEvent)
                eval(['this.chartObj.' queuedEvent(counterVar_SFX_67).eventVar '.valid = true;';]);
            end
        end
        function popQueuedTimerQueue(this)
            this.queuedTimerEvents(1) = [];
        end
        function saveCurrentExitCounts(this)
            for i = length(this.active):-1:1
                if isKey(this.exitCount, this.active(i).name)
                    this.active(i).exitCount = this.exitCount(this.active(i).name);
                else
                    this.active(i).exitCount = 0;
                    this.exitCount(this.active(i).name) = 0;
                end
                name = this.operatorMagicNumberToName(this.active(i).type);
                warnId ='MATLAB:sfx:TemporalDeferred';
                this.throwWarning(name, this.active(i), warnId);
            end
            this.queuedTimerEvents{end+1} = this.active;
            this.active = [];
            stop(this.timerObj);
            delete(this.timerObj);
        end
        function isValid = isQueuedTimerCallbackValid(this)
            isValid = false;
            queuedEvent = this.queuedTimerEvents{1};
            assert(~isempty(this.queuedTimerEvents), 'queue should not be empty');
            for i = 1:length(queuedEvent)
                isValid = isValid || isequal(queuedEvent(i).exitCount, this.exitCount(queuedEvent(i).name));
                if isValid
                    return;
                end
            end
        end
        function delete(obj)
            assert(isempty(obj.timerObj) || ~isvalid(obj.timerObj), 'timer must be empty');
            delete(obj.timerObj);
        end
    end

end
