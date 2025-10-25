classdef (Sealed) explicitRowTimesDim < matlab.internal.coder.tabular.private.rowTimesDim  %#codegen
%ROWTIMESDIM Internal class to represent a timetable's rows dimension.

% This class is for internal use only and will change in a
% future release.  Do not use this class.

    %   Copyright 2019-2022 The MathWorks, Inc.
    
    properties (GetAccess=public, SetAccess=protected)
        labels
        length
    end
    
    properties (Dependent, GetAccess=public, SetAccess=protected)
        startTime    % as datetime or duration
        sampleRate   % in hz
        timeStep     % as duration or calendarDuration
    end
    methods % dependent property get methods
        function startTime = get.startTime(obj)
            if obj.length > 0
                % The start time is defined as the first element of the row
                % times, even if they are not sorted.
                startTime = obj.labels(1);
            else
                % A 0xM timetable has an undefined (NaT or NaN) start time.
                %startTime = matlab.internal.datatypes.defaultarrayLike([1 1],[],obj.labels);
                if isa(obj.labels, 'duration')
                    startTime = matlab.internal.coder.duration(0,0,NaN,...
                        'Format',obj.labels.Format);
                else  % datetime 
                    % Create a NaT datetime while preserving the Format and TimeZone
                    [~,fmt,tz] = datetime.toMillis(obj.labels([]));
                    startTime = datetime.fromMillis(NaN,fmt,tz);
                end
            end
        end
        %-----------------------------------------------------------------------
        function timeStep = get.timeStep(obj)
            % Determine if the time vector is regular with respect to some time
            % unit. Return that time step, or NaN if it's not regular.
            [~,timeStep] = matlab.internal.coder.tabular.private.rowTimesDim.isRegularRowTimes(obj.labels);
        end
        %-----------------------------------------------------------------------
        function sampleRate = get.sampleRate(obj)
            % Determine if the time vector is regular with respect to some time
            % unit. Convert that time step to Hz if it's a duration, or NaN if
            % it's a calendarDuration, or not regular.
            [~,tymeStep] = matlab.internal.coder.tabular.private.rowTimesDim.isRegularRowTimes(obj.labels);
            sampleRate = timeStep2SampleRate(tymeStep); % avoid CA warning
        end
    end
    methods (Access=public)
        % These are effectively set.XXX methods, but setTimeStep and setSampleRate
        % might need to return an implicitRegularRowTimesDim.
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
            
            % Setting the start time doesn't check if the resulting time vector
            % can be stored implicitly the way that setting the time step or
            % sample rate does. It's potentially an expensive check, and one
            % that also isn't done by the constructor when given an explicit row
            % times vector.
            if obj.length > 0
                % The start time is defined as the first element of the row
                % times, even if they are not sorted. Add the (duration) offsets
                % from the original start time to the specified (datetime or
                % duration) start time. Adding the difference in start times to
                % the existing times won't work in cases where the start time is
                % being changed from datetime to duration or vice versa.
                obj.labels = startTime + (obj.labels - obj.labels(1));
                % If the old start time is non-finite, NaN-NaN or Inf-Inf will
                % put NaN in the first element. Overwrite it.
                obj.labels(1) = startTime;
            end
        end
        %-----------------------------------------------------------------------
        function obj = setTimeStep(obj,timeStep)
            coder.internal.assert(isscalar(timeStep), 'MATLAB:timetable:InvalidTimeStep');            
            if isa(timeStep,'duration')
                % OK
            elseif isa(timeStep,'calendarDuration')
                coder.internal.assert(isa(obj.labels,'datetime'), ...
                    'MATLAB:timetable:DurationStartTimeWithCalDurTimeStep');                
                % otherwise OK
            else
                isnum = isnumeric(timestep);
                coder.internal.errorIf(isnum, 'MATLAB:timetable:InvalidTimeStepNumeric');
                coder.internal.errorIf(~isnum, 'MATLAB:timetable:InvalidTimeStep');               
            end
            
            % In codegen, it is not possible to convert to storing the row 
            % times implicitly. Leave it in explicit form.
            
            % If assigning a NaN TimeStep to an irregular timetable, leave
            % the row times alone.
            if ~(isnan(timeStep) && isnan(obj.timeStep))
                obj.labels = obj.regularRowTimesFromTimeStep(obj.labels(1),timeStep,numel(obj.labels));
            end
        end
        %-----------------------------------------------------------------------
        function obj = setSampleRate(obj,sampleRateIn)
            coder.internal.assert(isnumeric(sampleRateIn) && isscalar(sampleRateIn) && ...
                isreal(sampleRateIn), 'MATLAB:timetable:InvalidSampleRate');
            
            samplerate = double(sampleRateIn);
            
            % In codegen, it is not possible to convert to storing the row 
            % times implicitly. Leave it in explicit form.
            
            % If assigning a NaN SampleRate to an irregular timetable, leave
            % the row times alone.
            if ~(isnan(samplerate) && isnan(obj.sampleRate))
                obj.labels = obj.regularRowTimesFromSampleRate(obj.labels(1),samplerate,numel(obj.labels));
            end
        end
    end
    
    %===========================================================================
    methods
        function obj = explicitRowTimesDim(length,labels)
            if nargin == 0
                % Do nothing. This syntax is reserved
                % for the situation where the caller will set the rest of the
                % properties manually afterwards.
                return;
            else
                assert(nargin == 2);
                
                % This is the relevant parts of validateAndAssignLabels
                coder.internal.assert(isa(labels,'datetime') || isa(labels,'duration'),...
                    'MATLAB:timetable:InvalidRowTimes');

                % init orients labels as a col vector (and conveniently forces any
                % empty to 0x1), no need to waste time doing it here.
                obj = obj.init(length,labels);
            end
        end
                
        %-----------------------------------------------------------------------
        function len = get.length(obj)
            % avoids using the length property stored value. Using
            % numel(labels) is more likely to return a constant value.
            len = numel(obj.labels);
        end

        %-----------------------------------------------------------------------
        function [tf,dt] = isregular(obj, unit)
            rowTimes = obj.labels;
            
            % Test if datetime or duration row times are regularly-spaced in with
            % respect to time or a calendar unit.
            if nargin == 1
                [tf,dt] = matlab.internal.coder.datetime.isRegularTimeVector(rowTimes,'time');
            else
                [tf,dt] = matlab.internal.coder.datetime.isRegularTimeVector(rowTimes,unit);
            end
        end
        
        %-----------------------------------------------------------------------
        function s = getProperties(obj)           
            ts = obj.timeStep;
            s.SampleRate = timeStep2SampleRate(ts);
        end
        
        %-----------------------------------------------------------------------
        function s = getDurationProperties(obj)
            s.RowTimes = obj.labels;
            s.StartTime = obj.startTime;
            s.TimeStep = obj.timeStep;
        end
    
        %-----------------------------------------------------------------------
        function template = rowTimesTemplate(obj)
            % Return an instance of the row times' class, with same time zone and format.
            template = obj.labels;
        end
        
        %-----------------------------------------------------------------------
        function subs = timerange2subs(obj,left,right,intervalType)
            % Return a logical vector indicating which row times are in the
            % specified interval.
                        
            rowTimes = obj.labels;
                        
            % check for mismatched types
            rowTimesClass = class(rowTimes);
            coder.internal.assert(isa(left, rowTimesClass), ...
                'MATLAB:timerange:MismatchRowTimesType', rowTimesClass, class(left));
            coder.internal.assert(isa(right, rowTimesClass), ...
                'MATLAB:timerange:MismatchRowTimesType', rowTimesClass, class(right));
            
            switch intervalType
                case {'openright' 'closedleft'}
                    subs = left <= rowTimes & rowTimes < right;
                case {'openleft' 'closedright'}
                    subs = left < rowTimes & rowTimes <= right;
                case 'open'
                    subs = left < rowTimes & rowTimes < right;
                case 'closed'
                    subs = left <= rowTimes & rowTimes <= right;
                otherwise    
                    % need to check again because intervalType may not be
                    % compile time constant
                    coder.internal.assert(~any(strcmp(intervalType, {'openright', ...
                        'closedleft', 'openleft', 'closedright', 'open', 'closed'})), ...
                        'MATLAB:timerange:InvalidIntervalType');
                    subs = false(size(rowTimes));  % assign dummy results
            end
        end
        
        %-----------------------------------------------------------------------
        function newobj = createLike(~,dimLength,dimLabels)
            coder.internal.prefer_const(dimLength);
            % create a new object
            newobj = matlab.internal.coder.tabular.private.explicitRowTimesDim;
            if nargin < 3
                newobj = newobj.createLike@matlab.internal.coder.tabular.private.tabularDimension(dimLength);
            else
                newobj = newobj.createLike@matlab.internal.coder.tabular.private.tabularDimension(dimLength,dimLabels);
            end
        end
        
        %-----------------------------------------------------------------------
        function rowtimes = createExtendedRowTimes(obj,len)
            % Utility function used by vertcat. Create a longer RowTimes
            % that is of the same type. For explicit rowtimes, the extended 
            % portion will be NaN or NaT.
            labs = obj.labels;
            if isa(labs, 'duration')
                rowtimes = duration.fromMillis(NaN(len,1),labs.Format);
            else  % datetime
                [~,fmt,tz] = datetime.toMillis(labs([]));
                rowtimes = datetime.fromMillis(NaN(len,1),fmt,tz);
            end
            rowtimes(1:numel(labs)) = labs;
        end
        
        %-----------------------------------------------------------------------
        function newObj = lengthenTo(obj,maxIndex,newLabels)
            % Utility function to lengthen a row times dim.
            
            % If newLables are not provided, create NaN values of the
            % appropriate type. Otherwise, assume that newLabels has already
            % been checked by validateNativeSubscripts. Row times need not be
            % unique, no need to worry about that. 
            if nargin < 3
                len = maxIndex - obj.length; 
                if len > 0
                    if isa(obj.labels,'datetime')
                        [~,fmt,tz] = datetime.toMillis(obj.labels([]));
                        newLabels = datetime.fromMillis(NaN(len,1),fmt,tz);
                    else
                        newLabels = duration.fromMillis(NaN(len,1),obj.labels.Format);
                    end
                else
                    newLabels = obj.labels([]);
                end
            end
            if ~isempty(newLabels)
                newObjLabels = [obj.labels;newLabels];
            else
                newObjLabels = obj.labels(1:maxIndex);
            end
            newObj = obj.createLike(maxIndex,newObjLabels);
        end
    end
    
    %===========================================================================
    methods (Access=protected)
        function tf = areRowTimesEqual(obj1,obj2)
            if isa(obj2,class(obj1))
                % The first object is an explicitRowTimesDim, if the second is too,
                % compare the time vectors.
                tf = isequal(obj1.labels,obj2.labels);
            else
                % The first object is an explicitRowTimesDim, if the second is an
                % implicitRegularRowTimesDim, compare on the expanded time vector.
                tf = obj1.labels(1) == obj2.startTime ... % quick check before expanding
                    && isequaln(obj1.labels,obj2.labels);
            end
        end
        function tf = areRowTimesEqualn(obj1,obj2)
            % See areRowTimesEqual.
            tf = isequaln(obj1.labels,obj2.labels);
        end
        
        %-----------------------------------------------------------------------
        function obj = validateAndAssignLabels(obj,newLabels,rowIndices,fullAssignment,dimLength,~,~,~)
            % Only accept datetime or duration, strings are not auto-converted.
            % Labels are required for a time dimension, so do not allow a full
            % assignment of a 0x0 to clear them out. Allow a full assignment to
            % change between datetime and duration, but not a partial
            % assignment.
            coder.internal.prefer_const(dimLength, fullAssignment);
                
                coder.internal.assert(isa(newLabels,'datetime') || ...
                isa(newLabels,'duration'), 'MATLAB:timetable:InvalidRowTimes');

            newLabelsColumn = newLabels(:); % a col vector, conveniently forces any empty to 0x1
            
            % Missing and duplicate row times are always allowed, no need to check.
            
            % Even for a full assignment, do not do the potentially expensive check
            % to determine if the new time vector is regular or not. The row times
            % dim remains explicit.
            obj = obj.assignLabels(newLabelsColumn,fullAssignment,rowIndices,dimLength);
        end
        
        %-----------------------------------------------------------------------
        function [subscripts,indices] = validateNativeSubscripts(~,subscripts,rowTimes)
            %rowTimes = obj.labels;
            if isa(rowTimes,'datetime')
                if ~isa(subscripts,'datetime')                    
                    coder.internal.assert(matlab.internal.coder.datatypes.isText(subscripts),...
                        'MATLAB:timetable:InvalidRowSubscriptsDatetime');
                    subscripts = matlab.internal.coder.datetime.text2timetype(...
                        subscripts,'MATLAB:datetime:AutoConvertString',rowTimes);
                    coder.internal.errorIf(isa(subscripts,'duration'), ...
                        'MATLAB:timetable:InvalidRowSubscriptsDatetime');
                end
            else % isa(rawRowTimes,'duration')
                if ~isa(subscripts,'duration') 
                    coder.internal.assert(matlab.internal.coder.datatypes.isText(subscripts), ...
                        'MATLAB:timetable:InvalidRowSubscriptsDuration');
                    subscripts = matlab.internal.coder.datetime.text2timetype(...
                        subscripts,'MATLAB:duration:AutoConvertString',rowTimes);
                    coder.internal.errorIf(isa(subscripts,'datetime'), ...
                        'MATLAB:timetable:InvalidRowSubscriptsDuration');
                end
            end
            locs = timesubs2inds(subscripts,rowTimes); % dispatch to datetime or duration
            % Each row of locs says which subscript (1st col) matched which row of the
            % timetable (2nd col), with zero in 2nd col indicating no match for that subscript.
            % Leave unmatched subscripts in the output so the caller can create new rows with
            % those rowtimes. But locs might be taller than subscripts because a subscript
            % might match more than one row, so broadcast subscripts to match loc's height,
            % thus keeping unmatched subscripts in sync with zero indices in the outputs.
            % ***codegen doesn't allow growing by assignment, but dealing with those zero
            % indices in assignment is left to the caller (parenAssign, ultimately).***
            subscripts = subscripts(locs(:,1)); % time subscripts
            indices = locs(:,2); % timetable indices, 0 indicate no match

            % reshape should not be necessary. But without it, coder can get
            % confused about the size of indices
            indices = reshape(indices,1,[]);
        end
    end
    
    %===========================================================================
    methods(Hidden, Access = {?matlab.internal.coder.tabular,...
                              ?matlab.internal.coder.tabular.private.rowTimesDim})
        function tf = isSpecifiedAsRate(~)
            % Utility function for codegen. Used to determine if the rowDim is
            % created using sample rate or time step. Always false for
            % explicitRowTimesDim.
            tf = false;
        end
    end
end



%===========================================================================
function fs = timeStep2SampleRate(dt)
if isa(dt,'duration') && isfinite(dt)
    % Convert time step into Hz.
    fs = 1/seconds(dt);
else
    % Sample rate is undefined for a time vector that is not regular
    % w.r.t. time, even if it's regular w.r.t. calendar days or months.
    fs = NaN;
end
end