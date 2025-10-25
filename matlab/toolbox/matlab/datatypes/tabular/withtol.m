classdef (Sealed) withtol < matlab.internal.tabular.private.subscripter
%

%   Copyright 2016-2024 The MathWorks, Inc.
    
    properties(Transient, Access={?withtol, ?matlab.internal.coder.withtol})
        subscriptTimes = NaT; % sorted datetime/duration vector used for matching
        tol = duration(NaN,0,0); % scalar duration for matching tolerance
    end
    
    properties(Transient, Access='private')
        matchTimeZone  = false;
    end
    
    methods
        % Constructor adds an extra, unused input so error handling catches
        % the common mistake of passing in a timetable as a leading input.
        % Otherwise, front-end would throw "Too many input arguments".        
        function obj = withtol(subscriptTimes,tol,~)
            import matlab.internal.datatypes.isText
            import matlab.internal.datatypes.isScalarText
            import matlab.internal.datetime.text2timetype
            
            % No input arguments, withtol will not match to any time
            if nargin==0
                return;
            end
            
            % common error: withtol(tt,subscriptTimes,tol)
            if istabular(subscriptTimes) 
                error(message('MATLAB:withtol:TabularInput'));
            end
            
            % Enforce 2-input in other cases
            narginchk(2,2);
                        
            % subscriptTimes must be datetime/duration (or text), or an event
            % filter. Columnize the times, not enforcing or preserving input shape.
            if isa(subscriptTimes, 'datetime') || isa(subscriptTimes, 'duration')
                obj.subscriptTimes = subscriptTimes(:);
            elseif isText(subscriptTimes)
                subscriptTimes = text2timetype(subscriptTimes,'MATLAB:datetime:InvalidTextInput');
                obj.subscriptTimes = subscriptTimes(:);
                obj.matchTimeZone = isdatetime(subscriptTimes);
            elseif isa(subscriptTimes,'eventfilter')
                obj.subscriptTimes = subscriptTimes; % eventfilters are scalars
            else
                error(message('MATLAB:timetable:InvalidTimes'));
            end
            
            % tol must be a positive scalar duration.
            if isScalarText(tol)
                try
                    tol = duration(tol); 
                catch
                    error(message('MATLAB:withtol:InvalidTolerance'));
                end
            end
            if ~isscalar(tol) || ~isa(tol, 'duration') || (tol < 0)
                error(message('MATLAB:withtol:InvalidTolerance'));
            end

            % Prevent a tolerance that exceeds half the smallest distance between
            % subscript times, which might result in distinct subscripts selecting the
            % same timetable row. Allow identical subscript times to return repeated
            % rows, but not distinct subscript times. For an eventfilter, this check
            % must wait until the event times are known in getSubscripts.
            if ~isa(obj.subscriptTimes,'eventfilter')
                maxTol = min(diff(unique(obj.subscriptTimes)))/2; % unique sorts result
                if tol >= maxTol
                    error(message('MATLAB:withtol:LargeTolerance',char(maxTol,tol.Format)));
                end
            end
            obj.tol = tol; % scalar duration
        end

        function t = keyMatch(~,~) %#ok<STOUT> 
            %

            %KEYMATCH True if two keys are the same.
            %   keyMatch(d1,d2) returns logical 1 (true) if arrays d1 and d2 are
            %   both the same class and equal. Returns 0 (false) otherwise.
            %
            %   See also keyHash, dictionary, isequal, eq.
            error(message("MATLAB:datatypes:InvalidTypeKeyMatch","withtol"));
        end

        function h = keyHash(~) %#ok<STOUT> 
            %

            %KEYHASH Generates a hash code
            %   h = keyHash(d) returns a uint64 scalar that represents the input array. Note that
            %   hash values are not guaranteed to be consistent across different MATLAB sessions.
            %
            % See also keyMatch, dictionary.
            error(message("MATLAB:datatypes:InvalidTypeKeyHash","withtol"));
        end
    end
    
    methods(Access={?withtol, ?timerange, ?vartype, ?matlab.io.RowFilter, ?matlab.internal.tabular.private.tabularDimension, ?tabular})
        % The getSubscripts method is called by timetable subscripting to find the
        % indices of the times (if any) along that dimension that match the given
        % times within the given tolerance
        function subs = getSubscripts(obj,tt,operatingDim)
            % Only timetable row subscripting is supported. WITHTOL is used in an
            % invalid context if t is not a timetable or we are not operating
            % along the rowDim.
            if ~(isa(tt,'timetable') && matches(operatingDim,'rowDim'))
                error(message('MATLAB:withtol:InvalidSubscripter'));
            end

            rowTimes  = tt.rowDim.labels;
            tol = obj.tol; %#ok<*PROPLC>
            if isa(obj.subscriptTimes,'eventfilter')
                if isa(tt,"eventtable")
                    % Subscripting into an eventtable with an ordinary withtol is
                    % fine, but won't work if the withtol is built on an eventfilter,
                    % because the eventtable has no attached events to filter.
                    error(message("MATLAB:eventfilter:EventFilterOnEventTable"));
                elseif isnumeric(tt.rowDim.timeEvents) % [], i.e. a timetable with no attached eventtable
                    error(message("MATLAB:eventfilter:NoEventsForSubscripting"));
                end

                % Select events that match the condition in the eventfilter. The
                % eventfilter might match multiple events, and any of the matching
                % events might match multiple timetable rows.
                et = tt.rowDim.timeEvents;
                eventIndices = find(filterIndices(obj.subscriptTimes,et));

                % For datetime/duration subscript times, the MATLAB:withtol:LargeTolerance
                % check was already done in the ctor to prevent distinct time subscripts
                % from matching the same row time. But with an eventfilter, the event time
                % differences needed for that check can only be found here when we have the
                % events.

                if hasInstantEvents(et)
                    % For instantaneous events, get the times of the events that match the
                    % eventfilter, as if passed into withtol. These are matched up with the
                    % timetable's row times by timesubs2inds below.
                    subsTimes = unique(et.rowDim.labels(eventIndices),'stable');
                    
                    % Get the smallest time difference between successive events. A
                    % tolerance that exceeds half of that might result in distinct
                    % events selecting the same timetable row. Allow identical event
                    % times to return repeated rows, but not distinct event times.
                    maxTol = min(diff(sort(subsTimes)))/2; % unique sorts the result, 0x1 for one event
                    if tol >= maxTol
                        error(message('MATLAB:withtol:LargeToleranceEvents',char(maxTol,tol.Format)));
                    end
                else
                    % For interval events, let the timetable's rowDim find all its matching rows.
                    [eventTimes,eventEndTimes] = eventIntervalTimes(et,eventIndices);
                    rowSubsCell = tt.rowDim.eventtimes2timetablesubs(eventTimes,eventEndTimes,obj.tol);
                    for i = 1:length(rowSubsCell), rowSubsCell{i} = find(rowSubsCell{i}); end % logical -> indices
                    subs = unique(vertcat(rowSubsCell{:}),'stable');

                    % Get the smallest time gap between successive interval events.
                    % A tolerance that exceeds half of that might result in disjoint
                    % events selecting the same timetable row. Allow identical
                    % events to return repeated rows, but not partially overlapping
                    % or abutting events.
                    maxTol = minIntervalEventsGap(eventTimes,eventEndTimes)/2;
                    if maxTol == 0
                        if tol > 0
                            error(message('MATLAB:withtol:OverlappingEvents'));
                        end
                    elseif tol >= maxTol
                        error(message('MATLAB:withtol:LargeToleranceEvents',char(maxTol,tol.Format)));
                    end

                    % eventtimes2timetablesubs above has already done the time subscripting
                    % that timesubs2inds below would do.
                    return
                end
            else
                subsTimes = obj.subscriptTimes;
            end

            try
                if obj.matchTimeZone
                    subsTimes.TimeZone = rowTimes.TimeZone; % datetime/duration mismatch is error
                end
                % Make a list of rowTimes that match each of subscriptTimes. timetable
                % rowTimes is always a column vector, and subscriptTimes is columnized at
                % construction. Thus subscripts return should also always be a column
                % vector.
                locs = timesubs2inds(subsTimes,rowTimes,tol); % dispatch to datetime or duration
            catch ME
                rowTimesCls  = class(rowTimes);
                subsTimesCls = class(subsTimes);
                if ~isequal(rowTimesCls,subsTimesCls)
                    % Timetable RowTimes has different time type from that in WITHTOL
                    error(message('MATLAB:withtol:MismatchRowTimesType',rowTimesCls,subsTimesCls));
                else
                    rethrow(ME);
                end
            end
            % Each row of locs says which subscript (1st col) matched which row of the
            % timetable (2nd col), with zero in 2nd col indicating no match for that subscript.
            % Unlike rowTimesDim, withtol's caller doesn't care what the original subscripts were,
            % only which rows of the timetable were matched, so we can throw away the 1st col.
            % And withtol does not create new rows, so we can throw away non-matches.
            subs = locs(:,2); % timetable row indices
            subs = subs(subs>0); % remove non-matches.
        end
    end
    
    methods(Hidden)
        function disp(obj)
            % Take care of formatSpacing
            import matlab.internal.display.lineSpacingCharacter;
            import matlab.internal.datatypes.addClassHyperlink;
            tab = sprintf('\t');
            
            numSubscripts = length(obj.subscriptTimes);
            dispSnipThres = numSubscripts;
            if isa(obj.subscriptTimes,'eventfilter')
                displaySubs = char(formatDisplayBody(obj.subscriptTimes));
                UIStringDispTimes = getString(message('MATLAB:withtol:UIStringDispEventTimes'));

            else
            displaySubs = char(obj.subscriptTimes(1:min(dispSnipThres,numSubscripts)));
                UIStringDispTimes = getString(message('MATLAB:withtol:UIStringDispTimes'));
            end
            displaySubsFooter = [tab tab getString(message('MATLAB:withtol:UIStringDispSnipFooter', numSubscripts-dispSnipThres)) lineSpacingCharacter];                        
            
            classNameLine = getString(message('MATLAB:withtol:UIStringDispHeader'));
            disp([tab addClassHyperlink(classNameLine,mfilename('class')) lineSpacingCharacter]); % no hyperlink added if hotlinks off
            disp([tab tab UIStringDispTimes lineSpacingCharacter]);                        
            disp([repmat([tab tab], size(displaySubs,1), 1) displaySubs]);
            disp(displaySubsFooter(numSubscripts>dispSnipThres,:));
            disp([tab tab getString(message('MATLAB:withtol:UIStringDispTolerance', char(obj.tol))) lineSpacingCharacter]);
            if matlab.internal.display.isHot
                disp([tab getString(message('MATLAB:withtol:UIStringDispFooter')) lineSpacingCharacter]);
            end
        end
    end
    
    %%%% PERSISTENCE BLOCK ensures correct save/load across releases %%%%%%
    %%%% Properties and methods in this block maintain the exact class %%%%
    %%%% schema required for WITHTOL to persist through MATLAB releases %%%
    properties(Constant, Access='protected')
        % current running version. This is used only for managing forward
        % compatibility. Value is not saved when an instance is serialized
        %
        %   1.0 : 16b. first shipping version
        %   1.1 : 18a. added 'first_matchTimeZone' & 'last_matchTimeZone'
        %              properties to support timezone inference on match
        %   1.2 : 18a. added serialized field 'incompatibilityMsg' to support
        %              customizable 'kill-switch' warning message. The field
        %              is only consumed in loadobj() and does not translate
        %              into any table property
        %   1.3 : 23a. added support for eventfilter as row times

        version = 1.3;
    end
    
    methods(Hidden)
        function s = saveobj(obj)
            s = struct;
            s = obj.setCompatibleVersionLimit(s, 1.0); % limit minimum version compatible with a serialized instance
            
            s.subscriptTimes = obj.subscriptTimes; % a sorted datetime or duration vector. Used in timetable subscripting to match rowTimes
            s.matchTimeZone  = obj.matchTimeZone;  % scalar logical. Used to decide if subscripting matches TimeZone in the timetable
            s.tol = obj.tol;                       % a scalar duration. Tolerance
        end
    end
    
    methods(Hidden, Static)
        function obj = loadobj(s)
            % Always default construct an empty instance, and recreate a
            % proper WITHTOL in the current schema using attributes
            % loaded from the serialized struct                
            obj = withtol();
            
            % Pre-18a (i.e. v1.0) saveobj did not save the versionSavedFrom
            % field. A missing field would indicate it is serialized in
            % version 1.0 format. Append the field if it is not present.
            if ~isfield(s,'versionSavedFrom')
                s.versionSavedFrom = 1.0;
            end
            
            % Return the empty instance if current version is below the
            % minimum compatible version of the serialized object
            if obj.isIncompatible(s, 'MATLAB:withtol:IncompatibleLoad')
                return;
            end
            
            % Restore serialized data
            % ASSUMPTION: 1. type and semantics of the serialized struct
            %                fields are consistent as stated in saveobj above.
            %             2. as a result of #1, the values stored in the
            %                serialized struct fields are valid in this
            %                version of withtol, and can be assigned into
            %                the reconstructed object without any check
            obj.subscriptTimes = s.subscriptTimes;
            obj.matchTimeZone  = s.versionSavedFrom>1.0 && s.matchTimeZone;
            obj.tol = s.tol;
        end
        
        function name = matlabCodegenRedirect(~)
            % Use the implementation in the class below when generating
            % code.
            name = 'matlab.internal.coder.withtol';
        end
    end
