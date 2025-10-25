classdef (CompatibleInexactProperties) timer < matlab.mixin.SetGet & matlab.mixin.internal.CustomSaveLoadObjectArray
%MATLAB Timer Object Properties and Methods.
%
% Timer properties.
%   AveragePeriod    - Average number of seconds between TimerFcn executions.
%   BusyMode         - Action taken when TimerFcn executions are in progress.
%   ErrorFcn         - Callback function executed when an error occurs.
%   ExecutionMode    - Mode used to schedule timer events.
%   InstantPeriod    - Elapsed time between the last two TimerFcn executions.
%   Name             - Descriptive name of the timer object.
%   Period           - Seconds between TimerFcn executions.
%   Running          - Timer object running status.
%   StartDelay       - Delay between START and the first scheduled TimerFcn execution.
%   StartFcn         - Callback function executed when timer object starts.
%   StopFcn          - Callback function executed after timer object stops.
%   Tag              - Label for object.
%   TasksExecuted    - Number of TimerFcn executions that have occurred.
%   TasksToExecute   - Number of times to execute the TimerFcn callback.
%   TimerFcn         - Callback function executed when a timer event occurs.
%   Type             - Object type.
%   UserData         - User data for timer object.
%
% timer methods:
% Timer object construction:
%   @timer/timer            - Construct timer object.
%
% Getting and setting parameters:
%   get              - Get value of timer object property.
%   set              - Set value of timer object property.
%
% General:
%   delete           - Remove timer object from memory.
%   display          - Display method for timer objects.
%   inspect          - Open the inspector and inspect timer object properties.
%   isvalid          - True for valid timer objects.
%   length           - Determine length of timer object array.
%   size             - Determine size of timer object array.
%   timerfind        - Find visible timer objects with specified property values.
%   timerfindall     - Find all timer objects with specified property values.
%
% Execution:
%   start            - Start timer object running.
%   startat          - Start timer object running at a specified time.
%   stop             - Stop timer object running.
%   wait             - Wait for timer object to stop running.

