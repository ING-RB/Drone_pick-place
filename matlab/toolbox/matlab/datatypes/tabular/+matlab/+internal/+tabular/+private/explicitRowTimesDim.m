classdef (Sealed) explicitRowTimesDim < matlab.internal.tabular.private.rowTimesDim
%ROWTIMESDIM Internal class to represent a timetable's rows dimension.

% This class is for internal use only and will change in a
% future release.  Do not use this class.

    %   Copyright 2016-2022 The MathWorks, Inc.
    
    properties (GetAccess=public, SetAccess=protected)
        labels
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
                startTime = matlab.internal.datatypes.defaultarrayLike([1 1],[],obj.labels);
            end
        end
        %-----------------------------------------------------------------------
        function timeStep = get.timeStep(obj)
            % Determine if the time vector is regular with respect to some time
            % unit. Return that time step, or NaN if it's not regular.
            [~,timeStep] = matlab.internal.tabular.private.rowTimesDim.isRegularRowTimes(obj.labels);
        end
        %-----------------------------------------------------------------------
        function sampleRate = get.sampleRate(obj)
            % Determine if the time vector is regular with respect to some time
            % unit. Convert that time step to Hz if it's a duration, or NaN if
            % it's a calendarDuration, or not regular.
            [~,tymeStep] = matlab.internal.tabular.private.rowTimesDim.isRegularRowTimes(obj.labels);
            sampleRate = timeStep2SampleRate(tymeStep); % avoid CA warning
        end
    end
    methods (Access=public)
        
        function obj = createLike(obj,varargin)
            obj = obj.createLike@matlab.internal.tabular.private.tabularDimension(varargin{:});
            % Clear out timeEvents.
            obj.timeEvents = [];
        end

        % These are effectively set.XXX methods, but setTimeStep and setSampleRate
        % might need to return an implicitRegularRowTimesDim.
        %
        % These methods assume that the object is in a valid state, and one
        % property at a time is being assigned. Cases where multiple properties
        % are being assigned go through validateTimeVectorParams and the
        % constructor.
        %-----------------------------------------------------------------------
        function obj = setStartTime(obj,startTime)
            import matlab.internal.tabular.private.implicitRegularRowTimesDim
            
            if isnumeric(startTime)
                error(message('MATLAB:timetable:InvalidStartTimeNumeric'));
            elseif ~isscalar(startTime) || ~(isa(startTime,'datetime') || isa(startTime,'duration'))
                error(message('MATLAB:timetable:InvalidStartTime'));
            end
            
            % Setting the start time doesn't check if the resulting time vector
            % can be stored implicitly the way that setting the time step or
            % sample rate does. It's potentially an expensive check, and one
            % that also isn't done by the constructor when given an explicit row
            % times vector.
            %
            % However, convert to implicitly-stored row times if the timetable has
            % no rows. If they were "stored" explicitly, there'd be nowhere to put
            % the new start time that's being set.
            if obj.length == 0
                obj = implicitRegularRowTimesDim(0,startTime,obj.timeStep,[],obj.timeEvents);
            else
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
            import matlab.internal.tabular.private.implicitRegularRowTimesDim
            
            if ~isscalar(timeStep)
                error(message('MATLAB:timetable:InvalidTimeStep'));
            elseif isa(timeStep,'duration')
                % OK
            elseif isa(timeStep,'calendarDuration')
                if ~isa(obj.labels,'datetime')
                    error(message('MATLAB:timetable:DurationStartTimeWithCalDurTimeStep'));
                end
                % otherwise OK
            elseif isnumeric(timeStep)
                error(message('MATLAB:timetable:InvalidTimeStepNumeric'));
            else
                error(message('MATLAB:timetable:InvalidTimeStep'));
            end
            
            % If possible, convert to storing the row times implicitly, unless
            % the time step is unreasonably large or small, or (maybe) NaN.
            [makeImplicit,explicitRowTimes] = implicitRegularRowTimesDim.implicitOrExplicit(obj.length,obj.startTime,timeStep,[]);
            if makeImplicit
                obj = implicitRegularRowTimesDim(obj.length,obj.startTime,timeStep,[],obj.timeEvents);
            elseif isnan(timeStep) && isnan(obj.timeStep)
                % If assigning a NaN TimeStep to an irregular timetable, leave
                % the row times alone.
            else
                obj.labels = explicitRowTimes;
            end
        end
        %-----------------------------------------------------------------------
        function obj = setSampleRate(obj,sampleRate)
            import matlab.internal.tabular.private.implicitRegularRowTimesDim
            
            if ~(isnumeric(sampleRate) && isscalar(sampleRate) && isreal(sampleRate))
                % SampleRate must be a scalar number, but may be negative, zero, or non-finite
                error(message('MATLAB:timetable:InvalidSampleRate'));
            end
            sampleRate = double(sampleRate);
            
            % If possible, convert to storing the row times implicitly, unless
            % the sample rate is unreasonably large or small, or (maybe) NaN.
            [makeImplicit,explicitRowTimes] = implicitRegularRowTimesDim.implicitOrExplicit(obj.length,obj.startTime,[],sampleRate);
            if makeImplicit
                obj = implicitRegularRowTimesDim(obj.length,obj.startTime,[],sampleRate,obj.timeEvents);
            elseif isnan(sampleRate) && isnan(obj.sampleRate)
                % If assigning a NaN SampleRate to an irregular timetable, leave
                % the row times alone. SampleRate could also be NaN because
                % TimeStep is a finite calendarDuration, leave them alone then too.
            else
                obj.labels = explicitRowTimes;
            end
        end
    end
    
    %===========================================================================
    methods
        function obj = explicitRowTimesDim(length,labels,timeEvents)
            
            % This is the relevant parts of validateAndAssignLabels
            if ~(isa(labels,'datetime') || isa(labels,'duration'))
                error(message('MATLAB:timetable:InvalidRowTimes'));
            end
            % init orients labels as a col vector (and conveniently forces any
            % empty to 0x1), no need to waste time doing it here.
            obj = obj.init(length,labels);

            if nargin == 3
                obj.timeEvents = timeEvents;
            end
        end
                
        %-----------------------------------------------------------------------
        function tf = hasExplicitLabels(~)
            % HASEXPLICITLABELS Determine if the rowDim obj has explicitly stored
            % labels.
            tf = true;
        end
                
        %-----------------------------------------------------------------------
        function [tf,dt] = isregular(obj, unit)
            rowTimes = obj.labels;
            
            % Test if datetime or duration row times are regularly-spaced in with
            % respect to time or a calendar unit.
            if nargin == 1
                [tf,dt] = matlab.internal.datetime.isRegularTimeVector(rowTimes,'time');
            else
                [tf,dt] = matlab.internal.datetime.isRegularTimeVector(rowTimes,unit);
            end
        end
        
        %-----------------------------------------------------------------------
        function rowTimes = serializeRowTimes(obj)
            % Save the row times vector explicitly.
            rowTimes = obj.labels;
        end
        
        %-----------------------------------------------------------------------
        function s = getProperties(obj)
            % Same order as rowNamesDim.propertyNames
            s.RowTimes = obj.labels;
            s.StartTime = obj.startTime;
            s.TimeStep = obj.timeStep;
            % Leverage the work done in getting the time step to get the sample rate.
            s.SampleRate = timeStep2SampleRate(s.TimeStep);
            s.Events = obj.timeEvents;
        end
                        
        %-----------------------------------------------------------------------
        function obj = lengthenTo(obj,maxIndex,newLabels)
            newIndices = (obj.length+1):maxIndex;
            if nargin < 3
                if isa(obj.labels,'datetime')
                    obj.labels(newIndices,1) = NaT;
                else
                    obj.labels(newIndices,1) = NaN;
                end
            else
                % Assume that newLabels has already been checked by validateNativeSubscripts.
                % Row times need not be unique, no need to worry about that.
                obj.labels(newIndices,1) = newLabels(:);
            end
            obj.length = maxIndex;
        end
    
        %-----------------------------------------------------------------------
        function template = rowTimesTemplate(obj)
            % Return an instance of the row times' class, with same time zone and format.
            template = obj.labels;
        end
        
        %-----------------------------------------------------------------------
        function subs = timerange2subs(obj,left,right,intervalType)
            % Return a logical vector indicating which row times are in the
            % specified interval. An interval with zero length and either
            % endpoint open does not select any row times. 
            rowTimes = obj.labels;
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
                error(message('MATLAB:timerange:InvalidIntervalType'));
            end
        end
                
        %-----------------------------------------------------------------------
        function [min,max] = getBounds(obj)
            % Min/max of the rowtimes.
            if obj.length == 0
                if isa(obj.labels,'datetime')
                    min = NaT;
                else % duration
                    min = duration.fromMillis(NaN);
                end
                max = min;
            else
                [min, max] = bounds(obj.labels);
            end
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
        function obj = validateAndAssignLabels(obj,newLabels,rowIndices,fullAssignment,~,~,~)
            % Only accept datetime or duration, strings are not auto-converted.
            % Labels are required for a time dimension, so do not allow a full
            % assignment of a 0x0 to clear them out. Allow a full assignment to
            % change between datetime and duration, but not a partial assignment.
            if isa(newLabels,'datetime') || isa(newLabels,'duration')
                if fullAssignment
                    % OK to replace datetime with duration or vice versa.
                elseif ~isa(newLabels,class(obj.labels))
                    error(message('MATLAB:timetable:MixedRowTimesAssignment',class(obj.labels)));
                end
            else
                error(message('MATLAB:timetable:InvalidRowTimes'));
            end
            
            % The number of new labels has to match what's being assigned to.
            if fullAssignment 
                if numel(newLabels) ~= obj.length
                    obj.throwIncorrectNumberOfLabels();
                end
            else
                if numel(newLabels) ~= numel(rowIndices)
                    obj.throwIncorrectNumberOfLabelsPartial();
                end
            end
            
            newLabels = newLabels(:); % a col vector, conveniently forces any empty to 0x1
            
            % Missing and duplicate row times are always allowed, no need to check.
            
            % Even for a full assignment, do not do the potentially expensive check
            % to determine if the new time vector is regular or not. The row times
            % dim remains explicit.
            obj = obj.assignLabels(newLabels,fullAssignment,rowIndices);
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
            rowTimes = obj.labels;
            if isa(rowTimes,'datetime')
                if isa(subscripts,'datetime')
                    % OK
                elseif isText(subscripts)
                    % Let text2timetype decide if the timestamps are duration or
                    % datetime. duration takes precedence, but use the existing
                    % datetime row times to suggest a format if duration fails.
                    subscripts = text2timetype(subscripts,'MATLAB:datetime:AutoConvertString',rowTimes);
                    if isa(subscripts,'duration')
                        error(message('MATLAB:timetable:InvalidRowSubscriptsDatetime'));
                    end
                else
                    error(message('MATLAB:timetable:InvalidRowSubscriptsDatetime'));
                end
            else % isa(existingLabels,'duration')
                if isa(subscripts,'duration') 
                    % OK
                elseif isText(subscripts)
                    % Let text2timetype decide if the timestamps are duration or
                    % datetime. duration takes precedence; use the existing
                    % duration row times to suggest a format.
                    subscripts = text2timetype(subscripts,'MATLAB:duration:AutoConvertString',rowTimes);
                    if isa(subscripts,'datetime')
                        error(message('MATLAB:timetable:InvalidRowSubscriptsDuration'));
                    end
                else
                    error(message('MATLAB:timetable:InvalidRowSubscriptsDuration'));
                end
            end
            locs = timesubs2inds(subscripts,rowTimes); % dispatch to datetime or duration
            % Each row of locs says which subscript (1st col) matched which row of the
            % timetable (2nd col), with zero in 2nd col indicating no match for that subscript.
            % Leave unmatched subscripts in the output so the caller can create new rows with
            % those rowtimes. But locs might be taller than subscripts because a subscript
            % might match more than one row, so broadcast subscripts to match loc's height,
            % thus keeping unmatched subscripts in sync with zero indices in the outputs.
            subscripts = subscripts(locs(:,1)); % time subscripts
            indices = locs(:,2); % timetable indices, 0 indicate no match
        end
    end
    
    %===========================================================================
    methods(Hidden, Access = {?timetable,...
                              ?matlab.internal.tabular.private.rowTimesDim})
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