end


function minGap = minIntervalEventsGap(eventTimes,eventEndTimes)
% Sort events by start time then by end time, then find all the
% successive gaps, i.e. upper edge of the i-th event to lower edge
% of (i+1)st event. These might be negative if events overlap.
sortedEventTimes = sortrows([eventTimes eventEndTimes]);
eventTimeGaps = sortedEventTimes(2:end,1) - sortedEventTimes(1:end-1,2); % nextStart - currentEnd
disjointFromPrev = (eventTimeGaps > 0);
if all(disjointFromPrev) % all(empty) == true, so this catches only one event
    % Gaps are all positive, so events do not overlap, so it
    % suffices to look at the min of the successive gaps.
    minGap = min(eventTimeGaps); % 0x1 if only one event
else
    % Some successive events might be disjoint, but at least some are
    % overlapping. Look for partial overlaps or abutting
    eventStartTimeDiffs = sortedEventTimes(2:end,1) - sortedEventTimes(1:end-1,1);
    eventEndTimeDiffs = sortedEventTimes(2:end,2) - sortedEventTimes(1:end-1,2);
    equalToPrev = (eventStartTimeDiffs==0) & (eventEndTimeDiffs==0);
    if any(~disjointFromPrev & ~equalToPrev) % at least one partial overlap
        minGap = 0; % only zero tol is OK
    elseif all(equalToPrev) % no partial overlaps, all identical
        minGap = NaN; % any non-negative tol is OK
    else % at least one disjoint pair
        % Look at the min of the successive gaps between disjoint events.
        minGap = min(eventTimeGaps(disjointFromPrev));
    end
end
end
