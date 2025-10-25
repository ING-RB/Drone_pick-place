classdef (AllowedSubclasses = {?matlab.internal.tabular.private.explicitRowTimesDim, ...
                               ?matlab.internal.tabular.private.implicitRegularRowTimesDim}) ...
                               rowTimesDim < matlab.internal.tabular.private.tabularDimension
%ROWTIMESDIM Internal abstract class to represent a timetable's row dimension.

% This class is for internal use only and will change in a
% future release.  Do not use this class.

    %   Copyright 2016-2023 The MathWorks, Inc.
    
    properties (Constant, GetAccess=public)
        labelType = "time";
        requireLabels = true;
        requireUniqueLabels = false;
        DuplicateLabelExceptionID = ''; % No exception: requireUniqueLabels is FALSE
    end
    properties (Abstract, GetAccess=public, SetAccess=protected)
        startTime    % as datetime or duration
        sampleRate   % in hz
        timeStep     % as duration or calendarDuration
    end
    properties (GetAccess=public, SetAccess=protected)
        timeEvents   % eventtable
    end
    properties (Dependent)
        hasEvents;
    end

    methods (Abstract)
        % These are effectively set.XXX methods, but implicitRegularRowTimesDim
        % needs setTimeStep and setSampleRate to set each others' properties,
        % and explicitRowTimesDim needs them to return a different class.
        obj = setStartTime(obj,startTime)
        obj = setTimeStep(obj,timeStep)
        obj = setSampleRate(obj,sampleRate)
    end
    
    methods(Abstract, Access = {?timetable,...
                                ?matlab.internal.tabular.private.rowTimesDim})
        tf = isSpecifiedAsRate(obj);
    end
    
    %===========================================================================
    methods (Access=public)
        function obj = init(obj,dimLength,dimLabels,timeEvents)
            if nargin == 2
                obj = init@matlab.internal.tabular.private.tabularDimension(obj,dimLength);
                return
            end
            obj = init@matlab.internal.tabular.private.tabularDimension(obj,dimLength,dimLabels);
            if nargin == 4
                obj.timeEvents = timeEvents;
            else
                obj.timeEvents = [];
            end
        end
        function tf = isequal(obj1,obj2,varargin)
            % The row times and events are the only properties that really
            % matters for comparison, but the inputs might be different
            % rowTimesDim subclasses with different representations for the row
            % times. Let the subclasses decide how to compare the row times.
            try
                % Compare the first two inputs' row times and events.
                tf = obj1.areRowTimesEqual(obj2) && isequal(obj1.timeEvents,obj2.timeEvents);
                for i = 2:length(varargin)
                    % Compare the first input's row times and events to those of
                    % each remaining input.
                    tf = tf && obj1.areRowTimesEqual(varargin{i}) ...
                        && isequal(obj1.timeEvents,varargin{i}.timeEvents);
                end
            catch
                tf = false;
            end
        end
        function tf = isequaln(obj1,obj2,varargin)
            % See isequal.
            try
                tf = obj1.areRowTimesEqualn(obj2) && isequaln(obj1.timeEvents,obj2.timeEvents);
                for i = 2:length(varargin)
                    tf = tf && obj1.areRowTimesEqualn(varargin{i}) ...
                        && isequaln(obj1.timeEvents,varargin{i}.timeEvents);
                end
            catch
                tf = false;
            end
        end
                                
        %-----------------------------------------------------------------------
        function labels = emptyLabels(obj,num)
            % EMPTYLABELS Return a vector of empty labels of the right kind.
            template = obj.rowTimesTemplate();
            if isa(template,'datetime')
                % Give fromMillis the template, so we don't need to care if it has
                % a default format or not.
                labels = datetime.fromMillis(NaN(num,1),template);
            else
                labels = duration.fromMillis(NaN(num,1),template);
            end
        end

        %-----------------------------------------------------------------------
        function target = mergeProps(target,source,fromLocs) %#ok<INUSD>
            % MERGEPROPS Merge properties of the rowDims.

            % Only rowDim's with "time" labelType have timeEvents. target always
            % has "time" labelType, so check if source's labelType is also
            % "time" and update target's timeEvents if necessary.
            if matches(source.labelType,"time") && source.hasEvents
                if target.hasEvents
                    % If both have events, then merge and update.
                    target = target.setTimeEvents(mergeevents(target.timeEvents,source.timeEvents));
                else
                    % If only source has events, then use that for target.
                    target = target.setTimeEvents(source.timeEvents);
                end
            end
        end

        %-----------------------------------------------------------------------
        function obj = setTimeEvents(obj,events)
            if isequal(events,[])
                obj.timeEvents = [];
                return
            end

            if (isa(events,'timetable') && ~isa(events,'eventtable')) || isa(events,'datetime') || isa(events,'duration')
                 % Convert to timetable, datetime, and durations to
                 % eventtable.
                events = eventtable(events);
            end
            
            if isa(events,'eventtable')
                % The eventtable must have the same time type as the
                % timetable.
                if ~isequal(class(events.Properties.RowTimes),class(obj.labels))
                    error(message("MATLAB:timetable:InvalidEventsIncompatibleType"))
                end
                
                % Either both the eventtable and the timetable are zoned
                % are both unzoned.
                if isdatetime(obj.labels) && (isempty(events.Properties.StartTime.TimeZone) ~= isempty(obj.labels.TimeZone))
                    error(message("MATLAB:timetable:InvalidEventsTimeZone"))
                end
 
                obj.timeEvents = events;
            else
                error(message('MATLAB:timetable:InvalidEvents'));
            end
        end

        %-----------------------------------------------------------------------
        function labels = textLabels(obj,indices)
            % TEXTLABELS Return the labels converted to text.
          
            if nargin < 2
                labels = cellstr(obj.labels);

            else
                labels = cellstr(obj.labels(indices));
            end

        end

        %-----------------------------------------------------------------------
        function labels = textEvents(obj)
            % TEXTEVENTS Return the event label annotation text for each timetable row.
            import matlab.internal.display.truncateLine
            
            % Get the eventtable attached to this rowDim.
            eventsTbl = obj.timeEvents;
            if ~obj.hasEvents || obj.length == 0
                labels = "";
                return;
            end

            % Get the event labels for all of the attached events. If there are no labels,
            % use a default.
            defaultLabel = string(getString(message("MATLAB:timetable:UIStringDispOneEvent"))); % <1 event>
            if ~isnumeric(eventsTbl.Properties.EventLabelsVariable)
                eventLabels = eventsTbl.(eventsTbl.Properties.EventLabelsVariable);
            else
                eventLabels = repmat(defaultLabel,obj.length,1);
            end

            % Find the timetable rows that match the attached events.
            try
                [eventTimes,eventEndTimes] = eventIntervalTimes(eventsTbl);
                eventRowSubsCell = obj.eventtimes2timetablesubs(eventTimes,eventEndTimes);
            catch ME
                % If the event times and timetable row times are different types, return empty text.
                if matches(ME.identifier,"MATLAB:eventfilter:EventTimeTypeFilterError")
                    labels = "";
                    return;
                end
                rethrow(ME);
            end

            % Get a text representation of each event label and save it for each timetable
            % row that the event matches.
            eventCounts = zeros(obj.length,1);
            labels = strings(obj.length,1);

            % Check if MATLAB desktop is available and pass that to
            % truncateLine so it does not need to perform that check every
            % iteration of the for loop
            doesMATLABUseDesktop = matlab.internal.display.isDesktopInUse;
            for i = 1:numel(eventRowSubsCell)
                % eventRowIndicesCell maps events to timetable rows. For instantaneous
                % events, usually each cell contains the one timetable row that matches the
                % i-th event, but there may be zero or multiple rows that match. Interval events
                % usually match multiple rows. Broadcast a string representation of the i-th
                % event's label to all matching rows. Replace missing strings with a default.
                try
                    eventLabel = string(eventLabels(i));
                    if ismissing(eventLabel) || eventLabel == ""
                        eventLabel = defaultLabel;
                    else
                        % Three input form of truncateLine requires -1 as
                        % second input to get default behavior, i.e. assume
                        % default width.
                        eventLabel = truncateLine(eventLabel, -1, doesMATLABUseDesktop);
                    end
                catch
                    % The event labels var might be empty, or something else could cause the
                    % string conversion to fail.
                    eventLabel = defaultLabel;
                end
                labels(eventRowSubsCell{i}) = eventLabel;
                % Increment the number of events that match each of those timetable rows.
                eventCounts = eventCounts + eventRowSubsCell{i};
            end
            % Use a generic text representation where multiple events match the same
            % timetable row.
            for i = 1:obj.length
                if eventCounts(i) > 1
                    labels(i) = getString(message("MATLAB:timetable:UIStringDispNEvents",eventCounts(i))); % <N events>
                end
            end
        end

        %-----------------------------------------------------------------------
        function rowSubsCell = eventtimes2timetablesubs(obj,eventTimes,eventEndTimes,tol)
            % Find rows in a timetable that match specified event times, including both
            % instantaneous and interval events. Return a cell array of logical
            % subscript vectors.
            if nargin < 4
                tol = seconds(0);
            end

            if ~isa(eventTimes,class(obj.labels))
                throwAsCaller(MException(message("MATLAB:eventfilter:EventTimeTypeFilterError",class(obj.labels),class(eventTimes))));
            elseif isa(eventTimes,'datetime') && (isempty(eventTimes.TimeZone) ~= isempty(obj.labels.TimeZone))
                throwAsCaller(MException(message("MATLAB:timetable:InvalidEventsTimeZone")));
            end
              
            % For each event, find the matching timetable row or rows. Instantaneous
            % events can match multiple rows if there are repeated timetable row times.
            % Interval events usually match multiple rows. Store the matching timetable
            % row indices for each event in a cell array so the event-to-timetable
            % correspondence is preserved.
            numEvents = numel(eventTimes);
            rowSubsCell = cell(numEvents,1);
            for i = 1:numEvents
                if isnumeric(eventEndTimes)  % [], i.e. instantaneous events
                    % For instantaneous events, use ordinary time subscripting.
                    rowSubsCell{i} = false(obj.length,1);
                    rowSubsCell{i}(obj.subs2inds(eventTimes(i))) = true; % indices -> logical
                    
                else
                    % For interval events, use the guts of timerange subscripting.
                    % Events are openright, and an event with zero length is effectively
                    % ignored unless there is a positive tolerance.
                    ri = obj.timerange2subs(eventTimes(i)-tol,eventEndTimes(i)+tol,'openright');
                    
                    % timerange2subs returns a logical for explicitRowTimesDim, and a
                    % ColonDescriptor for implictRowTimesDim. Force ri into a logical
                    % column vector (including for ColonDescriptor).
                    if islogical(ri)
                        rowSubsCell{i} = ri(:);
                    else
                        rowSubsCell{i} = false(obj.length,1);
                        rowSubsCell{i}(ri(:)) = true;
                    end
                end
            end
        end
        
        %-----------------------------------------------------------------------
        function labels = defaultLabels(obj,indices)
            % DEFAULTLABELS Return a vector of default labels of the right kind.
            template = obj.rowTimesTemplate();
            if nargin < 2
                len = obj.length;
            else
                len = length(indices);
            end
            if isa(template,'datetime')
                % Give fromMillis the template, so we don't need to care if it has
                % a default format or not.
                labels = datetime.fromMillis(NaN(len,1),template);
            else
                labels = duration.fromMillis(NaN(len,1),template);
            end
        end
        
        %-----------------------------------------------------------------------
        function [indices,numIndices,maxIndex,isLiteralColon,isLabels,updatedObj] ...
                     = subs2inds(obj,subscripts,subsType)
            %SUBS2INDS Convert table subscripts (labels, logical, numeric) to indices.
            if nargin < 3, subsType = obj.subsType_reference; end
            try
                % Let the superclass handle the real work.
                [indices,numIndices,maxIndex,isLiteralColon,isLabels,updatedObj] = ...
                    obj.subs2inds@matlab.internal.tabular.private.tabularDimension(subscripts,subsType);
            catch ME
                if (ME.identifier == "MATLAB:badsubscript") ...
                        && isnumeric(subscripts) && isa(obj.startTime,'duration')
                    throwAsCaller(MException(message('MATLAB:timetable:InvalidRowIndicesDuration')));
                else
                    throwAsCaller(ME)
                end
            end
        end
        
        %-----------------------------------------------------------------------
        function obj = unserializeRowTimes(existingExplicitObject,numRows,rowTimes,timeEvents)
            % This is a factory function to create an instance of one or the other
            % rowTimesDim subclass. Although a factory, it is an instance method
            % because it takes an (empty) explicitRowTimesDim instance for reuse if
            % possible. It does not check the class of the first imput (performance)
            % but will error if called on an implicitRegularRowTimesDim.
            import matlab.internal.tabular.private.implicitRegularRowTimesDim
            import matlab.internal.tabular.private.explicitRowTimesDim
            if isstruct(rowTimes)
                % Create an implicitRegularRowTimesDim from a struct created in saveobj
                % by the implicitRegularRowTimesDim serializeRowTimes method. The struct
                % contains params that define the regular row times as origin+stepSize
                % or origin+sampleRate.
                params = rowTimes;
                if params.specifiedAsRate
                    obj = implicitRegularRowTimesDim(numRows,params.origin,[],params.sampleRate,timeEvents);
                else
                    obj = implicitRegularRowTimesDim(numRows,params.origin,params.stepSize,[],timeEvents);
                end
            else
                % Reuse the existing explicitRowTimesDim, updated with the row times vector
                % saved in saveobj by the explicitRowTimesDim serializeRowTimes method.
                obj = existingExplicitObject.init(numRows,rowTimes,timeEvents); % an implicitRowTimesDim will assert
            end
        end
    
        function propNames = propertyNames(~)
            propNames = {'RowTimes'; 'StartTime'; 'SampleRate'; 'TimeStep'; 'Events'};
        end
    end

    methods
        function tf = get.hasEvents(obj)
            tf = ~isnumeric(obj.timeEvents);
        end
    end

    methods (Access=protected)
        function obj = makeUniqueForRepeatedIndices(obj,indices) %#ok<INUSD>
            % Row times do not need to be unique
        end
        
        %-----------------------------------------------------------------------
        function throwRequiresLabels(~)
            throwAsCaller(MException(message('MATLAB:timetable:CannotRemoveRowTimes')));
        end
        function throwIncorrectNumberOfLabels(~)
            throwAsCaller(MException(message('MATLAB:timetable:IncorrectNumberOfRowTimes')));
        end
        function throwIncorrectNumberOfLabelsPartial(~)
            throwAsCaller(MException(message('MATLAB:timetable:IncorrectNumberOfRowTimesPartial')));
        end
        function throwIndexOutOfRange(~)
            throwAsCaller(MException(message('MATLAB:table:RowIndexOutOfRange')));
        end
        function throwUnrecognizedLabel(~,~)
            assert(false); % rowTimesDim returns an empty result instead
        end
        function throwInvalidLabel(~)
            assert(false); % rowTimesDim throws InvalidRowSubscriptsDatetime/Duration instead
        end
        function throwInvalidSubscripts(~)
            assert(false); % rowTimesDim throws InvalidRowSubscriptsDatetime/Duration instead
        end

    end
    
    %===========================================================================
    methods (Abstract)
        [tf,dt] = isregular(obj,unit)
        rowTimes = serializeRowTimes(obj)
        template = rowTimesTemplate(obj)
        rowSubscript = timerange2subs(leftEndPoint,rightEndPoint,intervalType)
        [min,max] = getBounds(obj)
    end
    
    %===========================================================================
    methods (Abstract, Access=protected)
        tf = areRowTimesEqual(obj1,obj2)
        tf = areRowTimesEqualn(obj1,obj2)
    end
    
    %===========================================================================
    methods (Static)
        function rowtimes = regularRowTimesFromTimeStep(startTime,timeStep,len,indices)
            % This is correct for both duration and calendarDuration time step,
            % as long as the calendarDuration is "pure", i.e. only one unit.
            if nargin < 4
                steps = (0:len-1)';
            else
                steps = indices - 1; % 1-based -> 0-based
            end
            rowtimes = startTime + steps(:)*timeStep;
            
            % Overwrite the NaN that 0*NaN or 0*Inf for a non-finite time step
            % would put at step == 0.
            if ~isempty(rowtimes)
                if nargin < 4
                    rowtimes(1) = startTime;
                else
                    rowtimes(steps==0) = startTime;
                end
            end
        end
        function rowtimes = regularRowTimesFromCalDurTimeStep(startTime,timeStep,stopTime)
            % colon gets the (possibly ambiguous) arithmetic right even for
            % "non-pure" calendarDurations, without needing the length. It is
            % exact for calendarDuration steps, no round-off.
            rowtimes = (startTime:timeStep:stopTime)';
        end
        function rowtimes = regularRowTimesFromSampleRate(startTime,sampleRate,len,indices)
            if nargin < 4
                steps = (0:len-1)';
            else
                steps = indices - 1; % 1-based -> 0-based
            end
            rowtimes = startTime + milliseconds(steps(:))*1000/sampleRate;
            
            % Overwrite the NaN that 0/NaN or 0/0 for a NaN or zero sample rate
            % would put at step == 0.
            if ~isempty(rowtimes)
                if nargin < 4
                    rowtimes(1) = startTime;
                else
                    rowtimes(steps==0) = startTime;
                end
            end
        end
    end
    
    %===========================================================================
    methods (Static, Access=protected)
        function [tf,dt] = isRegularRowTimes(rowTimes)
            % Determine if the specified time vector is regular with respect to
            % some time unit.
            if isa(rowTimes,'duration')
                % durations can only be regular w.r.t. time.
                [tf,dt] = matlab.internal.datetime.isRegularTimeVector(rowTimes,'time');
            elseif length(rowTimes) < 2
                % Let isRegularTimeVector decide the right answer for empty/scalar.
                [tf,dt] = matlab.internal.datetime.isRegularTimeVector(rowTimes,'time');
            else
                % Use t(2)-t(1) as a rough check of the possibilities.
                dt0 = abs(days(diff(rowTimes(1:2))));
                if dt0 < 1
                    % If the first difference is less than 1 (standard) day, the times
                    % are either regular w.r.t. time or not regular, but they can't be
                    % regular w.r.t. (calendar) days or months.
                    units = {'time'};
                elseif dt0 < 28
                    % If the first difference is less than 28 (standard) days, the
                    % times are either regular w.r.t. (calendar) days or time or not
                    % regular, but they can't be regular w.r.t. months. Start by
                    % checking (calendar) days.
                    units = {'days' 'time'};
                else
                    % Otherwise, start by checking months. If there's only two row
                    % times, dt will prefer (e.g.) "1 month" and not "28 days" as
                    % long as it's number of days in the starting month.
                    units = {'months' 'days' 'time'};
                end
                
                for iunit = 1:length(units)
                    [tf,dt] = matlab.internal.datetime.isRegularTimeVector(rowTimes,units{iunit});
                    if tf, break, end
                end
                
                % The time step will always have mdt in the display format, but
                % if it's whole years, or a small number of whole quarters, or
                % whole weeks, give it a nicer format.
                if tf && isa(dt,'calendarDuration')
                    if units{iunit} == "months"
                        numMonths = calmonths(dt);
                        if rem(numMonths,12) == 0 && ~any(dt.Format == 'y')
                            dt.Format = replace(dt.Format,'m','ym');
                        elseif any(abs(numMonths) == [3 6 9])  && ~any(dt.Format == 'q')
                            dt.Format = replace(dt.Format,'m','qm');
                        end
                    elseif units{iunit} == "days"
                        numDays = caldays(dt);
                        if rem(numDays,7) == 0 && ~any(dt.Format == 'w')
                            dt.Format = replace(dt.Format,'d','wd');
                        end
                    end
                end
            end
        end
        
        %-----------------------------------------------------------------------
        function x = orientAs(x)
            % orient as column
            if ~iscolumn(x)
                x = x(:);
            end
        end
    end
end