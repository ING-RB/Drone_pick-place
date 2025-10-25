classdef (Sealed) timerange < matlab.internal.tabular.private.subscripter
%

%   Copyright 2016-2024 The MathWorks, Inc.

    properties(Transient, GetAccess = {?timetable, ?matlab.internal.coder.timerange}, SetAccess='protected')
        % left & right edge of range: default to NAT to not match anything

        first = NaT;
        last  = NaT;

        % Range type:
        %   'openright' (same as 'closedleft') {default}
        %   'openleft' (same as 'closedright')
        %   'open'
        %   'closed'

        type = 'openright';
    end

    properties(Transient, Access='private')
        % When a timerange is created from two text/numericInf datetime endpoint
        % inputs, the endpoints are created as unzoned datetimes, but are both allowed
        % to act "flexibly" as either zoned or unzoned when subscripting into a
        % timetable, to match whatever the timetable's row times are (that's what
        % first_ and last_matchTimeZone are for), and they are interpreted *in the
        % time zone of the timetable being subscripted (if any)*.
        %
        % The one-input time period syntax behaves as if the same endpoint had been
        % passed in twice, so it's not a special case.
        first_matchTimeZone = false;
        last_matchTimeZone  = false;
        unitOfTime          = '';
        hasEventFilters      = false;
    end

    methods(Access = 'public')
        % Constructor adds an extra, unused input so error handling here catches
        % the common mistake of passing in a timetable as a leading input along
        % with one of the three-input syntaxes. Otherwise, front-end would throw
        % "Too many input arguments".
        function obj = timerange(first,arg2,arg3,~)
            if nargin == 0
                return % No inputs: return default constructed timerange
            end

            try
                narginchk(2,3);

                % If third input is not specified, the second input can be either
                % the second endpoint or a unit of time. Copy the second input as
                % if given as the third, and let processInputs figure it out.
                if nargin == 2, arg3 = arg2; end

                % Determine which of the possible syntaxes we have:
                %     timerange(startTime, endTime)
                %     timerange(timePeriod, unitOfTime)
                %     timerange(startTime, endTime, intervalType)
                %     timerange(startTimePeriod, endTimePeriod, unitOfTime)
                % and initialize the object's endpoints and interval type or unit of time.
                [obj,oneEndpointSyntax] = obj.processInputs(first,arg2,arg3,(nargin==3));

                % The obj.first and obj.last endpoints might still be text or numeric,
                % convert to a datetime or duration.
                obj = obj.endpoints2Timetype(oneEndpointSyntax);

                % When the range is defined in terms of time periods rather than
                % instants, shift the first and last endpoints to the beginning
                % and end of the specified unitOfTime in which they fall.
                if strlength(obj.unitOfTime) > 0
                    obj = obj.snapEndpointsToUnitOfTime();
                end
            catch ME % Limit error stack to this constructor scope
                if isa(first,'tabular') % common error: timerange(tt,startTime,endTime,...)
                    error(message('MATLAB:timerange:TabularInput',upper(class(first))));
                else
                    throw(ME);
                end
            end
        end

        %-----------------------------------------------------------------------
        function tf = isequal(varargin)
            %

            % ISEQUAL True if timerange objects are identical.
            %   TF = ISEQUAL(TR1,TR2,...) returns true when all timerange inputs are
            %   identical, i.e. when their corresponding endpoints are equal, and the
            %   interval types are the same. NaT or NaN endpoints are never treated as
            %   equal.
            %
            %   Examples:
            %      tr1 = timerange(datetime(2021,12,25),"2022-01-6") % defaults to 'openright'
            %      tr2 = timerange("2021-12-25",datetime(2022,1,6),'openright')
            %      isequal(tr1,tr2) % returns true
            %
            %      tr3 = timerange("2021-12-25",datetime(2022,1,6),'closed')
            %      isequal(tr1,tr3) % returns false
            %
            %      tr4 = timerange(datetime(2021,12,25),datetime(2022,1,5),'day')
            %      isequal(tr1,tr4) % returns true
            %
            %      tr5 = timerange("2021-12-25",Inf)
            %      isequal(tr5,tr5) % returns true
            %
            %      tr6 = timerange("2021-12-25",NaT)
            %      isequal(tr6,tr6) % returns false, isequal(NaT,NaT) == false

            narginchk(2,Inf);
            tf = isequalUtil(@isequal,varargin);
        end

        %-----------------------------------------------------------------------
        function tf = isequaln(varargin)
            %

            % ISEQUAL True if timerange objects are identical,treating NaT or NaN endpoints as equal.
            %   TF = ISEQUALN(TR1,TR2,...) returns true when all timerange inputs are
            %   identical, i.e. when their corresponding endpoints are equal (including
            %   treating NaT or NaN as equal), and the interval types are the same.
            %
            %   Examples:
            %      tr1 = timerange(datetime(2021,12,25),"2022-01-6") % defaults to 'openright'
            %      tr2 = timerange("2021-12-25",datetime(2022,1,6),'openright')
            %      isequaln(tr1,tr2) % returns true
            %
            %      tr3 = timerange("2021-12-25",datetime(2022,1,6),'closed')
            %      isequaln(tr1,tr3) % returns false
            %
            %      tr4 = timerange(datetime(2021,12,25),datetime(2022,1,5),'day')
            %      isequaln(tr1,tr4) % returns true
            %
            %      tr5 = timerange("2021-12-25",Inf)
            %      isequaln(tr5,tr5) % returns true
            %
            %      tr6 = timerange("2021-12-25",NaT)
            %      isequaln(tr6,tr6) % returns true, isequaln(NaT,NaT) == true

            narginchk(2,Inf);
            tf = isequalUtil(@isequaln,varargin);
        end

        %-----------------------------------------------------------------------
        function t = keyMatch(~,~) %#ok<STOUT>
            %

            %KEYMATCH True if two keys are the same.
            %   keyMatch(d1,d2) returns logical 1 (true) if arrays d1 and d2 are
            %   both the same class and equal. Returns 0 (false) otherwise.
            %
            %   See also keyHash, dictionary, isequal, eq.
            error(message("MATLAB:datatypes:InvalidTypeKeyMatch","timerange"));
        end

        %-----------------------------------------------------------------------
        function h = keyHash(~) %#ok<STOUT>
            %

            %KEYHASH Generates a hash code
            %   h = keyHash(d) returns a uint64 scalar that represents the input array. Note that
            %   hash values are not guaranteed to be consistent across different MATLAB sessions.
            %
            % See also keyMatch, dictionary.
            error(message("MATLAB:datatypes:InvalidTypeKeyHash","timerange"));
        end
    end % public methods

    %=======================================================================
    methods(Access=private)
        function [obj,oneEndpointSyntax] = processInputs(obj,first,arg2,arg3,threeInputSyntax)
            % PROCESSINPUTS recognizes arg3 as either IntervalType or UnitOfTime. When
            % threeInputSyntax is true, arg3 is always one of those (or an error). When
            % threeInputSyntax is false, arg3 is a copy of arg2, so it may be the second
            % endpoint instead of UnitOfTime (can't be IntervalType).
            %
            % oneEndpointSyntax is true for timerange(first,"unitOfTime") and false otherwise.
            import matlab.internal.datatypes.isScalarText

            obj.first = first;

            % arg2 might contain the second endpoint, or an intervalType or unitOfTime. Wait
            % until arg3 is identified to make a final decision.
            obj.last = arg2; % provisionally
            oneEndpointSyntax = false;

            % getChoice would be nice here, but for timerange("startTime",endTime), that means
            % a throw/catch in order to continue on, which is slow and should be unnecessary.

            % arg3 always contains the last input to timerange, regardless of whether
            % there were two or three inputs. First try to recognize it as an intervalType
            % then as a unitOfTime. If it's not, and there were two inputs, it might be the
            % second endpoint, assume it is (if there were three inputs, it's a bad intervalType
            % or unitOfTime).
            foundIntervalTypeOrTimeUnit = false;
            if isScalarText(arg3)
                if threeInputSyntax
                    choices = {'openright' 'closedleft' 'openleft' 'closedright' 'open' 'closed'};
                    % Require an exact match for intervalType because the choices overlap so much
                    choice = find(strcmpi(arg3,choices)); % no partial match
                    if isscalar(choice) % timerange(startTime, endTime, "intervalType")
                        obj.type = choices{choice}; % braces, store as char
                        foundIntervalTypeOrTimeUnit = true;
                    else
                        % not an interval type, go on to look for a time period
                    end
                end
                if ~foundIntervalTypeOrTimeUnit
                    choices = {'years', 'quarters', 'months', 'weeks', 'days', 'hours', 'minutes', 'seconds'};
                    choice = find(strncmpi(arg3,choices,max(strlength(arg3),1))); % partial match, but not for ''
                    if isscalar(choice) % timerange(startTimePeriod, endTimePeriod, "unitOfTime") or timerange(timePeriod, "unitOfTime")
                        obj.unitOfTime = choices{choice}; % braces, store as char
                        if ~threeInputSyntax % timerange(timePeriod,"unitOfTime")
                            obj.last = first; % treat as timerange(timePeriod,timePeriod,"unitOfTime")
                            oneEndpointSyntax = true;
                        end
                        foundIntervalTypeOrTimeUnit = true;
                    elseif ~isempty(choice)
                        error(message("MATLAB:timerange:AmbiguousUnitOfTime",choices{choice(1:2)}));
                    else
                        % common error handling below
                    end
                end
            end
            if ~foundIntervalTypeOrTimeUnit
                if threeInputSyntax % timerange(startTimePeriod, endTimePeriod, noMatch)
                    % 3rd arg must be intervalType or unitOfTime
                    error(message('MATLAB:timerange:InvalidIntervalType'));
                else % timerange(timePeriod, noMatch)
                    % arg3 same as arg2 which was already saved in last, provisionally timerange(startTime, endTime)
                end
            end
        end

        %-----------------------------------------------------------------------
        function obj = endpoints2Timetype(obj,oneEndpointSyntax)
            import matlab.internal.datatypes.throwInstead

            firstTraits = endpointTraits(obj.first); % enforces time type, text, or numeric Inf/NaN

            if oneEndpointSyntax
                % If the endpoint is already a datetime or duration, no conversion is needed.
                if firstTraits.isText || firstTraits.isNonFiniteNum
                    % The endpoint is text or numeric Inf/NaN. Only a datetime endpoint is legal
                    % for this syntax, call convertEndpoint with a datetime template. The template
                    % does NOT determine the output type except to disambiguate Inf, 'Inf' and ''.
                    % A timer timestamp will be interpreted as duration (thus an error), never as
                    % a partial datetime. Numeric NaN always becomes a duration (thus an error).
                    % The datetime template also causes the output to be unzoned and flexible.
                    try
                        obj.first = convertEndpoint(obj.first,obj.unitOfTime,datetime);
                    catch ME
                        throwInstead(ME,'MATLAB:timerange:InputTypesMismatch','MATLAB:timerange:UnitOfTimeTypesMismatch');
                    end
                    obj.first_matchTimeZone = true;
                elseif firstTraits.isEventFilter
                    error(message('MATLAB:timerange:UnitOfTimeTypesMismatch'));
                else
                    % first was a time type, first_matchTimeZone defaults to false
                end
                % At this point, .first is a datetime or eventfilter. If a datetime,
                % convertEndpoint would have errored if its output's type did not match
                % the (datetime) template's.

                % Only one endpoint given, no need to check if the two endpoints are
                % compatible, they are. Behave as if second is identical.
                obj.last = obj.first;
                obj.last_matchTimeZone = obj.first_matchTimeZone;
            else
                lastTraits = endpointTraits(obj.last); % enforces time type, text, or numeric Inf/NaN

                % At this point, both endpoints are a time type, text, or numeric Inf/NaN,
                % so only those cases need be handled in the logic below.

                if firstTraits.isDatetime || firstTraits.isDuration || firstTraits.isEventFilter
                    if lastTraits.isDatetime && firstTraits.isDatetime
                        % Both endpoints are datetimes, no conversion needed, just check
                        % for time zone compatibility.
                        if isempty(obj.first.TimeZone) ~= isempty(obj.last.TimeZone)
                            error(message('MATLAB:timerange:TimeZonesMismatch'));
                        end
                    elseif lastTraits.isDuration && firstTraits.isDuration
                        % Both endpoints are durations, no conversion needed.
                    elseif lastTraits.isEventFilter && firstTraits.isEventFilter
                        % Both endpoints are EventFilter, no conversion needed.
                        obj.hasEventFilters = true;
                    elseif lastTraits.isText || lastTraits.isNonFiniteNum
                        % First endpoint is datetime or duration and the other is text or numeric
                        % Inf/NaN, call convertEndpoint with first endpoint as template. The
                        % output's type must match the template, but the template does NOT
                        % determine that type except to disambiguate Inf, 'Inf' and ''. A timer
                        % timestamp will be interpreted as duration, never as a partial datetime.
                        % Numeric NaN always becomes a duration.
                        %
                        % Also, the template determines the timezone of a datetime output: the
                        % endpoint becomes a zoned or unzoned datetime to match the template, i.e.
                        % the other endpoint.
                        obj.last = convertEndpoint(obj.last,obj.unitOfTime,obj.first);
                    else
                        % Mixed datetime/duration types is an error.
                        error(message('MATLAB:timerange:InputTypesMismatch'));
                    end
                    % At this point, .first  and .last are either both datetime, or both
                    % duration, or both eventfilter. If datetime or duration,
                    % convertEndpoint would have errored if its output's type did not
                    % match the template's (i.e. obj.first).
                    %
                    % first_matchTimeZone and last_matchTimeZone default to false. If the
                    % first endpoint was datetime and the second was text/numeric, the
                    % latter was converted to datetime using the first as a template,
                    % including time zone. So in all cases, false is correct.

                elseif lastTraits.isDatetime || lastTraits.isDuration
                    % Mirror image of timerange(datetime,text) or timerange(duration,text)
                    obj.first = convertEndpoint(obj.first,obj.unitOfTime,obj.last);

                else
                    % No time type to go on, try to infer type from text or numeric.
                    tryFirst = convertEndpoint(obj.first,obj.unitOfTime);
                    if isfinite(tryFirst) || (ismissing(tryFirst) && ~firstTraits.isEmptyText)
                        % The first endpoint is interpretable as a finite time type, or as
                        % an explicit NaT/NaN (i.e. not coming from from ''). Also use it
                        % as a hint for the second endpoint (see comments above).
                        obj.first = tryFirst;
                        obj.last = convertEndpoint(obj.last,obj.unitOfTime,obj.first);
                    else
                        % The first endpoint was Inf/'Inf'/'', try the second.
                        tryLast = convertEndpoint(obj.last,obj.unitOfTime);
                        if isfinite(tryLast) || (ismissing(tryLast) && ~lastTraits.isEmptyText)
                            % The second endpoint is interpretable as a finite time type,
                            % or as an explicit NaT/NaN (i.e. not coming from from '').
                            % Also use it as a hint for the first endpoint (see comments
                            % above).
                            obj.last = tryLast;
                            obj.first = convertEndpoint(obj.first,obj.unitOfTime,obj.last);
                        else
                            % A mix of only Inf/'Inf'/'' is ambiguous, error.
                            error(message('MATLAB:timerange:AmbiguousTimes'));
                        end
                    end

                    % If both endpoints were text or numeric Inf that became datetimes,
                    % flag them to allow getSubscripts to automatically convert to
                    % whatever time zone is needed when being used in timetable
                    % subscripting. Otherwise, false.
                    obj.first_matchTimeZone = isa(obj.first,'datetime');
                    obj.last_matchTimeZone = isa(obj.last,'datetime');
                end
            end
        end

        %-----------------------------------------------------------------------
        function obj = snapEndpointsToUnitOfTime(obj)
            % Duration endpoints are not accepted for UNITOFTIME semantics.
            % Let DATESHIFT error to avoid a more expensive isa test.
            try
                obj.first = dateshift(obj.first, 'start', obj.unitOfTime);
                obj.last  = dateshift(obj.last,  'start', obj.unitOfTime, 'next');
            catch ME
                if isa(obj.first,'duration') || isa(obj.last,'duration') || isa(obj.first,'eventfilter') || isa(obj.last,'eventfilter')
                    error(message('MATLAB:timerange:UnitOfTimeTypesMismatch'));
                else
                    rethrow(ME)
                end
            end
        end
    end % private methods

    %=======================================================================
    methods(Access={?withtol, ?timerange, ?vartype, ?matlab.io.RowFilter, ?matlab.internal.tabular.private.tabularDimension, ?tabular})
        % The getSubscripts method is called by table subscripting to find the indices
        % of the times (if any) along that dimension that fall between the specified
        % left and right time.
        function subs = getSubscripts(obj,tt,operatingDim)
            % Only timetable row subscripting is supported. TIMERANGE is used in
            % invalid context if t is not a timetable or we are not operating
            % along the rowDim.
            if ~(isa(tt,'timetable') && matches(operatingDim,'rowDim'))
                throwAsCaller(MException(message('MATLAB:timerange:InvalidSubscripter')));
            end

            try
                obj = obj.convertEventEnds(tt);

                % If the timerange was constructed from two text/numericInf datetime
                % timestamps, interpret them in the same time zone (if any) as the
                % timetable's row times. If they were duration timestamps of any kind,
                % matchTimeZone is false.
                if obj.first_matchTimeZone % || obj.last_matchTimeZone always same
                    % Get an example of the timetable's row times, but avoid
                    % expanding out an implicit row times vector
                    rowTimes = tt.rowDim.rowTimesTemplate();
                    rowTimesTZ = rowTimes.TimeZone; % errors if timetable's row times are durations
                    if  ~isempty(rowTimesTZ)
                        obj.first.TimeZone = rowTimesTZ;
                        obj.last.TimeZone = rowTimesTZ;
                    end
                end

                % Let the dimension object decide what's in the specified range,
                % without expanding an implicit row times vector
                subs = tt.rowDim.timerange2subs(obj.first,obj.last,obj.type);
            catch ME
                rowTimes = tt.rowDim.rowTimesTemplate(); % may not have gotten it above, make sure
                if ~isequal(class(rowTimes),class(obj.first)) && ~obj.hasEventFilters
                    % The timetable's row times and the timerange's first/last
                    % times were a mix of datetime and duration.
                    throwAsCaller(MException(message('MATLAB:timerange:MismatchRowTimesType',class(rowTimes),class(obj.first))));
                else
                    rethrow(ME);
                end
            end
        end

        function obj = convertEventEnds(obj,tt)
            % Convert a timerange of eventfilters to a timerange with
            % datetime/duration first and last values.
            % Used by getSubscripts and containsrange, overlapsrange, withinrange.
            if obj.hasEventFilters
                if isa(tt,"eventtable")
                    % Subscripting into an eventtable with an ordinary timerange is
                    % fine, but won't work if the timerange has eventfilter endpoints,
                    % because the eventtable has no attached events to filter.
                    error(message("MATLAB:eventfilter:EventFilterOnEventTable"));
                elseif isnumeric(tt.rowDim.timeEvents) % [], i.e. a timetable with no attached eventtable
                    error(message("MATLAB:eventfilter:NoEventsForSubscripting"));
                end

                % Select events that match the eventfilter conditions in the first and
                % last timerange endpoints. The endpoints are either both eventfilters,
                % or neither is.
                et = tt.rowDim.timeEvents;
                firstEndpointEvent = find(filterIndices(obj.first,et));
                lastEndpointEvent = find(filterIndices(obj.last,et));

                % The eventfilter endpoints must match only one event. We do not allow the
                % filter condition to match multiple events even if those events have the
                % same time, or even if only one matches rows in the timetable. Either event
                % might match more than one timetable row, but the one event has a unique
                % time.
                if ~isscalar(firstEndpointEvent) || ~isscalar(lastEndpointEvent)
                    throwAsCaller(MException(message('MATLAB:timerange:FilterMatchesMultipleEvents')));
                end

                % Use the times of the matching events as the timerange endpoints. Because the
                % events are coming from the same eventtable, they are both either instantaneous
                % events or both interval events.
                if hasInstantEvents(tt.rowDim.timeEvents)
                    % For instantaneous events, use the event times as the timerange endpoints.
                    obj.first = et.rowDim.labels(firstEndpointEvent);
                    obj.last = et.rowDim.labels(lastEndpointEvent);
                else
                    % For interval events, base the timerange endpoints on the two event intervals.
                    [eventTimes,eventEndTimes] = eventIntervalTimes(et,[firstEndpointEvent lastEndpointEvent]);
                    switch obj.type
                        case 'closed'
                            % Use the "first" event's beginning time and the "last" event's ending
                            % time as the timerange endpoints. timerange2subs will include both,
                            % effectively closing the open upper edge of the interval event.
                            obj.first = eventTimes(1);
                            obj.last = eventEndTimes(2);
                        case 'open'
                            % Use the "first" event's ending time and the "last" event's beginning
                            % time as the timerange endpoints. timerange2subs will exclude both,
                            % effectively opening the closed lower edge of the interval event.
                            obj.first = eventEndTimes(1);
                            obj.last = eventTimes(2);
                        case {'closedleft' 'openright'}
                            % Use the "first" event's beginning time and the "last" event's
                            % beginning time as the timerange endpoints. timerange2subs will
                            % include the former, exclude the latter, coinciding with the
                            % already openright interval event.
                            obj.first = eventTimes(1);
                            obj.last = eventTimes(2);
                        otherwise % {'closedright' 'openleft'}
                            % Use the "first" event's ending time and the "last" event's ending
                            % time as the timerange endpoints. timerange2subs will exclude the
                            % former and include the latter, effectively closing the open upper
                            % edge of the interval event.
                            obj.first = eventEndTimes(1);
                            obj.last = eventEndTimes(2);
                    end
                end
                obj.hasEventFilters = false;
            end
        end
    end % restricted methods

    %=======================================================================
    methods(Hidden)
        function disp(obj)
            % Take care of formatSpacing
            import matlab.internal.display.lineSpacingCharacter
            import matlab.internal.datatypes.addClassHyperlink
            tab = sprintf('\t');

            % Determine what string to display depending on the interval type
            if ~obj.hasEventFilters
                is_NaN_NaT_endpoints = (~isfinite(obj.first) && ~isinf(obj.first)) || (~isfinite(obj.last) && ~isinf(obj.last));
                isNullRange = (obj.first > obj.last) || ((obj.type ~= "closed") && (obj.first == obj.last));
                rowMsg = getString(message('MATLAB:timerange:UIStringDispSelectTimes'));
            else
                is_NaN_NaT_endpoints = false;
                isNullRange = false;
                rowMsg = getString(message('MATLAB:timerange:UIStringDispSelectEventTimes'));
            end

            if is_NaN_NaT_endpoints
                msgid = 'MATLAB:timerange:UIStringDispNaTNaNEndpoint';
                rowMsg = [];
            elseif isNullRange
                msgid = 'MATLAB:timerange:UIStringDispNullRange';
                rowMsg = [];
            elseif matches(char(obj.type),["openright" "closedleft"]) % char is needed around obj.type to support disp of empty timerange
                msgid = 'MATLAB:timerange:UIStringDispRightOpen';
            elseif matches(char(obj.type),["openleft" "closedright"])
                msgid = 'MATLAB:timerange:UIStringDispLeftOpen';
            elseif char(obj.type) == "open"
                msgid = 'MATLAB:timerange:UIStringDispOpen';
            else % closed
                msgid = 'MATLAB:timerange:UIStringDispClosed';
            end

            % Plug in the time range end points
            if is_NaN_NaT_endpoints
                dispMsg = getString(message(msgid, 'NaN/NaT'));
            elseif isNullRange
                dispMsg = getString(message(msgid));
            elseif isa(obj.first,'datetime')
                % Use the default date and time format for datetime. The time portion must be included to make the range
                % as explicit as possible.
                dispMsg = getString(message(msgid, rowMsg, char(obj.first, defaultFormat(obj.first)), char(obj.last, defaultFormat(obj.last))));
            elseif obj.hasEventFilters
                dispMsg = getString(message(msgid, rowMsg, char(formatDisplayBody(obj.first)), char(formatDisplayBody(obj.last))));

            else % duration timerange, don't need a format specified
                dispMsg = getString(message(msgid, rowMsg, char(obj.first), char(obj.last)));
            end


            classNameLine = getString(message('MATLAB:timerange:UIStringDispHeader'));
            disp([tab addClassHyperlink(classNameLine,mfilename('class')) lineSpacingCharacter]); % no hyperlink added if hotlinks off
            disp([tab tab dispMsg lineSpacingCharacter]);
            if matlab.internal.display.isHot
                disp([tab getString(message('MATLAB:timerange:UIStringDispFooter')) lineSpacingCharacter]);
            end
        end
    end

    %%%% PERSISTENCE BLOCK ensures correct save/load across releases %%%%%%
    %%%% Properties and methods in this block maintain the exact class %%%%
    %%%% schema required for TIMERANGE to persist through MATLAB releases %
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
        %   1.3 : 18b. added serialized field 'unitOfTime' for different
        %              display of timerange created with UNITOFTIME syntax.
        %   1.4 : 23a. added support for eventfilter as start and end

        version = 1.4;
    end

    %=======================================================================
    methods(Hidden)
        function s = saveobj(obj)
            s = struct;
            s = obj.setCompatibleVersionLimit(s, 1.0); % limit minimum version compatible with a serialized instance

            s.first                = obj.first; % scalar datetime or duration. left limit of the range.
            s.first_matchTimeZone  = obj.first_matchTimeZone;
            s.last                 = obj.last;  % scalar datetime or duration. right limit of the range.
            s.last_matchTimeZone   = obj.last_matchTimeZone;
            s.hasEventFilters      = obj.hasEventFilters;
            s.type                 = obj.type;  % row character vector. One of {'openright' 'closedleft' 'openleft' 'closedright' 'open' 'closed'}
            s.unitOfTime           = obj.unitOfTime; % row character vector. '' or one of {'years' 'quarters' 'months' 'weeks' 'days' 'hours' 'minutes' 'seconds'}
        end
    end

    %=======================================================================
    methods(Hidden, Static)
        function obj = loadobj(s)
            % Always default construct an empty instance, and recreate a
            % proper timerange in the current schema using attributes
            % loaded from the serialized struct
            obj = timerange();

            % Pre-18a (i.e. v1.0) saveobj did not save the versionSavedFrom
            % field. A missing field would indicate it is serialized in
            % version 1.0 format. Append the field if it is not present.
            if ~isfield(s,'versionSavedFrom')
                s.versionSavedFrom = 1.0;
            end

            % Return the empty instance if current version is below the
            % minimum compatible version of the serialized object
            if obj.isIncompatible(s, 'MATLAB:timerange:IncompatibleLoad')
                return;
            end

            % Restore serialized data
            % ASSUMPTION: 1. type and semantics of the serialized struct
            %                fields are consistent as stated in saveobj above.
            %             2. as a result of #1, the values stored in the
            %                serialized struct fields are valid in this
            %                version of timerange, and can be assigned into
            %                the reconstructed object without any check
            obj.first               = s.first;
            obj.last                = s.last;
            obj.type                = s.type;
            obj.first_matchTimeZone = (s.versionSavedFrom >= 1.1) && s.first_matchTimeZone;
            obj.last_matchTimeZone  = (s.versionSavedFrom >= 1.1) && s.last_matchTimeZone;
            obj.hasEventFilters     = (s.versionSavedFrom >= 1.4) && s.hasEventFilters;
            if s.versionSavedFrom >= 1.3
                obj.unitOfTime = s.unitOfTime;
            end
        end

        function name = matlabCodegenRedirect(~)
            % Use the implementation in the class below when generating
            % code.
            name = 'matlab.internal.coder.timerange';
        end
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% helpers %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function timetype = convertEndpoint(endpoint,unitOfTime,template)
    import matlab.internal.datetime.text2timetype
    if isnumeric(endpoint) % Convert numeric endpoint to either datetime or duration
        if nargin == 3
            if isa(template,'datetime')
                % Numeric Inf becomes a datetime, but numeric NaN is a duration.
                if isinf(endpoint)
                    timetype = datetime.fromMillis(endpoint,template.Format,template.TimeZone);
                else % NaN
                    error(message('MATLAB:timerange:InputTypesMismatch'));
                end
            else % duration
                % Numeric Inf and NaN both become a duration.
                timetype = duration.fromMillis(endpoint,template.Format); % NaN or +/-Inf
            end
        else
            timetype = duration.fromMillis(endpoint); % Inf/NaN -> duration for backwards compatibility
        end
    else % Parse text endpoint to either datetime or duration
        try
            % Neither the template nor the unitOfTime input inform the decision between duration
            % and datetime, except to tell text2timetype how to interpret 'Inf' and '' ('NaN' is
            % always duration; 'NaT' is always datetime). Other than that, text2timetype decides
            % if the input text is a datetime or a duration based only on the text, regardless of
            % the other input's type or whether timerange was called with the "time unit" syntax
            % (for which duration is not accepted). text2timetype always interprets a "pure time"
            % timestamp as duration, so for example, timerange('00:00:00','day') is an error, and
            % NOT treated as timerange(datetime('today'),'day'). 'Inf' and '' without a template
            % become datetime.
            if nargin == 3
                timetype = text2timetype(endpoint,'MATLAB:datetime:InvalidTextInput',template);
            else
                timetype = text2timetype(endpoint,'MATLAB:datetime:InvalidTextInput');
            end
        catch ME
            if isempty(unitOfTime) % timerange(first,last) or timerange(first,last,intervalType)
                rethrow(ME);
            else % timerange(first,unitOfTime) or timerange(first,last,unitOfTime)
                % When none of the standard formats are recognized, try some additional
                % datetime-only formats that are unambiguous, given the time unit.
                pureDateFmts = ["MMM-dd-uuuu","uuuu-dd-MMM","dd/MMM/uuuu","MMM/dd/uuuu","uuuu/dd/MMM","uuuu/MMM/dd","dd.MMM.uuuu","MMM.dd.uuuu","uuuu.dd.MMM","uuuu.MMM.dd"];
                switch unitOfTime
                case 'years',    fmts = "uuuu";
                case 'quarters', fmts = ["QQQ-uuuu","uuuu-QQQ","QQQ/uuuu","uuuu/QQQ","QQQ.uuuu","uuuu.QQQ","uuuuQQQ"];
                case 'months',   fmts = ["MMM-uuuu","uuuu-MMM","MMM/uuuu","uuuu/MMM","MMM.uuuu","uuuu.MMM"];
                case 'weeks',    fmts = []; % No anchored format to try
                case 'days',     fmts = pureDateFmts;
                case 'hours',    fmts = pureDateFmts(:) + " " + ["HH:mm" "hh:mm aa"]; % implicit expansion
                case 'minutes',  fmts = pureDateFmts(:) + " " + ["HH:mm" "hh:mm aa"]; % implicit expansion;
                case 'seconds',  fmts = pureDateFmts(:) + " " + ["HH:mm:ss" "hh:mm:ss aa"]; % implicit expansion
                end
                for i = 1:numel(fmts)
                    try
                        timetype = datetime(endpoint,'InputFormat',fmts(i));
                        % Use the template's time zone and format.
                        if nargin == 3
                            timetype.TimeZone = template.TimeZone;
                            timetype.Format = template.Format;
                        end
                        break % success
                    catch
                        if i < numel(fmts)
                            continue % try the next format
                        end
                        % Avoid an err msg from the datetime c'tor suggesting to supply a
                        % format, which the caller can't do.
                        error(message('MATLAB:datetime:InvalidTextInput',endpoint));
                    end
                end
            end
        end

        % The template (mostly) doesn't determine the output type from text2timetype, which might
        % be datetime or duration, but that output's type must match the template's type.
        if nargin == 3
            if ~matches(class(timetype),class(template))
                error(message('MATLAB:timerange:InputTypesMismatch'));
            end
        end
    end
end


%-----------------------------------------------------------------------
function traits = endpointTraits(in)
    import matlab.internal.datetime.isLiteralNonFinite

    traits.isText     = matlab.internal.datatypes.isScalarText(in); % scalar text, that is
    traits.isDatetime = ~traits.isText && isa(in,'datetime'); % short-circuit to avoid isa
    traits.isDuration = ~traits.isText && ~traits.isDatetime && isa(in,'duration'); % short-circuit to avoid isa
    traits.isNonFiniteNum = isnumeric(in) && ~isfinite(in); % +/- Inf or NaN
    traits.isEmptyText = traits.isText && all(isspace(in));
    traits.isEventFilter = isa(in,'eventfilter');


    % Check for error cases in endpoint
    if ~(traits.isText || traits.isDatetime || traits.isDuration || traits.isNonFiniteNum || traits.isEventFilter)
        % Error if type is invalid - finite numeric values are not allowed.
        error(message('MATLAB:timerange:InvalidTimes'));
    elseif ~traits.isText && ~isscalar(in) % already know that text is scalar
        % Endpoints must be scalar
        error(message('MATLAB:timerange:NonScalarInput'));
    end
end


%-----------------------------------------------------------------------
function tf = isequalUtil(testFun,objs)
    % When used to subscript a timetable with UNZONED row times, either flexible
    % or inflexible unzoned endpoints work. But when used to subscript a timetable
    % with ZONED row times, only the flexible unzoned endpoints work, inflexible
    % unzoned endpoints will error. The converse for inflexible zoned endpoints.
    % So in that sense, a timerange with flexible endpoints is never equal to
    % one with inflexible endpoints, zoned or unzoned, even if the timestamps
    % are the same. So all the inputs to isequal must have either flexible or
    % inflexible endpoints. Actually, first_ and last_matchTimeZone are always
    % both either true or false, so only need check one.

    n = length(objs);
    tr_i = objs{1}; % always at least one
    if ~isa(tr_i,"timerange")
        tf = false;
        return
    end
    type = tr_i.type;
    matchTimeZones = sum(tr_i.first_matchTimeZone);
    first = tr_i.first;
    last = tr_i.last;
    for i = 2:n
        tr_i = objs{i};
        if ~isa(tr_i,"timerange") ...
                || ~strcmp(tr_i.type,type) ...
                || (tr_i.first_matchTimeZone ~= matchTimeZones) ...
                || ~testFun(tr_i.first,first) || ~testFun(tr_i.last,last)
            tf = false;
            return
        end
    end
    tf = true;
end
