classdef TimerBasedDataModel < internal.matlab.variableeditor.NamedVariable & ...
        internal.matlab.variableeditor.VariableObserver
    % TimerBasedDataModel - Base mixin for object data data models that
    % need to update on a periodic timer

    % Copyright 2014-2025 The MathWorks, Inc.

    properties(Access = protected)
        UpdateTimer = [];

        ListenersChecked = false;
    end

    properties(Access = protected)
        DataChanged = false;
        PreviousData = [];

        TimerCallbackDelay (1,1) double = 1;
        TimerState (1,1) internal.matlab.variableeditor.ObjectTimerState = internal.matlab.variableeditor.ObjectTimerState.TIMER_STOPPED;
    end

    properties(Hidden)
        UseTimer (1,1) logical = false;
    end

    properties(Constant, Hidden)
        MAX_AUTO_REFRESH_DELAY = 5;
    end

    events
        AutoRefreshChanged;
    end

    methods(Access = public)
        function this = TimerBasedDataModel(useTimer)
            arguments
                useTimer (1,1) logical = true;
            end

            this.UseTimer = useTimer;
            if this.UseTimer
                this.TimerState = internal.matlab.variableeditor.ObjectTimerState.START_REQUESTED;
                this.startTimer();
            end
        end

        function startTimer(this)
            if ~this.UseTimer || this.TimerState == internal.matlab.variableeditor.ObjectTimerState.STOP_REQUESTED
                internal.matlab.datatoolsservices.logDebug('ve::timer', "VE startTimer() but state == StopTimerRunning");
                this.TimerState = internal.matlab.variableeditor.ObjectTimerState.TIMER_STOPPED;
                return
            end

            internal.matlab.datatoolsservices.logDebug('ve::timer', "VE startTimer()");

            if isempty(this.UpdateTimer) || ~isvalid(this.UpdateTimer)
                timername = ['veHandleObj_' this.Name];
                this.TimerState = internal.matlab.variableeditor.ObjectTimerState.TIMER_RUNNING;

                % Startup a timer to check for changes to the variable
                this.UpdateTimer = timer(...
                    'TimerFcn', @(~,~)callIfValid(this, @handleUpdateTimer), ...
                    'ErrorFcn', @(~,~)callIfValid(this, @handleTimerError), ...
                    'StartDelay', this.TimerCallbackDelay, ...
                    'Name', timername, ...
                    'ObjectVisibility', 'off', ...
                    'ExecutionMode', 'singleShot');
                start(this.UpdateTimer);
            else
                stop(this.UpdateTimer);
                if ~isequal(this.UpdateTimer.StartDelay, this.TimerCallbackDelay)
                    this.UpdateTimer.StartDelay = this.TimerCallbackDelay;
                end
                start(this.UpdateTimer);
            end
        end

        function stopTimer(this)
            this.TimerState = internal.matlab.variableeditor.ObjectTimerState.STOP_REQUESTED;
            internal.matlab.datatoolsservices.logDebug('ve::timer', "stopTimer()");
            try
                % Try to stop the timer, but its possible its being deleted
                % at the time.  So if there's an exception, it can be
                % ignored.
                if ~isempty(this.UpdateTimer) && isvalid(this.UpdateTimer)
                    stop(this.UpdateTimer);
                end
            catch
            end
        end

        function restartTimer(this)
            this.stopTimer;
            this.TimerState = internal.matlab.variableeditor.ObjectTimerState.START_REQUESTED;
            this.startTimer;
        end

        function pauseTimer(this)
            this.TimerState = internal.matlab.variableeditor.ObjectTimerState.STOP_REQUESTED;
            try
                if ~isempty(this.UpdateTimer) && isvalid(this.UpdateTimer)
                    % Make sure we have a valid timer before stopping it
                    stop(this.UpdateTimer);
                end
            catch
            end
        end

        function b = isTimerRunning(this)
            if ~this.UseTimer
                b = false;
            else
                b = (this.TimerState == internal.matlab.variableeditor.ObjectTimerState.TIMER_RUNNING || ...
                    this.TimerState == internal.matlab.variableeditor.ObjectTimerState.START_REQUESTED);
            end
        end

        function unpauseTimer(this)
            this.TimerState = internal.matlab.variableeditor.ObjectTimerState.START_REQUESTED;
            try
                if ~isempty(this.UpdateTimer) && isvalid(this.UpdateTimer)
                    % Make sure we have a valid timer before starting it
                    start(this.UpdateTimer);
                end
            catch
            end
        end

        function handleUpdateTimer(this)
             internal.matlab.datatoolsservices.logDebug('ve::timer', "handleUpdateTimer start")
             this.pauseTimer;
             tStart = tic;

            try
                if isempty(this.PreviousData)
                    this.PreviousData = matlab.internal.datatoolsservices.createStructForObject(this.Data);
                end
                oldPropCount = length(fieldnames(this.PreviousData));
                
                newData = this.Data;
                try
                    newData = evalin(this.Workspace, this.Name);
                catch e
                    internal.matlab.datatoolsservices.logDebug('ve::timer', "Error getting new value: " + e.message);
                end
                sizeChanged = false;
                newPropCount = length(fieldnames(matlab.internal.datatoolsservices.createStructForObject(newData)));

                if ~this.ListenersChecked
                    this.updateChangeListeners(this.getData);
                end

                if ~isobject(newData) || (ismethod(newData, 'isvalid') && ~all(isvalid(newData),'all')) && length(newData) == 1
                    this.stopTimer;
                else
                    this.checkUnobservableUpdates(newData);

                    if (newPropCount ~= oldPropCount) || ~all(isvalid(newData),'all')
                        sizeChanged = true;
                        this.DataChanged = true;
                    end
                end

                if this.DataChanged
                    % Call data model update
                    % Force update since we've already done the comparison
                    data = newData;
                    this.variableChanged('newData', data, 'newClass', class(data), 'newSize', size(data), 'forceUpdate', true);

                    % If the data has changed, fire an event
                    eventdata = internal.matlab.datatoolsservices.data.DataChangeEventData;
                    eventdata.SizeChanged = sizeChanged;
                    eventdata.EventSource = 'InternalDmUpdate';
                    this.notify('DataChange', eventdata);
                    this.DataChanged = false;
                end

                tElapsed = ceil(toc(tStart));
                if tElapsed > this.MAX_AUTO_REFRESH_DELAY
                    internal.matlab.datatoolsservices.logDebug('ve::timer', "TimerCallbackDelay TOO LONG = " + tElapsed)
                    this.stopTimer;
                else
                    this.TimerCallbackDelay = max(1, tElapsed);
                    internal.matlab.datatoolsservices.logDebug('ve::timer', "TimerCallbackDelay = " + this.TimerCallbackDelay)
                    this.startTimer;
                end
            catch ex
                internal.matlab.datatoolsservices.logDebug('ve::timer', "error(" + ex.message + ')');
                this.stopTimer;
            end
            this.unpauseTimer;
            internal.matlab.datatoolsservices.logDebug('ve::timer', "handleUpdateTimer end")
        end

        function handleTimerError(this)
            if ~isobject(this.Data) || (ismethod(this.Data, 'isvalid') && ~all(isvalid(this.Data),'all'))
                this.stopTimer;
            end
        end

        function checkUnobservableUpdates(this, newData)
            s = warning('off', 'all');
            c = onCleanup(@() warning(s));

            if isa(newData,'handle') && (ismethod(newData, 'isvalid') && all(isvalid(newData),'all'))
                d = this.PreviousData;
                if isscalar(newData)
                    newDataStruct = matlab.internal.datatoolsservices.createStructForObject(newData);
                else
                    newDataStruct = arrayfun(@(d)matlab.internal.datatoolsservices.createStructForObject(d), newData);
                end
                if ~isempty(d)
                    % Compare as a struct, just as a way to compare the
                    % states of a handle between old data and new data

                    if ~isequal(d, newDataStruct)
                        this.DataChanged = true;
                    end
                end
                this.PreviousData = newDataStruct;
            end

        end

        function delete(this)
            % Also stop the timer
            if ~isempty(this.UpdateTimer) && isvalid(this.UpdateTimer)
                % Also stop the timer
                this.stopTimer;
                delete(this.UpdateTimer);
                this.UpdateTimer = [];
            end
        end
    end

    methods(Access = protected)
        function updateChangeListeners(this, data)
        end

        function fireAutoRefreshChanged(this, value)
            this.firePropertyEvent('AutoRefreshChanged', "AutoRefreshChanged", value);
        end

        function firePropertyEvent(this, eventName, properties, values)
            % Fire a property changed event
            e = internal.matlab.variableeditor.PropertyChangeEventData;

            % Property name comes from the event source, which is the
            % metaclass data for the property. Property value can be
            % retrieved by getting the property from the affected source in
            % the event data
            e.Properties = properties;
            e.Values = values;
            this.notify(eventName, e);
        end
    end
end

function callIfValid(dm, fcn)
    arguments
        dm (1,1) internal.matlab.variableeditor.TimerBasedDataModel
        fcn (1,1) function_handle
    end
    if isvalid(dm)
        try
            fcn(dm);
        catch e
            internal.matlab.datatoolsservices.logDebug('ve::timer', "function callback error: " + e.message);
        end
    end
end
