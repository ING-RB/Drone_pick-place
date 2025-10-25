classdef (Sealed) implicitRegularRowTimesDim < matlab.internal.tabular.private.rowTimesDim
%REGULARROWTIMESDIM Internal class to represent an optimized regular timetable's rows dimension.

% This class is for internal use only and will change in a
% future release.  Do not use this class.

    %   Copyright 2018-2022 The MathWorks, Inc.
    
    properties (Dependent=true, GetAccess=public, SetAccess=protected)
        labels
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
            import matlab.internal.tabular.private.implicitRegularRowTimesDim
            import matlab.internal.tabular.private.explicitRowTimesDim
            
            if isnumeric(startTime)
                error(message('MATLAB:timetable:InvalidStartTimeNumeric'));
            elseif ~isscalar(startTime) || ~(isa(startTime,'datetime') || isa(startTime,'duration'))
                error(message('MATLAB:timetable:InvalidStartTime'));
            elseif isa(startTime,'duration') && isa(obj.timeStep,'calendarDuration')
                error(message('MATLAB:timetable:DurationStartTimeWithCalDurTimeStep'));
            end
            
            % Keep the row times stored implicitly unless the new start time makes
            % the time step unreasonably large or small.
            [keepImplicit,explicitRowTimes] = ...
                implicitRegularRowTimesDim.implicitOrExplicit(obj.length,startTime,obj.timeStep,[]);
            if keepImplicit
                obj.startTime = startTime;
            else
                obj = explicitRowTimesDim(length(explicitRowTimes),explicitRowTimes,obj.timeEvents);
                
            end
        end
        %-----------------------------------------------------------------------
        function obj = setTimeStep(obj,timeStep)
            import matlab.internal.tabular.private.implicitRegularRowTimesDim
            import matlab.internal.tabular.private.explicitRowTimesDim
            
            if ~isscalar(timeStep)
                error(message('MATLAB:timetable:InvalidTimeStep'));
            elseif isa(timeStep,'duration')
                haveDurationTimeStep = true;
            elseif isa(timeStep,'calendarDuration')
                if ~isa(obj.startTime,'datetime')
                    error(message('MATLAB:timetable:DurationStartTimeWithCalDurTimeStep'));
                end
                haveDurationTimeStep = false;
            elseif isnumeric(timeStep)
                error(message('MATLAB:timetable:InvalidTimeStepNumeric'));
            else
                error(message('MATLAB:timetable:InvalidTimeStep'));
            end
            
            % Keep the row times stored implicitly unless the new time step is
            % unreasonably large or small (including 0 or Inf) or NaN.
            [keepImplicit,explicitRowTimes] = ...
                implicitRegularRowTimesDim.implicitOrExplicit(obj.length,obj.startTime,timeStep,[]);
            if keepImplicit
                obj.specifiedAsRate = false;
                obj.timeStep = timeStep;
                if haveDurationTimeStep
                    obj.sampleRate = 1/seconds(timeStep);
                else % calendarDuration
                    % sampleRate is in Hz, don't attempt to convert a calendarDuration to seconds
                    obj.sampleRate = NaN;
                end
            else
                obj = explicitRowTimesDim(length(explicitRowTimes),explicitRowTimes,obj.timeEvents);
            end
            
        end
        %-----------------------------------------------------------------------
        function obj = setSampleRate(obj,sampleRate)
            import matlab.internal.tabular.private.implicitRegularRowTimesDim
            import matlab.internal.tabular.private.explicitRowTimesDim
            
            if ~(isnumeric(sampleRate) && isscalar(sampleRate) && isreal(sampleRate))
                % SampleRate must be a scalar number, but may be negative, zero, or non-finite
                error(message('MATLAB:timetable:InvalidSampleRate'));
            end
            sampleRate = double(sampleRate);
            
            % Keep the row times stored implicitly unless the new sample rate is
            % unreasonably large or small (including 0 or Inf) or NaN.
            [keepImplicit,explicitRowTimes] = ...
                implicitRegularRowTimesDim.implicitOrExplicit(obj.length,obj.startTime,[],sampleRate);
            if keepImplicit
                obj.specifiedAsRate = true;
                obj.sampleRate = sampleRate;
                obj.timeStep = seconds(1/sampleRate);
            elseif isnan(sampleRate) && isnan(obj.sampleRate) && ~isnan(obj.timeStep) % && isa(timeStep,'calendarDuration')
                % SampleRate is NaN when TimeStep is a finite calendarDuration,
                % leave the implicit row times alone in that case.
            else
                obj = explicitRowTimesDim(length(explicitRowTimes),explicitRowTimes,obj.timeEvents);
            end
        end
    end
    
    %===========================================================================
    methods
        function obj = implicitRegularRowTimesDim(length,startTime,timeStep,sampleRate,timeEvents)
            
            % There is no error checking on the "regular" parameters, the caller
            % should use validateTimeVectorParams and implicitOrExplicit first.
            obj = obj.init(length,[]);
            obj.startTime = startTime;
            
            if isnumeric(sampleRate) && isequal(timeStep,[])
                % Given a sample rate, and not a time step
                obj.specifiedAsRate = true;
                obj.sampleRate = sampleRate;
                obj.timeStep = seconds(1/sampleRate);
            elseif isequal(sampleRate,[])
                % Given a time step, and not a sample rate
                obj.specifiedAsRate = false;
                obj.timeStep = timeStep;
                if isa(timeStep,'duration')
                    obj.sampleRate = 1/seconds(timeStep);
                else % calendarDuration
                    % sampleRate is in Hz, don't attempt to convert a calendarDuration to seconds
                    obj.sampleRate = NaN;
                end
            else
                % Given both
                error(message('MATLAB:timetable:TimeStepSampleRateConflict'));
            end

            if nargin == 5
                obj.timeEvents = timeEvents;
            end
        end
        
        %-----------------------------------------------------------------------
        function obj = init(obj,dimLength,dimLabels)
            % This method should never be called with explicit row times. It
            % assumes that an object has already been created with the correct
            % "regular" parameters, and only needs the length set. It exists
            % mostly to provide polymorphism with explicitRowTimesDim, in which
            % init does (a little more) work.
            assert(nargin==2 || isequal(dimLabels,[]));
            obj.length = dimLength;
            obj.hasLabels = true;
        end
        
        %-----------------------------------------------------------------------
        function obj = createLike(obj,dimLength,dimLabels)
            assert(nargin==2 || isequal(dimLabels,[])); % should never be called with explicit row times
            obj.length = dimLength;
            % Ordinarily, setting .length but not .labels leaves a tabularDimension
            % in an inconsistent state, but .labels is a dependent property in 
            % implicitRegularRowTimesDim.

            % Clear out timeEvents.
            obj.timeEvents = [];
        end

        %-----------------------------------------------------------------------
        function tf = hasExplicitLabels(~)
            % HASEXPLICITLABELS Determine if the rowDim obj has explicitly stored
            % labels.
            tf = false;
        end
        
        %-----------------------------------------------------------------------
        function [tf,dt] = isregular(obj,unit)
            dt = obj.timeStep;
            
            % Validate single char vector inputs
            if nargin == 2 && ~matlab.internal.datatypes.isScalarText(unit)
                error(message('MATLAB:datetime:InvalidSingleComponent'));
            end
            
            % Test if row times are regularly-spaced in time.
            if nargin == 1 || strncmpi(unit, 'time', max([1,length(unit)])) % max fends off ''
                if obj.specifiedAsRate
                    % Row times with a finite sample rate are regular w.r.t. time.
                    tf = isfinite(obj.sampleRate);
                    dt = seconds(1/obj.sampleRate);
                elseif isa(dt,'duration')
                    % Row times with a finite duration time step are regular w.r.t. time.
                    tf = isfinite(dt);
                    dt = obj.timeStep;
                elseif isa(dt,'calendarDuration')
                    % Row times with a calendar duration time step might be regular w.r.t. time.
                    [tf,dt] = matlab.internal.datetime.isRegularTimeVector(obj.getRowTimes(),'time');
                else
                    assert(false);
                end
                
            % Test if row times are regularly-spaced in the specified calendar unit
            else
                if obj.specifiedAsRate || isa(dt,'duration')
                    % Row times specified with a sample rate or a duration time
                    % step aren't regular w.r.t. a calendar duration unit.
                    tf = false;
                    dt = duration.fromMillis(nan);
                    
                else
                    % The row times are datetimes with a calendar duration time
                    % step, determine if the time step is regular w.r.t specified
                    % calendar unit.
                    [tf,dt] = isPureNonZeroCalendarDurationForUnit(dt,unit);
                end
            end
            
            % Make sure the start time is finite, an empty rowDim may have a
            % non-finite start time.
            tf = tf && isfinite(obj.startTime);
        end
        
        %-----------------------------------------------------------------------
        function rowTimes = serializeRowTimes(obj)
            % Save the regular row times parameters as a struct recognizable by
            % rowTimeDim.unserializeRowTimes, even for pre-R2018b if the time
            % step is a duration. However, if the time step is a calendarDuration,
            % the pre-R2016b timetable's loadobj will fail.
            rowTimes.origin = obj.startTime;
            rowTimes.specifiedAsRate = obj.specifiedAsRate;
            rowTimes.stepSize = obj.timeStep;
            rowTimes.sampleRate = obj.sampleRate;
        end
        
        %-----------------------------------------------------------------------
        function s = getProperties(obj)
            % Same order as rowNamesDim.propertyNames
            s.RowTimes = obj.getRowTimes();
            s.StartTime = obj.startTime;
            s.SampleRate = obj.sampleRate;
            s.TimeStep = obj.timeStep;
            s.Events = obj.timeEvents;
        end
        
        %-----------------------------------------------------------------------
        function obj = lengthenTo(obj,maxIndex,newLabels)
            
            if nargin < 3
                if obj.specifiedAsRate
                    [keepImplicit,explicitRowTimes] = obj.implicitOrExplicit(maxIndex,obj.startTime,[],obj.sampleRate);
                else
                    [keepImplicit,explicitRowTimes] = obj.implicitOrExplicit(maxIndex,obj.startTime,obj.timeStep,[]);
                end
                if keepImplicit
                    % The existing dim is regular, just extend it with the same time
                    % step or sample rate.
                    obj.length = maxIndex;
                else
                    % The lengthened rowDim can't be stored implcitly, e.g. an empty implicit
                    % rowDim with non-finite params must become explicit.
                    % when adding rows.
                    obj = matlab.internal.tabular.private.explicitRowTimesDim(length(explicitRowTimes),explicitRowTimes,obj.timeEvents);
                    obj = obj.lengthenTo(maxIndex);
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
                rowtimes = obj.labels;
                obj = matlab.internal.tabular.private.explicitRowTimesDim(length(rowtimes),rowtimes,obj.timeEvents);
                obj = obj.lengthenTo(maxIndex,newLabels);
            end
        end
        
        %-----------------------------------------------------------------------
        function obj = selectFrom(obj,toSelect)
            
            import matlab.internal.datatypes.isColon
            
            if islogical(toSelect)
                % A logical subscript may or may not result in an regular
                % result, most likely not, but have to convert to indices to
                % determine, and would have to convert it anyway if not.
                toSelect = find(toSelect);
            end
            
            isColonObj = isobject(toSelect) && isa(toSelect,'matlab.internal.ColonDescriptor');
            if isnumeric(toSelect) || isColonObj
                if isnumeric(toSelect)
                    if isscalar(toSelect)
                        stride = 1;
                    else
                        stride = unique(diff(toSelect));
                    end
                    if isscalar(stride)
                        start = toSelect(1); % this is the min if stride is a scalar
                    end
                else % isColonObj
                    stride = double(toSelect.Stride);
                    start = double(toSelect.Start);
                    % ColonDescriptor overloads length, so length(toSelect) below is OK
                end
                % Determine if the selection preserves regularity.
                if isscalar(stride)
                    % If it does, update the implicit row times dim. There must
                    % be at least one row, so timeStep or sampleRate must be
                    % finite, and startTime can't be overwritten with NaN.
                    if obj.specifiedAsRate
                        obj.startTime = obj.startTime + seconds((start-1)/obj.sampleRate);
                        obj.sampleRate = obj.sampleRate / stride;
                        obj.timeStep = seconds(1/obj.sampleRate);
                    else
                        obj.startTime = obj.startTime + (start-1)*obj.timeStep;
                        obj.timeStep = obj.timeStep*stride;
                        if isa(obj.timeStep,'duration')
                            obj.sampleRate = 1/seconds(obj.timeStep);
                        else
                            obj.sampleRate = NaN;
                        end
                    end
                    obj.length = length(toSelect);
                elseif isempty(stride)
                    % An empty selection does not preserve regularity per se,
                    % but should preserve implicitness.
                    obj.length = length(toSelect);
                else
                    % If it does not, replace the existing implicit row times dim.
                    rowtimes = obj.getRowTimes(toSelect);
                    obj = matlab.internal.tabular.private.explicitRowTimesDim(length(rowtimes),rowtimes,obj.timeEvents);
                end
            elseif isColon(toSelect)
                % A colon subscript leaves the row times alone.
            else
                % All other subscripts should already have been converted to indices.
                assert(false);
            end
        end
        
        %-----------------------------------------------------------------------
        function obj = shortenTo(obj,maxIndex)
            % implicitRegularRowTimesDim doesn't store the row labels explicitly,
            % don't try to shorten them.
            obj.length = maxIndex;
        end
        
        %-----------------------------------------------------------------------
        function obj = deleteFrom(obj,toDelete)
            
            import matlab.internal.datatypes.isColon
            
            if islogical(toDelete)
                % A logical subscript may or may not result in an regular
                % result, most likely not, but have to convert to indices to
                % determine, and would have to convert it anyway if not.
                toDelete = find(toDelete);
            end
            
            % A much simpler implementation would be
            %    toKeep = 1:obj.length; toKeep(toDelete) = []; obj = obj.selectFrom(toKeep)
            % but that creates a potentially large index vector
            
            % Determine if the deletion preserves regularity. Deleting all rows
            % doesn't preserve regularity per se, but should leave the row times
            % parameters alone and only change the length.
            if isobject(toDelete) && isa(toDelete,'matlab.internal.ColonDescriptor')
                delStart = double(toDelete.Start);
                delStop = double(toDelete.Stop);
                delStride = double(toDelete.Stride);
                % ColonDescriptor overloads length, so length(toDelete) below is OK
                
                % Look for the special cases that preserve regularity.
                if (delStart == 1) && (delStride == 1) % delete rows 1:m, including 1:end
                    if delStop < obj.length
                        keepStart = delStop + 1;
                        keepLen = obj.length - delStop;
                    else % deleting all rows
                        keepStart = 1;
                        keepLen = 0;
                    end
                    keepStride = delStride;
                    preservesRegularity = true;
                elseif (delStop == obj.length) && (delStride == 1) % delete rows m:end
                    keepStart = 1;
                    keepStride = delStride;
                    keepLen = delStart - 1;
                    preservesRegularity = true;
                else
                    % Any other colonobj deletion leaves an irregular subset of
                    % rows, expand out the colon object
                    toKeep = 1:obj.length; toKeep(delStart:delStride:delStop) = [];
                    preservesRegularity = false;
                end
            elseif isnumeric(toDelete)
                delStride = unique(diff(toDelete));
                if isscalar(delStride)
                    if delStride < 0, toDelete = flip(toDelete); end % order doesn't matter for deletion
                    delStart = toDelete(1); % this is the min if stride is a scalar
                    delStop = toDelete(end); % this is the max if stride is a scalar
                    % Look for some of the special cases that preserve regularity.
                    if (delStart == 1) && (delStride == 1) % delete rows 1:m, including 1:end, or m:-1:1
                        if delStop < obj.length
                            keepStart = delStop + 1;
                            keepLen = obj.length - delStop;
                        else % deleting all rows
                            keepStart = 1;
                            keepLen = 0;
                        end
                        keepStride = 1;
                        preservesRegularity = true;
                    elseif (delStop == obj.length) && (delStride == 1) % delete rows m:end or end:-1:m
                        keepStart = 1;
                        keepStride = 1;
                        keepLen = delStart - 1;
                        preservesRegularity = true;
                    else
                        % Most other deletions with a regular stride leave an
                        % irregular subset of rows (1:2:end is one exception),
                        % need to expand out toKeep for those. Cases that might
                        % preserve regularity are either very small, or toDelete
                        % would already have been a memory issue. Expand out
                        % toKeep to determine.
                        toKeep = 1:obj.length; toKeep(toDelete) = [];
                        if isscalar(toKeep)
                            keepStride = 1;
                        else
                            keepStride = unique(diff(toKeep));
                        end
                        preservesRegularity = isscalar(keepStride);
                        if preservesRegularity
                            keepStart = toKeep(1);
                            keepLen = length(toKeep);
                        end
                    end
                else
                    % The rows to delete are not regular but the remaining rows
                    % may still be, e.g. deleting all but the middle rows, or
                    % deleting all but one row or all but every third row.
                    % Expand out toKeep to determine.
                    toKeep = 1:obj.length; toKeep(toDelete) = [];
                    if isscalar(toKeep)
                        keepStride = 1;
                    else
                        keepStride = unique(diff(toKeep));
                    end
                    preservesRegularity = isscalar(keepStride);
                    if preservesRegularity
                        keepStart = toKeep(1);
                        keepLen = length(toKeep);
                    end
                end
            elseif isColon(toDelete)
                % A colon subscript deletes all rows.
                preservesRegularity = true;
                keepStart = 1;
                keepLen = 0;
                keepStride = 1;
            else
                % All other subscripts should already have been converted to indices.
                assert(false);
            end
            
            if preservesRegularity
                % If the remaining rows are regular, update the implicit row
                % times dim. There must be at least one row, so timeStep or
                % sampleRate must be finite, and startTime can't be overwritten
                % with NaN.
                if obj.specifiedAsRate
                    obj.startTime = obj.startTime + seconds((keepStart-1)/obj.sampleRate);
                    obj.sampleRate = obj.sampleRate / keepStride;
                    obj.timeStep = seconds(1/obj.sampleRate);
                else
                    obj.startTime = obj.startTime + (keepStart-1)*obj.timeStep;
                    obj.timeStep = obj.timeStep*keepStride;
                    if isa(obj.timeStep,'duration')
                        obj.sampleRate = 1/seconds(obj.timeStep);
                    else
                        obj.sampleRate = NaN;
                    end
                end
                obj.length = keepLen;
            else
                % Otherwise replace the existing implicit row times dim.
                rowtimes = obj.getRowTimes(toKeep);
                obj = matlab.internal.tabular.private.explicitRowTimesDim(length(rowtimes),rowtimes,obj.timeEvents);
            end
        end
        
        %-----------------------------------------------------------------------
        function obj = assignInto(obj,obj2,assignInto)
            if ~isa(obj2,'matlab.internal.tabular.private.implicitRegularRowTimesDim') || ...
                    ~areRowTimesEqual(obj.selectFrom(assignInto),obj2)
                % When both the objs are implicitRegularRowTimesDim, check if we 
                % can keep the obj as implicitRegularRowTimesDim after assignment,
                % otherwise convert it to an explicitRowTimesDim.
                rowTimes = obj.labels;
                obj = matlab.internal.tabular.private.explicitRowTimesDim(length(rowTimes),rowTimes,obj.timeEvents);
                % Assign labels of the explicitRowTimesDim via the protected
                % tabularDimension method, which implicitRegularRowTimesDim has
                % access to.
                obj = obj.assignLabels(obj2.labels,false,assignInto);
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
            
            import matlab.internal.ColonDescriptor
            
            t0 = obj.startTime;
            dt = obj.timeStep;
            if ~isa(left,class(t0)) || ~isa(right,class(t0))
                error(message('MATLAB:datetime:CompareTimeOfDay'));
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
            
            if useExactTimeWithTol
                % Find the (possibly non-integer) number of time steps from the
                % start time to the left/right interval endpoints.
                dt = milliseconds(dt);
                tLeft = milliseconds(left - t0);
                tRight = milliseconds(right - t0);
                if obj.specifiedAsRate
                    fs = obj.sampleRate;
                    nLeft = (tLeft*fs) / 1000; % 0-based
                    nRight = (tRight*fs) / 1000;
                else
                    nLeft = tLeft / dt; % 0-based
                    nRight = tRight / dt;
                end
                % In an optimized regular timetable the row times are at whole
                % multiples of the time step (when finite). However, the time
                % range's endpoints may be off a bit from those ideal multiples,
                % so use a tolerance to determine beginning/ending rows (e.g. a
                % closed interval with left endpoint just above a row's time
                % will pick up that row).
                tol = 1000*eps*max(1,1e-6/abs(dt)); % transition to absolute at 1ns (1e-6ms) steps
            else % use calendar units
                % Get the (whole) number of months or days from the start time
                % to the left/right interval endpoints, plus any time left over.
                % A calendarDuration time step is (when not pure time) either a
                % whole number of months or a whole number of days. Get the
                % (possibly non-integer) number of time steps from start time to
                % each endpoint. There are no fractional calendar months or
                % days, so assign 1/2 of a unit to any left-over time.
                [nCalUnits,timeLeftOver] = split(between(t0,left,{calUnit 't'}),{calUnit 't'});
                nLeft = (nCalUnits + .5*(timeLeftOver ~= 0)) / dt; % 0-based
                [nCalUnits,timeLeftOver] = split(between(t0,right,{calUnit 't'}),{calUnit 't'});
                nRight = (nCalUnits + .5*(timeLeftOver ~= 0)) / dt;
                % Unless the start time is specified to high resolution, there
                % will not be round-off in creating the time subscripts, so
                % determine beginning/ending rows with no tolerance (e.g. a
                % closed interval's endpoints must match a row's time exactly to
                % pick up that row).
                tol = 0;
            end
            
            if isfinite(dt) % dt is numeric by now
                % Find the row indices corresponding to the left/right endpoints.
                % An interval with zero length and either endpoint open does not
                % select any row times.
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
                    error(message('MATLAB:timerange:InvalidIntervalType'));
                end
                iLeft = iLeft + 1; % 0-based -> 1-based
                iRight = iRight + 1;
                % Return a ColonDescriptor if the timerange overlaps the dim
                % object's row times, otherwise return an empty set of indices.
                if (iLeft <= iRight) && (iLeft <= obj.length) && (iRight >= 1)
                    subs = ColonDescriptor(max(iLeft,1),1,min(iRight,obj.length));
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
        function [min,max] = getBounds(obj)
            % Min/max of the rowtimes.
            if obj.length == 0
                if isa(obj.startTime,'datetime')
                    tmp = NaT(1,2);
                else % duration
                    tmp = duration.fromMillis(NaN(1,2));
                end
            else
                if obj.sampleRate >= 0
                    tmp = getRowTimes(obj, [1, obj.length]);
                else % sampleRate < 0
                    tmp = getRowTimes(obj, [obj.length, 1]);
                end
                min = tmp(1);
                max = tmp(2);
            end
        end
    end
    
    %===========================================================================
    methods (Static)
        function [canBeImplicit,explicitRowTimes] = implicitOrExplicit(length,startTime,timeStep,sampleRate)
            % Decide if an a timetable can have an implicitly-stored row times
            % vector for a specified set of regular time parameters. Reasons why
            % it can't:
            % * time step too small or large (including 0 or Inf), or not finite
            % * sample rate too small or large (including 0 or Inf), or not finite
            % If it can't, return the appropriate explicit row times vector.
            
            import matlab.internal.tabular.private.rowTimesDim.regularRowTimesFromTimeStep
            import matlab.internal.tabular.private.rowTimesDim.regularRowTimesFromSampleRate
            
            explicitRowTimes = []; % return [] if the row times can be implicit
            
            if isnumeric(timeStep) && isequal(timeStep,[]) % short-circuit isequal for datetime/duration timestep
                % If timeStep is [], assume sampleRate specified.
                haveSampleRate = true;
                haveTimeStep = false;
            elseif isequal(sampleRate,[])
                % If sampleRate is [], assume timeStep specified.
                haveSampleRate = false;
                haveTimeStep = true;
            else
                % Both timeStep and sampleRate were specified.
                error(message('MATLAB:timetable:TimeStepSampleRateConflict'));
            end
            
            if length == 0
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
            
            if ~canBeImplicit
                % If timeStep or sampleRate is too extreme, create an explicit
                % row times vector, subject to round-off or non-finites.
                if haveTimeStep
                    explicitRowTimes = regularRowTimesFromTimeStep(startTime,timeStep,length);
                else
                    explicitRowTimes = regularRowTimesFromSampleRate(startTime,sampleRate,length);
                end
            end
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
        function obj = validateAndAssignLabels(obj,newLabels,rowIndices,fullAssignment,~,~,~)
            % Only accept datetime or duration, strings are not auto-converted.
            % Labels are required for a time dimension, so do not allow a full
            % assignment of a 0x0 to clear them out. Allow a full assignment to
            % change between datetime and duration, but not a partial assignment.
            if isa(newLabels,'datetime') || isa(newLabels,'duration')
                if fullAssignment
                    % OK to replace datetime with duration or vice versa.
                elseif ~isa(newLabels,class(obj.startTime))
                    error(message('MATLAB:timetable:MixedRowTimesAssignment',class(obj.startTime)));
                end
            else
                error(message('MATLAB:timetable:InvalidRowTimes'));
            end
            
            if fullAssignment
                % The number of new row times has to match what's being assigned to.
                newRowTimes = newLabels(:); % a col vector, conveniently forces any empty to 0x1
                if numel(newRowTimes) ~= obj.length
                    obj.throwIncorrectNumberOfLabels();
                end
                
                % The check to recognize a new time vector as regular might be
                % expensive, in most cases we replace the existing implicit row
                % times dim with an explicit dim. To modify the row times while
                % preserving the implicit dim one should assign to the StartTime
                % and TimeStep/SampleRate properties instead of to RowTimes.
                % However, when assigning an empty row times vector with the same
                % type to an (already) 0xM timetable, leave the dim as implicit
                % so that the regular time params are preserved. representation.
                if (obj.length > 0) || ~isa(newRowTimes,class(obj.startTime))
                    obj = matlab.internal.tabular.private.explicitRowTimesDim(length(newRowTimes),newRowTimes,obj.timeEvents);
                end
            else
                % The number of new labels has to match what's being assigned to.
                if numel(newLabels) ~= numel(rowIndices)
                    obj.throwIncorrectNumberOfLabelsPartial();
                end
                % Assume that a partial assignment will break regularity, do not do
                % the potentially expensive check to determine if the result would
                % be regular. Just replace the existing implicit row times dim with
                % an explicit dim.
                newRowTimes = obj.labels;
                obj = matlab.internal.tabular.private.explicitRowTimesDim(length(newRowTimes),newRowTimes,obj.timeEvents);
                % Assign labels of the explicitRowTimesDim via the protected
                % tabularDimension method, which implicitRegularRowTimesDim has
                % access to.
                obj = obj.assignLabels(newLabels,fullAssignment,rowIndices);
            end
        end
                
        %-----------------------------------------------------------------------
        function [subscripts,indices,canPreserveShape] = validateNativeSubscripts(obj,subscripts)
            import matlab.internal.datatypes.isText
            import matlab.internal.datetime.text2timetype
            
            % canPreserveShape output argument is used to let the caller know if the
            % the indices could be reshaped (if needed) to match the shape of
            % the original subscripts.
            % For rowTimesDim we always return false for native subscripts
            % because subscripting using row times would drop out-of-range
            % values without any errors, so it is not always possible to
            % preserve the shape in such cases. Hence we would always return a
            % column vector for this case.
            canPreserveShape = false;
            t0 = obj.startTime;
            dt = obj.timeStep;
            if isa(t0,'datetime')
                if isa(subscripts,'datetime')
                    % OK
                elseif isText(subscripts)
                    % Let text2timetype decide if the timestamps are duration or
                    % datetime. duration takes precedence, but use the existing
                    % datetime row times to suggest a format if duration fails.
                    subscripts = text2timetype(subscripts,'MATLAB:datetime:AutoConvertString',t0);
                    if isa(subscripts,'duration')
                        error(message('MATLAB:timetable:InvalidRowSubscriptsDatetime'));
                    end
                else
                    error(message('MATLAB:timetable:InvalidRowSubscriptsDatetime'));
                end
            else % isa(t0,'duration')
                if isa(subscripts,'duration') 
                    % OK
                elseif isText(subscripts)
                    % Let text2timetype decide if the timestamps are duration or
                    % datetime. duration takes precedence; use the existing
                    % duration row times to suggest a format.
                    subscripts = text2timetype(subscripts,'MATLAB:duration:AutoConvertString',t0);
                    if isa(subscripts,'datetime')
                        error(message('MATLAB:timetable:InvalidRowSubscriptsDuration'));
                    end
                else
                    error(message('MATLAB:timetable:InvalidRowSubscriptsDuration'));
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
    methods(Hidden, Access = {?timetable,...
                              ?matlab.internal.tabular.private.rowTimesDim})
        function tf = isSpecifiedAsRate(obj)
            % Utility function for codegen. Used to determine if the rowDim is
            % created using sample rate or time step.
            tf = obj.specifiedAsRate;
        end
    end
