classdef (Sealed) implicitRegularRowTimesDim < matlab.internal.coder.tabular.private.rowTimesDim  %#codegen
%REGULARROWTIMESDIM Internal class to represent an optimized regular timetable's rows dimension.

% This class is for internal use only and will change in a
% future release.  Do not use this class.

    %   Copyright 2019-2020 The MathWorks, Inc.
    
    properties (Dependent=true, GetAccess=public, SetAccess=protected)
        labels
    end
    
    properties (GetAccess=public, SetAccess=protected)
        length
    end
    
    methods % dependent property get/set methods
        function rowtimes = get.labels(obj)
            rowtimes = obj.getRowTimes();
        end
        % No set.labels method, assignment directly to obj.labels is an error.
        % Any assignment goes through the setLabels method.
    end
    
    properties (GetAccess=protected, SetAccess=protected)
        % Remember how the row times were specified: timeStep or sampleRate?
        specifiedAsRate
    end
    
    properties (GetAccess=public, SetAccess=protected)
        startTime
        sampleRate
        timeStep
    end
    methods (Access=public)
        % These are effectively set.XXX methods, but setTimeStep and
        % setSampleRate need to set each others' properties, which would lead
        % to infinite recursion if they were set.XXX methods. Also, they might
        % need to return an explicitRowTimesDim.
        %
        % These methods assume that the object is in a valid state, and one
        % property at a time is being assigned. Cases where multiple properties
        % are being assigned go through validateTimeVectorParams and the
        % constructor.
        %-----------------------------------------------------------------------
        function obj = setStartTime(obj,startTime)
    
            coder.internal.errorIf(isnumeric(startTime), 'MATLAB:timetable:InvalidStartTimeNumeric');
            coder.internal.assert(isscalar(startTime) && (isa(startTime,'datetime') || isa(startTime,'duration')),...
                'MATLAB:timetable:InvalidStartTime');
            coder.internal.errorIf(isa(startTime,'duration') && isa(obj.timeStep,'calendarDuration'), ...
                'MATLAB:timetable:DurationStartTimeWithCalDurTimeStep');
            
            % codegen does not allow switching from implicit rowtimes to
            % explicit
            keepImplicit = matlab.internal.coder.tabular.private.implicitRegularRowTimesDim.implicitOrExplicit(...
                obj.length,startTime,obj.timeStep,[]);
            coder.internal.assert(keepImplicit, 'MATLAB:timetable:IrregularRowTimesAssignment');
                obj.startTime = startTime;
        end
        %-----------------------------------------------------------------------
        function obj = setTimeStep(obj,timeStep)

            coder.internal.assert(isscalar(timeStep), 'MATLAB:timetable:InvalidTimeStep');            
            if isa(timeStep,'duration')
                haveDurationTimeStep = true;
            elseif isa(timeStep,'calendarDuration')
                coder.internal.assert(isa(obj.labels,'datetime'), ...
                    'MATLAB:timetable:DurationStartTimeWithCalDurTimeStep');                
                haveDurationTimeStep = false;
            else
                isnum = isnumeric(timestep);
                coder.internal.errorIf(isnum, 'MATLAB:timetable:InvalidTimeStepNumeric');
                coder.internal.errorIf(~isnum, 'MATLAB:timetable:InvalidTimeStep');               
            end
            
            % codegen does not allow switching from implicit rowtimes to
            % explicit
            keepImplicit = matlab.internal.coder.tabular.private.implicitRegularRowTimesDim.implicitOrExplicit(...
                obj.length,obj.startTime,timeStep,[]);
            coder.internal.assert(keepImplicit, 'MATLAB:timetable:IrregularRowTimesAssignment');
            
                obj.specifiedAsRate = false;
                obj.timeStep = timeStep;
                if haveDurationTimeStep
                    obj.sampleRate = 1/seconds(timeStep);
                else % calendarDuration
                    % sampleRate is in Hz, don't attempt to convert a calendarDuration to seconds
                    obj.sampleRate = NaN;
                end
        end
        %-----------------------------------------------------------------------
        function obj = setSampleRate(obj,sampleRateIn)

            coder.internal.assert(isnumeric(sampleRateIn) && isscalar(sampleRateIn) && ...
                isreal(sampleRateIn), 'MATLAB:timetable:InvalidSampleRate');
            
            samplerate = double(sampleRateIn);

            % codegen does not allow switching from implicit rowtimes to
            % explicit
 
            keepImplicit = matlab.internal.coder.tabular.private.implicitRegularRowTimesDim.implicitOrExplicit(...
                obj.length,obj.startTime,[],samplerate);
            coder.internal.assert(keepImplicit, 'MATLAB:timetable:IrregularRowTimesAssignment');
            
                obj.specifiedAsRate = true;
            obj.sampleRate = samplerate;
            obj.timeStep = seconds(1/samplerate);            
            end
        end
    
    %===========================================================================
    methods
        function obj = implicitRegularRowTimesDim(length,startTime,timeStep,sampleRate)
            assert(nargin == 4);
            coder.internal.prefer_const(length);
            
            % There is no error checking on the "regular" parameters, the caller
            % should use validateTimeVectorParams and implicitOrExplicit first.
            obj = obj.init(length,[]);
            obj.startTime = startTime;
            
            if isnumeric(sampleRate) && isequal(timeStep,[])
                % Given a sample rate, and not a time step
                obj.specifiedAsRate = true;
                obj.sampleRate = sampleRate;
                obj.timeStep = seconds(1/sampleRate);
            else
                % check that sampeRate and timeStep are not both defined
                coder.internal.assert(isequal(sampleRate,[]), ...
                    'MATLAB:timetable:TimeStepSampleRateConflict');
                % Given a time step, and not a sample rate
                obj.specifiedAsRate = false;
                % Avoid directly assigning duration input to timeStep. Make
                % a copy instead. When assigned directly, the timeStep 
                % property type can be linked to the timeStep input type. 
                % Subsequent changes to the timeStep input variable can 
                % affect the property type, and we have seen this lead to
                % failure in parenReference.
                obj.timeStep = duration.fromMillis(milliseconds(timeStep), timeStep.Format);
                if isa(timeStep,'duration')
                    obj.sampleRate = 1/seconds(timeStep);
                else % calendarDuration
                    % sampleRate is in Hz, don't attempt to convert a calendarDuration to seconds
                    obj.sampleRate = NaN;
                end
            end
        end
        
        %-----------------------------------------------------------------------
        function obj = init(obj,dimLength,dimLabels)
            % This method should never be called with explicit row times. It
            % assumes that an object has already been created with the correct
            % "regular" parameters, and only needs the length set. It exists
            % mostly to provide polymorphism with explicitRowTimesDim, in which
            % init does (a little more) work.
            coder.internal.prefer_const(dimLength);
            assert(nargin==2 || isequal(dimLabels,[]));
            obj.length = dimLength;
        end
        
        %-----------------------------------------------------------------------
        function newobj = createLike(obj,dimLength,dimLabels)
            coder.internal.prefer_const(dimLength);            
            assert(nargin==2 || isequal(dimLabels,[])); % should never be called with explicit row times
            % create a new object
            if obj.specifiedAsRate
                newobj = matlab.internal.coder.tabular.private.implicitRegularRowTimesDim(...
                    dimLength, obj.startTime, [], obj.sampleRate);
            else
                newobj = matlab.internal.coder.tabular.private.implicitRegularRowTimesDim(...
                    dimLength, obj.startTime, obj.timeStep, []);
            end
        end
        
        %-----------------------------------------------------------------------
        function [tf,dt] = isregular(obj,unit)
            ts = obj.timeStep;
            
            % Test if row times are regularly-spaced in time.
            if nargin == 1 || strncmpi(unit, 'time', max([1,length(unit)])) %#ok<CPROPLC> % max fends off ''
                if obj.specifiedAsRate
                    % Row times with a finite sample rate are regular w.r.t. time.
                    tf = isfinite(obj.sampleRate);
                    dt = seconds(1/obj.sampleRate);
                elseif isa(ts,'duration')
                    % Row times with a finite duration time step are regular w.r.t. time.
                    tf = isfinite(ts);
                    dt = obj.timeStep;
                else
                    assert(false);
                end
                
            % Test if row times are regularly-spaced in the specified calendar unit
            else
                % Validate single char vector inputs
                coder.internal.assert(nargin < 2 || ...
                    matlab.internal.coder.datatypes.isScalarText(unit), ...
                    'MATLAB:datetime:InvalidSingleComponent');
                
                % Row times specified with a sample rate or a duration time
                % step aren't regular w.r.t. a calendar duration unit.
                tf = false;
                dt = duration.fromMillis(nan);
            end
            
            % Make sure the start time is finite, an empty rowDim may have a
            % non-finite start time.
            tf = tf && isfinite(obj.startTime);
        end
        
        %-----------------------------------------------------------------------
        function s = getProperties(obj)
            s.SampleRate = obj.sampleRate;
        end
        
        %-----------------------------------------------------------------------
        function s = getDurationProperties(obj)
            s.RowTimes = obj.getRowTimes();
            s.StartTime = obj.startTime;
            s.TimeStep = obj.timeStep;
        end
        
        %-----------------------------------------------------------------------
        function newObj = lengthenTo(obj,maxIndex,newLabels)
            
            if nargin < 3
                if obj.specifiedAsRate
                    [keepImplicit,explicitRowTimes] = obj.implicitOrExplicit(maxIndex,obj.startTime,[],obj.sampleRate);
                else
                    [keepImplicit,explicitRowTimes] = obj.implicitOrExplicit(maxIndex,obj.startTime,obj.timeStep,[]);
                end
                if keepImplicit || ~coder.internal.isConst(keepImplicit)
                    coder.internal.assert(keepImplicit, 'MATLAB:timetable:CannotBeImplicit');
                    % The existing dim is regular, just extend it with the same time
                    % step or sample rate.
                    newObj = createLike(obj,maxIndex);
                else
                    % The lengthened rowDim can't be stored implcitly, e.g. an empty implicit
                    % rowDim with non-finite params must become explicit.
                    % when adding rows.
                    newObj = matlab.internal.coder.tabular.private.explicitRowTimesDim(length(explicitRowTimes),explicitRowTimes);
                    newObj = newObj.lengthenTo(maxIndex);
                end
            else
                % If new row times are given, the check to determine if they are
                % regular and consistent with the existing regular labels is
                % potentially expensive. Just replace the existing implicit row
                % times dim with an explicit dim.
                %
                % Assume that newLabels has already been checked by
                % validateNativeSubscripts. Row times need not be unique, no
                % need to worry about that.
                rowtimes = [obj.labels;newLabels];
                newObj = matlab.internal.coder.tabular.private.explicitRowTimesDim(length(rowtimes),rowtimes);
            end
        end
        
        %-----------------------------------------------------------------------
        function newObj = shortenTo(obj,maxIndex)
            newObj = createLike(obj, maxIndex);
        end

        %-----------------------------------------------------------------------
        function newObj = selectFrom(obj,toSelectRaw)
            
            if islogical(toSelectRaw)
                % A logical subscript may or may not result in an regular
                % result, most likely not, but have to convert to indices to
                % determine, and would have to convert it anyway if not.
                toSelect = find(toSelectRaw);                
            elseif isa(toSelectRaw, 'coder.internal.indexInt')
                % convert indexInt to double for better computation support
                toSelect = double(toSelectRaw);
            else
                toSelect = toSelectRaw;
            end
            
            isColonObj = isobject(toSelect) && isa(toSelect,'matlab.internal.ColonDescriptor');
            if isnumeric(toSelect) || isColonObj
                if isnumeric(toSelectRaw)  % branch on toSelectRaw here so that logical go through another branch
                    if isscalar(toSelect)
                        stride = 1;
                        isregularstride = true;
                    elseif isempty(toSelect)
                        isregularstride = false;
                        stride = toSelect;
                    else
                        %stride = unique(diff(toSelect));
                        stride = toSelect(2) - toSelect(1);
                        isregularstride = true;
                        coder.unroll(coder.internal.isConst(numel(toSelect)));
                        for i = 3:numel(toSelect)
                            if (toSelect(i) - toSelect(i-1)) ~= stride
                                isregularstride = false;
                                break;                            
                            end
                        end
                    end
                    if isscalar(stride)
                        start = toSelect(1); % this is the min if stride is a scalar
                    end
                elseif islogical(toSelectRaw)
                    % with logical indices, determine whether the resulting
                    % timetable is regular by inspecting toSelectRaw rather
                    % than toSelect. The result can more likely be
                    % constant.
                    prev = 0;
                    diffi = 0;
                    isregularstride = true;
                    coder.unroll(coder.internal.isConst(numel(toSelectRaw)));
                    for i = 1:numel(toSelectRaw)
                        if toSelectRaw(i)
                            if prev > 0   % second or subsequent true element
                                if diffi == 0   % second true element
                                    diffi = i - prev;
                                else   % third or subsequent true element
                                    if (i-prev) ~= diffi
                                        isregularstride = false;
                                        break;
                                    end
                                end
                            else   % prev == 0, first true element
                                start = i;
                            end
                            prev = i;
                        end
                    end
                    if diffi == 0 && prev > 0 % scalar case
                        stride = 1;
                    elseif prev == 0  % empty case
                        stride = [];
                    else
                        stride = diffi;
                    end
                else % isColonObj
                    stride = double(toSelect.Stride);
                    isregularstride = isscalar(stride);
                    start = double(toSelect.Start);
                    % ColonDescriptor overloads length, so length(toSelect) below is OK
                end
                % Determine if the selection preserves regularity.
                % Only use implicit regular rowtimes if we are sure time is
                % regular (isregularstride is constant)
                if coder.internal.isConst(isregularstride) && isregularstride
                    % If it does, update the implicit row times dim. There must
                    % be at least one row, so timeStep or sampleRate must be
                    % finite, and startTime can't be overwritten with NaN.
                    newObj = createLike(obj,numel(toSelect));
                    if obj.specifiedAsRate
                        newObj.startTime = obj.startTime + seconds((start-1)/obj.sampleRate);
                        newObj.sampleRate = obj.sampleRate / stride(1);
                        newObj.timeStep = seconds(1/newObj.sampleRate);
                    else
                        newObj.startTime = obj.startTime + (start-1)*obj.timeStep;
                        newObj.timeStep = obj.timeStep*stride(1);
                        if isa(obj.timeStep,'duration')
                            newObj.sampleRate = 1/seconds(newObj.timeStep);
                        else
                            newObj.sampleRate = NaN;
                        end
                    end
                elseif coder.internal.isConst(size(stride)) && isempty(stride)
                    % An empty selection does not preserve regularity per se,
                    % but should preserve implicitness.
                    newObj = createLike(obj,numel(toSelect));
                else
                    % If it does not, replace the existing implicit row times dim.
                    rowtimes = obj.getRowTimes(toSelect);
                    newObj = matlab.internal.coder.tabular.private.explicitRowTimesDim(numel(rowtimes),rowtimes);
                end
            elseif matlab.internal.datatypes.isColon(toSelect)
                % A colon subscript leaves the row times alone.
                newObj = obj;
            else
                % All other subscripts should already have been converted to indices.
                assert(false);
            end
        end
        
        %-----------------------------------------------------------------------
        function template = rowTimesTemplate(obj)
            % Return an instance of the row times' class, with same time zone and format.
            template = obj.startTime;
        end
        
        %-----------------------------------------------------------------------
        function subs = timerange2subs(obj,left,right,intervalType)
            % Return a colonDescriptor indicating which row times are in the
            % specified interval.
            
            t0 = obj.startTime;
            dt = obj.timeStep;
            
            % check for mismatched types
            t0class = class(t0);
            coder.internal.assert(isa(left, t0class), ...
                'MATLAB:timerange:MismatchRowTimesType', t0class, class(left));
            coder.internal.assert(isa(right, t0class), ...
                'MATLAB:timerange:MismatchRowTimesType', t0class, class(right));
            
            % Find the (possibly non-integer) number of time steps from the
            % start time to the left/right interval endpoints.
            dtnumeric = milliseconds(dt);
            tLeft = milliseconds(left - t0);
            tRight = milliseconds(right - t0);
            if obj.specifiedAsRate
                fs = obj.sampleRate;
                nLeft = (tLeft*fs) / 1000; % 0-based
                nRight = (tRight*fs) / 1000;
            else
                nLeft = tLeft / dtnumeric; % 0-based
                nRight = tRight / dtnumeric;
            end
            % In an optimized regular timetable the row times are at whole
            % multiples of the time step (when finite). However, the time
            % range's endpoints may be off a bit from those ideal multiples,
            % so use a tolerance to determine beginning/ending rows (e.g. a
            % closed interval with left endpoint just above a row's time
            % will pick up that row).
            tol = 1000*eps*max(1,1e-6/abs(dtnumeric)); % transition to absolute at 1ns (1e-6ms) steps
            
            if isfinite(dtnumeric) % dt is numeric by now
                % Find the row indices corresponding to the left/right endpoints.
                switch intervalType
                    case {'openright' 'closedleft'}
                        iLeft = ceil(nLeft-tol);
                        iRight = ceil(nRight-tol)-1;
                    case {'openleft' 'closedright'}
                        iLeft = floor(nLeft+tol)+1;
                        iRight = floor(nRight+tol);
                    case 'open'
                        iLeft = floor(nLeft+tol)+1;
                        iRight = ceil(nRight-tol)-1;
                    case 'closed'
                        iLeft = ceil(nLeft-tol);
                        iRight = floor(nRight+tol);
                    otherwise
                        % need to check again because intervalType may not be
                        % compile time constant
                        coder.internal.assert(~any(strcmp(intervalType, {'openright', ...
                            'closedleft', 'openleft', 'closedright', 'open', 'closed'})), ...
                            'MATLAB:timerange:InvalidIntervalType');
                        iLeft = 0;  % assign dummy results
                        iRight = 0;
                end
                iLeft = iLeft + 1; % 0-based -> 1-based
                iRight = iRight + 1;
                % Return the expanded indices if the timerange overlaps the dim
                % object's row times, otherwise return an empty set of indices.
                if (iLeft <= iRight) && (iLeft <= obj.length) && (iRight >= 1)
                    %subs = matlab.internal.ColonDescriptor(max(iLeft,1),1,min(iRight,obj.length));
                    subs = max(iLeft,1):min(iRight,obj.length);
                else
                    subs = 1:0;
                end
            else
                % A non-finite time step (duration or calendarDuration) should
                % not match any range.
                subs = 1:0;
            end
        end
        
        %-----------------------------------------------------------------------
        function rowtimes = createExtendedRowTimes(obj,len)
            % Utility function used by vertcat. Create a longer RowTimes
            % that is of the same type. For implicit rowtimes, the new
            % RowTimes will have the same time step or sample rate.
            tempObj = obj.createLike(len);
            rowtimes = tempObj.labels;
        end
    end
    
    %===========================================================================
    methods (Static)
        function [canBeImplicit,explicitRowTimes] = implicitOrExplicit(length,startTime,timeStep,sampleRate)
            coder.internal.prefer_const(length, startTime, timeStep, sampleRate);
           
            % Decide if an a timetable can have an implicitly-stored row times
            % vector for a specified set of regular time parameters. Reasons why
            % it can't:
            % * time step too small or large (including 0 or Inf), or not finite
            % * sample rate too small or large (including 0 or Inf), or not finite
            % If it can't, return the appropriate explicit row times vector.
            if isnumeric(timeStep) && isequal(timeStep,[]) % short-circuit isequal for datetime/duration timestep
                % If timeStep is [], assume sampleRate specified.
                haveSampleRate = true;
                haveTimeStep = false;
            else
                % check that timeStep and sampleRate are not both specified
                coder.internal.assert(isequal(sampleRate,[]), ...
                    'MATLAB:timetable:TimeStepSampleRateConflict');
                % If sampleRate is [], assume timeStep specified.
                haveSampleRate = false;
                haveTimeStep = true;
            end
            
            if coder.internal.isConst(length) && length == 0
                % If the timetable has no rows, "storing" row times explicitly
                % would lose the information contained in startTime and
                % timeStep/sampleRate. So for 0xM, always implicit. When the
                % timetable grows, the row times might then be converted to
                % explicitly-stored, e.g. if some of the params are non-finite.
                canBeImplicit = true;
            elseif isfinite(startTime)
                if haveSampleRate
                    timeStepMillis = 1000/sampleRate; % might overflow -> NaN tol
                    if isa(startTime,'datetime')
                        % The time step corresponding to the specified sample rate
                        % must be large enough in a (somewhat arbitrary) absolute sense,
                        % but finite and not so large that the stop time overflows.
                         if isfinite(startTime + duration.fromMillis(length*timeStepMillis))
                            tol = 1e-9; % 1e-12s
                        else
                            tol = NaN;
                        end
                    else
                        % The time step corresponding to the specified sample rate
                        % must be large enough relative to the magnitude of the
                        % largest timestamp, but finite and not so large that the
                        % stop time overflows.
                        startTimeMillis = milliseconds(startTime);
                        stopTimeMillis = startTimeMillis + length*timeStepMillis; % might overflow -> NaN tol
                        tol = 3*eps(max(abs(startTimeMillis),abs(stopTimeMillis),'includeNaN'));
                    end
                    canBeImplicit = (abs(timeStepMillis) > tol);
                elseif haveTimeStep
                    haveDurationTimeStep = isa(timeStep,'duration');
                    if ~haveDurationTimeStep % timeStep is a calendarDuration
                        % Treat a non-zero, finite "pure time" calendarDuration as a duration.
                        [isPureTime,isPureDays,isPureMonths,dt] = isPureNonZeroCalendarDuration(timeStep);
                        if isPureTime
                            timeStep = dt;
                            haveDurationTimeStep = true;
                        end
                    end
                    if haveDurationTimeStep
                        % startTime might be a datetime or duration
                        timeStepMillis = milliseconds(timeStep);
                        if isa(startTime,'datetime')
                            % The time step must be large enough in a (somewhat arbitrary)
                            % absolute sense, but finite and not so large that the stop
                            % time overflows.
                            if isfinite(startTime + length*timeStep)
                                tol = 1e-9; % 1e-12s
                            else
                                tol = NaN;
                            end
                        else
                            % The time step must be large enough relative to the magnitude
                            % of the largest timestamp, but finite and not so large that
                            % the stop time overflows.
                            startTimeMillis = milliseconds(startTime);
                            stopTimeMillis = startTimeMillis + length*timeStepMillis; % might overflow -> NaN tol
                            tol = 3*eps(max(abs(startTimeMillis),abs(stopTimeMillis),'includeNaN'));
                        end
                        canBeImplicit = (abs(timeStepMillis) > tol);
                    else % timeStep is a calendarDuration
                        % startTime will only be a datetime
                        startTimeDV = datevec(startTime);
                        
                        % A calendarDuration timestep must be non-zero, finite, and pure
                        % (either days or months, already weeded out pure time).
                        %
                        % However, if the timeStep is specified in months, and the startTime
                        % is near the end of a non-Feb month, creating an optimized
                        % timetable could lead to end-of-month mistakes later on. Create an
                        % explicitRowTimesDim to avoid that.
                        %
                        % There are no fractional calendar days or months, so the timeStep
                        % cannot be too small, but it must be finite and not so large that the
                        % stop time overflows.
                        canBeImplicit = (isPureDays || (isPureMonths && (startTimeDV(3) <= 28))) ...
                                        && isfinite(startTime + length*timeStep);
                        
                        if canBeImplicit
                            startTimeTZ = startTime.TimeZone;
                            switch startTimeTZ
                            case {'' 'UTC'}
                                % No other issues
                            case 'UTCLeapSeconds'
                                % Analogous things can happen if the timeStep is specified
                                % in either days or months, and if startTime is on a leap
                                % second.
                                canBeImplicit = (startTimeDV(6) < 60);
                            otherwise
                                % Analogous things can happen if the timeStep is specified
                                % in either days or months, and if startTime is between 1am
                                % and 2am, and therefore a subsequent row time might be in
                                % a fall DST overlap.
                                canBeImplicit = (startTimeDV(4) < 1) || (2 <= startTimeDV(4));
                            end
                        end
                    end
                end
            else % non-finite startTime with length > 0
                canBeImplicit = false;
            end
            
            % if we are unsure, assume implicit as that is the more general
            % case
            if ~canBeImplicit && coder.internal.isConst(canBeImplicit)
                % If timeStep or sampleRate is too extreme, create an explicit
                % row times vector, subject to round-off or non-finites.
                if haveTimeStep
                    explicitRowTimes = matlab.internal.coder.tabular.private.rowTimesDim.regularRowTimesFromTimeStep(...
                        startTime,timeStep,length);
                else
                    explicitRowTimes = matlab.internal.coder.tabular.private.rowTimesDim.regularRowTimesFromSampleRate(...
                        startTime,sampleRate,length);
                end
            else
                explicitRowTimes = [];
            end
        end
        
        function result = matlabCodegenSoftNontunableProperties(~)
            result = {'length'};
        end
    end
    
    %===========================================================================
    methods (Access=protected)
        function rowTimes = getRowTimes(obj,subscripts)
            if obj.specifiedAsRate
                if nargin == 1
                    rowTimes = obj.regularRowTimesFromSampleRate(obj.startTime,obj.sampleRate,obj.length);
                else
                    % The explicit row times vector could be quite large. Only
                    % get the requested elements.
                    if islogical(subscripts), subscripts = find(subscripts); end
                    rowTimes = obj.regularRowTimesFromSampleRate(obj.startTime,obj.sampleRate,obj.length,subscripts);
                end
            else
                % A calendarDuration time step is required to be "pure", so
                % don't need regularRowTimesFromCalDurTimeStep.
                if nargin == 1
                    rowTimes = obj.regularRowTimesFromTimeStep(obj.startTime,obj.timeStep,obj.length);
                else
                    % The explicit row times vector could be quite large. Only
                    % get the requested elements.
                    if islogical(subscripts), subscripts = find(subscripts); end
                    rowTimes = obj.regularRowTimesFromTimeStep(obj.startTime,obj.timeStep,obj.length,subscripts);
                end
            end
        end
        
        %-----------------------------------------------------------------------
        function tf = areRowTimesEqual(obj1,obj2)
            if isa(obj2,class(obj1))
                % The first object is an implicitRegularRowTimesDim, and if the
                % second is too, the comparison is on the start times and time
                % steps. One dim may have been constructed from a time step, the
                % other from a sample rate, but if the start times and
                % (possibly computed) time steps are equal, the time vectors are
                % equal. There's no tolerance to account for round-off in a
                % computed time step.
                tf = isequal(obj1.startTime,obj2.startTime) ...
                    && isequal(obj1.timeStep,obj2.timeStep);
            else
                % Otherwise we have an explicitRowTimesDim, do the comparison on
                % the expanded out row times vectors.
                tf = obj1.startTime == obj2.labels(1) ... % quick check before expanding
                    && isequaln(obj1.labels,obj2.labels);
            end
        end
        function tf = areRowTimesEqualn(obj1,obj2)
            % See areRowTimesEqual.
            if isa(obj1,class(obj2))
                tf = isequaln(obj1.startTime,obj2.startTime) ...
                    && isequaln(obj1.timeStep,obj2.timeStep);
            else
                tf = obj1.startTime == obj2.labels(1) ... % quick check before expanding
                    && isequaln(obj1.labels,obj2.labels);
            end
        end
        
        %-----------------------------------------------------------------------
        function obj = validateAndAssignLabels(obj,newLabels,~,fullAssignment,~,~,~,~)
            % Only accept datetime or duration, strings are not auto-converted.
            % Labels are required for a time dimension, so do not allow a full
            % assignment of a 0x0 to clear them out.
            assert(fullAssignment);  % partial assignment not implemented yet
            coder.internal.assert(isa(newLabels,'datetime') || isa(newLabels,'duration'), ...
                'MATLAB:timetable:InvalidRowTimes');
            
            % in codegen, not OK to replace datetime with duration or vice versa.
            coder.internal.assert(isa(newLabels,class(obj.startTime)), ...
                'MATLAB:timetable:MixedRowTimesAssignment',class(obj.startTime));
            
                % The number of new row times has to match what's being assigned to.
                newRowTimes = newLabels(:); % a col vector, conveniently forces any empty to 0x1
            coder.internal.assert(numel(newRowTimes) == obj.length, ...
                obj.IncorrectNumberOfLabelsExceptionID);
                
            % codegen does not support switching between explicit and
            % implicit rowtimes. If newRowTimes is not regular, return an error.
                % However, when assigning an empty row times vector with the same
                % type to an (already) 0xM timetable, leave the dim as implicit
                % so that the regular time params are preserved. representation.
            if (obj.length > 0)
                [tf,dt] = matlab.internal.coder.datetime.isRegularTimeVector(newRowTimes,'time');
                % scalar rowtimes returns as irregular, but ok to store as
                % implicit
                coder.internal.assert(tf || obj.length == 1, 'MATLAB:timetable:IrregularRowTimesAssignment');
                obj.startTime = newRowTimes(1);
                % make sure new computed timestep does not cause mismatched 
                % format error by forcing it to use same format as old
                obj.timeStep = duration.fromMillis(milliseconds(dt), obj.timeStep.Format);
                obj.sampleRate = 1/seconds(dt);
            end
        end
                
        %-----------------------------------------------------------------------
        function [subscripts,indices] = validateNativeSubscripts(obj,subscripts,~)

            
            t0 = obj.startTime;
            dt = obj.timeStep;
            if isa(t0,'datetime')
                if ~isa(subscripts,'datetime')
                    coder.internal.assert(matlab.internal.coder.datatypes.isText(subscripts),...
                        'MATLAB:timetable:InvalidRowSubscriptsDatetime');
                    subscripts = matlab.internal.coder.datetime.text2timetype(...
                        subscripts,'MATLAB:datetime:AutoConvertString',t0);
                    coder.internal.errorIf(isa(subscripts,'duration'),...
                        'MATLAB:timetable:InvalidRowSubscriptsDatetime');
                end
            else % isa(t0,'duration')
                
                if ~isa(subscripts, 'duration')
                    coder.internal.assert(matlab.internal.coder.datatypes.isText(subscripts),...
                        'MATLAB:timetable:InvalidRowSubscriptsDuration'); 
                    subscripts = matlab.internal.coder.datetime.text2timetype(...
                        subscripts,'MATLAB:datetime:AutoConvertString',t0);
                    coder.internal.errorIf(isa(subscripts,'datetime'),...
                        'MATLAB:timetable:InvalidRowSubscriptsDuration');
                end
            end
            
            if isa(dt,'duration')
                useExactTimeWithTol = true;
            else
                [dtMonths,dtDays,dtTime] = split(dt,{'m' 'd' 't'});
                if dtTime ~= 0 % including isnan(dt)
                    % When the time step is a "pure time" calendarDuration,
                    % treat as if it were a duration.
                    dt = dtTime; % time component is a duration
                    useExactTimeWithTol = true;
                else % whole months or whole days
                    useExactTimeWithTol = false;
                    if dtMonths ~= 0
                        dt = dtMonths;
                        calUnit = 'm';
                    else % dtDays ~= 0
                        dt = dtDays;
                        calUnit = 'd';
                    end
                end
            end
            
            % A non-finite time step (duration or calendarDuration) will lead to
            % a NaN in the calculation of row index, and will not match any rows.
            
            if useExactTimeWithTol
                % Get the nearest row time to each subscript. Do calculations in
                % raw ms from start time.
                t = milliseconds(subscripts - t0);
                dt = milliseconds(dt);
                if obj.specifiedAsRate
                    fs = obj.sampleRate;
                    i = min(max(round((t*fs)/1000),0),obj.length-1); % index of nearest row, 0-based
                    ti = ((1000*i)/fs); % time of nearest row
                else
                    i = min(max(round(t/dt),0),obj.length-1); % index of nearest row, 0-based
                    ti = i*dt; % time of nearest row
                end
                % In an optimized regular timetable the row times are at whole
                % multiples of the time step (when finite). However, the time
                % subscripts may be off a bit from those ideal multiples, so use
                % a relative (to the time step) tolerance to match subscripts to
                % nearest row times, transitioning to absolute tolerance for
                % time steps smaller than 1ns.
                tol = 1000*eps*max(abs(dt),1e-6); % transition at 1ns (1e-6ms) steps
                % Find within-tolerance matches to the nearest row time.
                matches = (abs(t - ti) < tol);
            else % use calendar units
                % Get the (whole) number of months or days from the start time
                % to each subscript, plus any time left over.
                [t,timeLeftOver] = split(between(t0,subscripts,{calUnit 't'}),{calUnit 't'});
                % A calendarDuration time step is (when not pure time) either a
                % whole number of months or a whole number of days. Get the
                % (possibly non-integer) number of time steps from start time to
                % each subscript. There are no fractional calendar months or
                % days, so assign 1/2 of a unit to any left-over time.
                n = (t + .5*(timeLeftOver ~= 0))/ dt;
                % Get the nearest row index
                i = min(max(round(n),0),obj.length-1); % 0-based
                % Unless the start time is specified to high resolution, there
                % will not be round-off in creating the time subscripts, so
                % require exact matches to the nearest row time.
                matches = (n == i);
            end
            indices = i + 1; % 0-based -> 1-based
            indices(~matches) = 0; % return zeros for no match
        end
    end
    
    %===========================================================================
    methods(Hidden, Access = {?matlab.internal.coder.tabular,...
                              ?matlab.internal.coder.tabular.private.rowTimesDim})
        function tf = isSpecifiedAsRate(obj)
            % Utility function for codegen. Used to determine if the rowDim is
            % created using sample rate or time step.
            tf = obj.specifiedAsRate;
        end
    end
end

%===========================================================================
function [tfTime,tfDays,tfMonths,dt] = isPureNonZeroCalendarDuration(dt)
% Determine if a calendar duration time step is non-zero, finite, and "pure"
% with respect to time, days, or months. This is strictly for performance: save
% implicitOrExplict from calling isPureNonZeroCalendarDurationForUnit repeatedly.
%
% Zero or non-finite calendar durations are not considered pure because (1) it's
% not useful for callers, and (2) all three components are identical (0, Inf or
% NaN) in those cases.
%
% Also return the time step in the specified unit.

[m,d,t] = split(dt,{'month','day','time'});

tfTime = false;
tfDays = false;
tfMonths = false;
dt = NaN;
if isfinite(t)
    if t ~= 0
        tfTime = (m == 0) && (d == 0);
        dt = t; % times from split come out as a duration already
    elseif d ~= 0
        tfDays = (m == 0); % && (t == 0)
        dt = caldays(d);
    elseif m ~= 0
        tfMonths = true; % && (d == 0) && (t == 0)
        dt = calmonths(m);
    end
end
end