% Copyright 2002-2022 The MathWorks, Inc.

    properties (SetAccess = private, Hidden)
        ud = {};
    end


    properties (Access = private, Hidden)
        jobject;
        corebackend;
        errorReached = false;
        stopRequested = false;
        errorReachedMsgId;
        errorReachedMsgStr;
    end

    properties (Access = private, Hidden, Transient)
        internal_StartFcnCallBackType matlab.internal.timer.CallBackTypeEnum = matlab.internal.timer.CallBackTypeEnum.TYPE_UNDEF;
        internal_StopFcnCallBackType  matlab.internal.timer.CallBackTypeEnum = matlab.internal.timer.CallBackTypeEnum.TYPE_UNDEF;
        internal_ErrorFcnCallBackType matlab.internal.timer.CallBackTypeEnum = matlab.internal.timer.CallBackTypeEnum.TYPE_UNDEF;
        internal_TimerFcnCallBackType matlab.internal.timer.CallBackTypeEnum = matlab.internal.timer.CallBackTypeEnum.TYPE_UNDEF;
    end

    properties
        Name
        Tag = ''
        ObjectVisibility matlab.internal.timer.ObjectVisibilityEnum = matlab.internal.timer.ObjectVisibilityEnum('On');
        TasksToExecute(1,1) {mustBePositive} = inf
        StartFcn = ''
        StopFcn = ''
        ErrorFcn = ''
        TimerFcn = ''
        StartDelay (1,1)  {mustBeNonnegative} = 0
        Period (1,1) {mustBePositive} = 1
        BusyMode matlab.internal.timer.BusyModeEnum = matlab.internal.timer.BusyModeEnum('drop') %enumeration class provides inexact matching and case insensitivity.
        ExecutionMode matlab.internal.timer.ExecutionModeEnum = matlab.internal.timer.ExecutionModeEnum('singleShot')
        UserData
    end

    properties (SetAccess = private, Dependent)
        AveragePeriod
        InstantPeriod
        Running
        TasksExecuted
    end

    properties (Constant)
        Type = 'timer';
    end


    methods
        function obj = timer(varargin)
        %TIMER Construct timer object.
        %
        %    T = TIMER constructs a timer object with default attributes.
        %
        %    T = TIMER('PropertyName1',PropertyValue1, 'PropertyName2', PropertyValue2,...)
        %    constructs a timer object in which the given Property name/value pairs are
        %    set on the object.
        %
        %    Note that the property value pairs can be in any format supported by
        %    the SET function, i.e., param-value pairs, structures, and
        %    param-value cell array pairs.
        %
        %    Example:
        %       % To construct a timer object with a timer callback mycallback and a 10s interval:
        %         t = timer('TimerFcn',@mycallback, 'Period', 10.0);
        %
        %    See also TIMER/SET, TIMER/TIMERFIND, TIMER/START, TIMER/STARTAT.

        % Create the default class.
            mlock

            [varargin{:}] = convertStringsToChars(varargin{:});

            % this flavor of the constructor is not intended to be for the end-user
            if ((nargin == 1) && (ischar(varargin{1})) && (varargin{1}=="INIT"))
                obj.corebackend = makeDefaultCoreBackEnd(obj);
                obj.Name = 'timer-root';
                return
            end




            obj.Name = ['timer-' num2str(matlab.internal.timer.lifetimeManager('Count'))];

            if nargin > 0 ...
                    && (isa(varargin{1},'timer') ...
                        || (isstruct(varargin{1}) && isfield(varargin{1}, 'jobject'))) %support for old style timer object
                obj = makeFromStruct(obj,varargin{1});
                return
            end

            obj.corebackend = makeDefaultCoreBackEnd(obj);


            if (nargin > 0)
                % user gave PV pairs, so process them by calling set.
                try
                    set(obj, varargin{:});
                catch exception
                    delete(obj);
                    throw(exception);
                end
            end

            matlab.internal.timer.lifetimeManager('Add', obj);
        end

        function delete(obj)
        %DELETE Remove timer object from memory.
        %
        %    DELETE(OBJ) removes timer object, OBJ, from memory. If OBJ
        %    is an array of timer objects, DELETE removes all the objects
        %    from memory.
        %
        %    When a timer object is deleted, it becomes invalid and cannot
        %    be reused. Use the CLEAR command to remove invalid timer
        %    objects from the workspace.
        %
        %    If multiple references to a timer object exist in the workspace,
        %    deleting the timer object invalidates the remaining
        %    references. Use the CLEAR command to remove the remaining
        %    references to the object from the workspace.
        %
        %    See also CLEAR, TIMER, TIMER/ISVALID.

            stopWarn = false;
            len = length(obj);
            % we need a try-catch, because the following can happen.
            % t1 = timer; delete(t1); feval('timer', t1) can cause a
            % delete, because matlab.internal.timer.lifetimeManager/makeFromStruct needs to delete
            % temporary timer, which is invalid already
            try
                for i = 1:len
                    areRunning(i) = obj(i).coreBackend.Running;  %#ok<AGROW>
                    wasStopRequested(i) = obj(i).stopRequested; %#ok<AGROW>
                end

                % The previous implementation immediately marked
                % the timer as stopped, even if the last
                % timerfcn/stopfcn has not been processed yet.
                % and that's what we used to check as to whether we
                % message 'MATLAB:timer:deleterunning'
                % Now, we can disambiguate between whether a stop
                % method was called (stopRequested), and whether a stopfcn/last
                % timerfcn is starting to being processed (Running).


                if (any(areRunning))
                    % if the timers have been asked to stop explicitly,
                    % it's safe to not warn, even if the
                    % backend has not marked the timer Running as off
                    if (~all(wasStopRequested))
                        stopWarn = true;
                    end
                end

                for j = find(areRunning)
                    % this call must go back to builtin
                    obj(j).coreBackend.stop();
                    % synchronized stopFcn call, Note we are making a
                    % special DeletionStopFcn call , stead of usual StopFcn
                    % call
                    event.Type = 'StopFcn';
                    event.Data = datestr(now);
                    timercb(obj(j), 'DeletionStopFcn', [], event);
                end
            catch
            end


            if stopWarn
                state = warning('backtrace','off');
                warning(message('MATLAB:timer:deleterunning'));
                warning(state);
            end

            matlab.internal.timer.lifetimeManager('Delete',obj);
        end
    end

    methods(Access = private, Hidden)
        function runCheck(obj, theProperty)
            if (strcmp(obj.Running, 'on')) %The Java/C++ backend is guaranteed to be initialized,
                                           % so running property must be queryable from that side, before the MATLAB side
                error(message('MATLAB:timer:cannotBeSetWhileTimerRunning', theProperty));
            end
        end
    end

    methods (Access = public, Hidden)
        % the definition/code for this function is in getdisp.m
        % The function signature is specified here, to ensure
        % that the function is hidden when someone calls
        % >> methods timer
        % this is needed to match the superclass visibility behavior
        % of matlab.mixin.SetGet
        getdisp(obj);
    end


    methods % get/set

        function set.ObjectVisibility(obj,rhs)
            if (isenum(rhs))
                rhs = char(rhs); % convert enum to char
            end
            obj.ObjectVisibility = convertStringsToChars(rhs);
        end

        function val = get.ObjectVisibility(obj)
            val = char(obj.ObjectVisibility);
        end

        function set.TasksToExecute(obj, rhs)
        % note rhs can also be logical :(.. supported in previous
        % implementations, keeping the behaviour
            if ~(isscalar(rhs))
                error(message('MATLAB:class:MustBeScalar'));
            end

            if ~isinf(rhs)
                mustBeLessThan(rhs, intmax('int64'));
                % The previous implementation silently took a floor
                % to convert to integer. We are unfortunately keeping the
                % same behavior.
                rhs = floor(rhs);
                try
                    mustBePositive(rhs);
                catch ME
                    if (strcmp(ME.identifier,'MATLAB:validators:mustBePositive'))
                        error(message('MATLAB:timer:floorOfTasksToExecuteMustBePositive'));
                    end
                end
            end
            obj.coreBackend.TasksToExecute = rhs;

            obj.TasksToExecute = rhs;
        end


        function set.BusyMode(obj,rhs)
            runCheck(obj, 'BusyMode');
            try
                obj.BusyMode = rhs;
            catch ME
                throwAsCaller(ME)
            end
        end

        function set.ExecutionMode(obj,rhs)
            runCheck(obj, 'ExecutionMode');
            try
                obj.ExecutionMode = rhs;
            catch ME
                throwAsCaller(ME)
            end
        end

        function set.Name(obj, rhs)
            rhs = convertStringsToChars(rhs);
            if (~ischar(rhs))
                error(message('MATLAB:class:StringExpected'));
            end
            obj.Name = rhs;
        end

        function set.Period(obj,rhs)
        %The input is set as seconds, but the backend accepts it as
        %miliseconds
            runCheck(obj, 'Period');
            period = round(rhs * 1000);
            didRoundOffOccur = abs(rhs * 1000 - period) > eps(rhs * 1000); % less than a milisecond precision
            if  (didRoundOffOccur)
                warning(message('MATLAB:timer:miliSecPrecNotAllowed', 'Period'));
            end

            obj.Period = period/1000; % Save in rounded of seconds that adheres to milisecond precision
        end

        function set.StartDelay(obj,rhs)
        %The input is set as seconds, but the backend accepts it as
        %miliseconds
            runCheck(obj, 'StartDelay');

            % the backend uses steady_clock, which is OS/platform
            % dependent. There is no accuracy limit on the standard.
            % However, given there is a queue  & execution lag and other factors involved
            % setting a resolution less that mili-second is realistically
            % not possible in avg. use case. It's possibly quite a bit
            % larger than a milisecond.
            % The backend does calculations in miliseconds.
            delay = round(rhs * 1000);
            didRoundOffOccur = abs(rhs * 1000 - delay) > eps(rhs * 1000); % less than a milisecond precision
            if  (didRoundOffOccur)
                warning(message('MATLAB:timer:miliSecPrecNotAllowed', 'StartDelay'));
            end

            obj.StartDelay = delay/1000; % Save in rounded of seconds that adheres to milisecond precision
        end

        function set.StartFcn(obj,rhs)
            rhs = convertStringsToChars(rhs);
            obj.internal_StartFcnCallBackType = validateAndGetCallbackFcnType(rhs, 'StartFcn'); %#ok<*MCSUP>
            if (~isempty(rhs))
                obj.corebackend.isStartFcnEmpty = false;
            end
            obj.StartFcn = rhs;
        end

        function set.StopFcn(obj,rhs)
            rhs = convertStringsToChars(rhs);
            obj.internal_StopFcnCallBackType = validateAndGetCallbackFcnType(rhs, 'StopFcn');
            if (~isempty(rhs))
                obj.corebackend.isStopFcnEmpty = false;
            end
            obj.StopFcn = rhs;
        end

        function set.ErrorFcn(obj,rhs)
            rhs = convertStringsToChars(rhs);
            obj.internal_ErrorFcnCallBackType = validateAndGetCallbackFcnType(rhs, 'ErrorFcn');
            if (~isempty(rhs))
                obj.corebackend.isErrorFcnEmpty = false;
            end
            obj.ErrorFcn = rhs;
        end

        function set.TimerFcn(obj,rhs)
            rhs = convertStringsToChars(rhs);
            obj.internal_TimerFcnCallBackType = validateAndGetCallbackFcnType(rhs, 'TimerFcn');
            obj.TimerFcn = rhs;
        end

        function set.Tag(obj,rhs)
            rhs = convertStringsToChars(rhs);
            if ~isTextScalar(rhs)
                error(message('MATLAB:class:StringExpected'));
            end
            obj.Tag = rhs;
        end

        function val = get.AveragePeriod(obj)
            val = obj.getProperty('AveragePeriod');
        end

        function val = get.InstantPeriod(obj)
            val = obj.getProperty('InstantPeriod');
        end

        function val = get.Running(obj)
            val = obj.getProperty('Running');
            if (val)
                val = 'on';
            else
                val = 'off';
            end
        end

        function val = get.TasksExecuted(obj)
            val = obj.getProperty('TasksExecuted');
        end

    end

    methods (Static=true, Hidden=true)
        obj = loadobj(B)
        obj = loadObjectArray(B)
    end

    methods (Hidden=true)
        B = saveObjectArray(obj);
        output = sharedTimerfind(varargin);

        function jobj = getJobjects(obj)
            try
                jobj = reshape([obj(:).jobject],size(obj));
            catch
                jobj = [];
                for i = 1:numel(obj)
                    try
                        jobj(i) = obj(i).jobject; %#ok<AGROW>
                    catch
                    end
                end
            end
        end
    end

    methods (Access=private)
        function val = getProperty(obj,name)
            if isvalid(obj)
                val = obj.corebackend.(name);
            else
                error(message('MATLAB:class:InvalidHandle'))
            end
        end

        function val = getStartDelayInMiliSec_internal(obj)
            val = obj.StartDelay * 1000; % return result in miliseconds for timer internal usage
        end

        function val = getPeriodMiliSec_internal(obj)
            val = obj.Period * 1000; % return result in miliseconds for timer internal usage
        end
    end
end

function obj = makeFromStruct(obj,orig)
    if (isa(orig,'timer') && ~isvalid(orig))
        error(message('MATLAB:timer:invalid'));
    end


    % foreach valid object in the original timer object array...

    if (isfield(orig, 'jobject'))
        warning(message('MATLAB:timer:incompatibleTimerLoad'));
    else
        len = length(orig);
        for lcv=1:len
            if isvalid(orig(lcv))
                % for valid timers found, make new timer object,...
                currTimerToCopyFrom = orig(lcv);
                t = timer;
                [setableNames, setableVals] = currTimerToCopyFrom.getSettableValues();

                setableValsSingle = setableVals{:};
                idxWithNonEmptyInfo = ~cellfun(@isempty, setableValsSingle);

                set(t, ...
                    setableNames(idxWithNonEmptyInfo),...
                    setableValsSingle(idxWithNonEmptyInfo));

                obj(lcv) = t;
            end
        end
    end
end


function corebackend =  makeDefaultCoreBackEnd(userFacingObj)
    corebackend = matlab.internal.timer.TimerInfo(userFacingObj);
end

function TF = isTextScalar(x)
    TF = (ischar(x) && isempty(x)) || (ischar(x) && isrow(x)) || isStringScalar(x);
end