end

            
%===========================================================================
function [tf,dtSpecifiedUnit] = isPureNonZeroCalendarDurationForUnit(dt,unit)
% Determine if a calendar duration time step is non-zero, finite, and "pure"
% with respect to a given calendar unit, i.e., can be expressed entirely in
% terms of that unit and nothing larger or smaller. E.g., 3q is pure with
% respect to quarters and months but not with respect to years or days.
%
% Zero or non-finite calendar durations are not considered pure because (1) it's
% not useful for callers, and (2) all three components are identical (0, Inf or
% NaN) in those cases.
%
% Also return the time step in the specified unit.

import matlab.internal.datatypes.getChoice

icalunit = getChoice(unit,{'years' 'quarters' 'months' 'weeks' 'days' 'time'}, ...
    'MATLAB:datetime:InvalidSingleComponent');

% Split the (scalar) time step into the specified calendar unit and all the
% other primary units.
switch icalunit
case 1 % 'years'
    [dtSplitSpecified,m,d,t] = split(dt,{'year','month','day','time'});
    dtSplitOthers = [m d t];
    template = calyears(1);
case 2 % 'quarters'
    [dtSplitSpecified,m,d,t] = split(dt,{'quarter','month','day','time'});
    dtSplitOthers = [m d t];
    template = calquarters(1);
case 3 % 'months'
    [dtSplitSpecified,d,t] = split(dt,{'month','day','time'});
    dtSplitOthers = [d t];
    template = calmonths(1);
case 4 % 'weeks'
    [m,dtSplitSpecified,d,t] = split(dt,{'month','week','day','time'});
    dtSplitOthers = [m d t];
    template = calweeks(1);
case 5 % 'days'
    [m,dtSplitSpecified,t] = split(dt,{'month','day','time'});
    dtSplitOthers = [m t];
    template = caldays(1);
case 6 % 'time'
    [m,d,dtSplitSpecified] = split(dt,{'month','day','time'});
    dtSplitOthers = [m d];
    template = 1; % times from split come out as a duration already
end

% The (scalar) time step must be non-zero, non-nan/inf in the specified unit,
% and zero in all of the other primary units.
if (dtSplitSpecified == 0) || ~isfinite(dtSplitSpecified) || any(dtSplitOthers ~= 0)
    tf = false;
    dtSpecifiedUnit = NaN.*template;
else
    tf = true;
    dtSpecifiedUnit = dtSplitSpecified.*template;
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
