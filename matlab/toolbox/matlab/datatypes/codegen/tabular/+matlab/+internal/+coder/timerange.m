classdef (Sealed) timerange < matlab.internal.coder.tabular.private.subscripter  %#codegen
%TIMERANGE Timetable row subscripting by time range.

%   Copyright 2019-2023 The MathWorks, Inc.

    properties(GetAccess = {?matlab.internal.coder.timetable}, SetAccess='protected')
        % left & right edge of range: no default to allow either datetime or duration
        first
        last
        
        % Range type: 
        %   'openright' (same as 'closedleft') {default}
        %   'openleft' (same as 'closedright')
        %   'open'
        %   'closed'
        type = 'openright';
    end
    
    properties(Access='private')
        % codegen doesn't yet support timezones, the one-endpoint syntax, or eventfilters,
        % but leave these properties in.
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
            nin = nargin;
            if nin == 0
                % Default to NAT to not match anything
                obj.first = NaT;
                obj.last = NaT;
                return % No inputs: return default constructed timerange
            end

            coder.internal.prefer_const(first);
            
            % Common error: timerange(tt,startTime,endTime,...)
            coder.internal.errorIf(isa(first,'tabular'),'MATLAB:timerange:TabularInput',upper(class(first)));
            
            narginchk(2,3);
            
            % If third input is not specified, the second input can be either
            % the second endpoint or a unit of time. Copy the second input as
            % if given as the third, and let processInputs figure it out.
            if nin == 2, arg3 = arg2; end
            
            % Determine which of the possible syntaxes we have:
            %     timerange(startTime, endTime)
            %     timerange(timePeriod, unitOfTime)
            %     timerange(startTime, endTime, intervalType)
            %     timerange(startTimePeriod, endTimePeriod, unitOfTime)
            % and initialize the object's endpoints and interval type. Unit of time is
            % not yet supported and processInputs throws an error.
            [obj,first,last,oneEndpointSyntax] = obj.processInputs(first,arg2,arg3,(nin==3));

            % The obj.first and obj.last endpoints might still be text or numeric,
            % although text is not supported and endpointTraits throws an error. Convert
            % numeric to a datetime or duration.
            obj = obj.endpoints2Timetype(first,last,oneEndpointSyntax);
            
            % unitOfTime is not yet supported in codegen.
            coder.internal.assert(isempty(obj.unitOfTime), 'MATLAB:timerange:UnitOfTimeNotSupported');
        end
             
        %-----------------------------------------------------------------------
        function tf = isequal(varargin)
            % ISEQUAL True if timerange objects are identical.
            %   TF = ISEQUAL(TR1,TR2,...) returns true when all timerange inputs are
            %   identical, i.e. when their corresponding endpoints are equal, and the
            %   interval types are the same. NaT or NaN endpoints are never treated as
            %   equal.

            narginchk(2,Inf);
            tf = isequalUtil(@isequal,varargin);
        end

        %-----------------------------------------------------------------------
        function tf = isequaln(varargin)
            % ISEQUAL True if timerange objects are identical,treating NaT or NaN endpoints as equal.
            %   TF = ISEQUALN(TR1,TR2,...) returns true when all timerange inputs are
            %   identical, i.e. when their corresponding endpoints are equal (including
            %   treating NaT or NaN as equal), and the interval types are the same.

            narginchk(2,Inf);
            tf = isequalUtil(@isequaln,varargin);
        end
    end % public methods
    
    %=======================================================================
    methods(Access=private)
        function [obj,outfirst,outlast,oneEndpointSyntax] = processInputs(obj,first,arg2,arg3,threeInputSyntax)
            % PROCESSINPUTS recognizes arg3 as either IntervalType or UnitOfTime. When
            % threeInputSyntax is true, arg3 is always one of those (or an error). When
            % threeInputSyntax is false, arg3 is a copy of arg2, so it may be the second
            % endpoint instead of UnitOfTime (can't be IntervalType).
            %
            % oneEndpointSyntax is true for timerange(first,"unitOfTime") and false otherwise.
            coder.internal.prefer_const(first,arg2,arg3,threeInputSyntax);

            % arg2 might contain the second endpoint, or an intervalType or unitOfTime. Wait
            % until arg3 is identified to make a final decision.
            last = arg2; %#ok<PROPLC> % provisionally
            oneEndpointSyntax = false;

            % getChoice would be nice here, but need to sometimes turn MATLAB:datatypes:AmbiguousChoice
            % into MATLAB:timerange:AmbiguousUnitOfTime which is hard to do in codegen.

            % arg3 always contains the last input to timerange, regardless of whether
            % there were two or three inputs. First try to recognize it as an intervalType
            % then as a unitOfTime. If it's not, and there were two inputs, it might be the
            % second endpoint, assume it is (if there were three inputs, it's a bad intervalType
            % or unitOfTime).
            foundIntervalTypeOrTimeUnit = false;
            if matlab.internal.coder.datatypes.isScalarText(arg3)
                coder.internal.assert(coder.internal.isConst(arg3), 'MATLAB:timerange:NonConstTypeOrUnit');
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

                    % Currently unitOfTime is not supported in codegen.
                    coder.internal.assert(isempty(choice), 'MATLAB:timerange:UnitOfTimeNotSupported');
                end
            end
            if ~foundIntervalTypeOrTimeUnit
                % timerange(startTimePeriod, endTimePeriod, noMatch), 3rd arg must be intervalType or unitOfTime
                coder.internal.errorIf(threeInputSyntax, 'MATLAB:timerange:InvalidIntervalType');
                % By now must be timerange(timePeriod, noMatch), arg3 same as arg2 which was already saved
                % in last, provisionally timerange(startTime, endTime)
            end

            % Avoid setting obj.first and obj.last here, that would fail to preserve
            % compile time constants and wuld not allow us to convert numeric to time type.
            % Instead return first/last vars, and set obj.first/last in endpoints2Timetype.
            outfirst = first;
            outlast = last; %#ok<PROPLC> 
        end
        
        %-----------------------------------------------------------------------
        function obj = endpoints2Timetype(obj,first,last,oneEndpointSyntax)
            coder.internal.prefer_const(first,last);

            firstTraits = endpointTraits(first); % enforces time type or numeric Inf/NaN

            if oneEndpointSyntax
                % If the endpoint is already a datetime or duration, no conversion is needed.
                if firstTraits.isNonFiniteNum
                    % The endpoint is numeric Inf/NaN. Only a datetime endpoint is legal for this
                    % syntax, call convertEndpoint with a datetime template. The template does NOT
                    % determine the output type except to disambiguate Inf. Numeric NaN always
                    % becomes a duration (thus an error). The datetime template also causes the
                    % output to be unzoned and flexible.
                    obj.first = convertNonFiniteNumericEndpoint(first,datetime,'MATLAB:timerange:UnitOfTimeTypesMismatch');
                    obj.first_matchTimeZone = true;
                else
                    % first was a time type, first_matchTimeZone defaults to false
                    obj.first = first;
                end
                % At this point, .first is a datetime, convertEndpoint would have errored if
                % its output's type did not match the (datetime) template's.

                % Only one endpoint given, no need to check if the two endpoints are
                % compatible, they are. Behave as if second is identical.
                obj.last = first;
                obj.last_matchTimeZone = obj.first_matchTimeZone;
            else
                lastTraits = endpointTraits(last); % enforces time type or numeric Inf/NaN

                % At this point, both endpoints are a time type or numeric Inf/NaN,
                % so only those cases need be handled in the logic below.

                if firstTraits.isDatetime || firstTraits.isDuration
                    if lastTraits.isDatetime && firstTraits.isDatetime
                        % Both endpoints are datetimes, no conversion needed, just check for time
                        % zone compatibility, although codegen doesn't support time zones.
                        coder.internal.errorIf(isempty(first.TimeZone) ~= isempty(last.TimeZone),'MATLAB:timerange:TimeZonesMismatch');
                        obj.first = first;
                        obj.last = last;
                    elseif lastTraits.isDuration && firstTraits.isDuration
                        % Both endpoints are durations, no conversion needed.
                        obj.first = first;
                        obj.last = last;
                    else
                        % Mixed datetime/duration types is an error.
                        coder.internal.errorIf(~lastTraits.isNonFiniteNum,'MATLAB:timerange:InputTypesMismatch');

                        % First endpoint is datetime or duration and the other is numeric Inf/NaN,
                        % call convertEndpoint with first endpoint as template. The output's type
                        % must match the template, but the template does NOT determine that type
                        % except to disambiguate Inf. Numeric NaN always becomes a duration.
                        %
                        % Also, the template determines the timezone of a datetime output: the
                        % endpoint becomes a zoned or unzoned datetime to match the template, i.e.
                        % the other endpoint.
                        obj.first = first;
                        obj.last = convertNonFiniteNumericEndpoint(last,first,'MATLAB:timerange:InputTypesMismatch');
                    end
                    % At this point, .first  and .last are either both datetime, or both
                    % duration. convertEndpoint would have errored if its output's type
                    % did not match the template's (i.e. obj.first).
                    %
                    % first_matchTimeZone and last_matchTimeZone default to false. If the
                    % first endpoint was datetime and the second was numeric, the
                    % latter was converted to datetime using the first as a template,
                    % including time zone. So in all cases, false is correct.

                elseif lastTraits.isDatetime || lastTraits.isDuration
                    % Mirror image of timerange(datetime,numeric) or timerange(duration,numeric)
                    obj.first = convertNonFiniteNumericEndpoint(first,last,'MATLAB:timerange:InputTypesMismatch');
                    obj.last = last;

                else
                    % No time type to go on, try to infer type from numeric.
                    tryFirst = convertNonFiniteNumericEndpoint(first,'MATLAB:timerange:InputTypesMismatch');
                    if ismissing(tryFirst)
                        % The first endpoint is an explicit NaN. Use it as a hint for
                        % the second endpoint (see comments above).
                        obj.first = tryFirst;
                        obj.last = convertNonFiniteNumericEndpoint(last,first,'MATLAB:timerange:InputTypesMismatch');
                    else
                        % The first endpoint was Inf, try the second.
                        tryLast = convertNonFiniteNumericEndpoint(last,'MATLAB:timerange:InputTypesMismatch');
                        % A mix of only Inf is ambiguous, error.
                        coder.internal.errorIf(~ismissing(tryLast),'MATLAB:timerange:AmbiguousTimes');
                        % The second endpoint is an explicit NaN. Use it as a hint for
                        % the first endpoint (see comments above).
                        obj.last = tryLast;
                        obj.first = convertNonFiniteNumericEndpoint(first,last,'MATLAB:timerange:InputTypesMismatch');
                    end

                    % If both endpoints were numeric Inf that became datetimes,
                    % flag them to allow getSubscripts to automatically convert to
                    % whatever time zone is needed when being used in timetable
                    % subscripting. Otherwise, false.
                    obj.first_matchTimeZone = isa(obj.first,'datetime');
                    obj.last_matchTimeZone = isa(obj.last,'datetime');
                end
            end
        end
    end % private methods
    

    %=======================================================================
    methods(Access={?matlab.internal.coder.timerange, ...
                    ?matlab.internal.coder.withtol, ...
                    ?matlab.internal.coder.tabular.private.tabularDimension, ...
                    ?matlab.internal.coder.tabular})
        % The getSubscripts method is called by table subscripting to find the indices
        % of the times (if any) along that dimension that fall between the specified
        % left and right time.
        function subs = getSubscripts(obj,dimObj)
            % A timerange is only supported on a rowTimesDim
            coder.internal.assert(isa(dimObj,'matlab.internal.coder.tabular.private.rowTimesDim'),'MATLAB:timerange:InvalidSubscripter');
            
            % No timezone support in codegen, so no check to see if we need to match
            % an unzoned endpoint "as if" it were zoned.
                
            % Let the dimension object decide what's in the specified range,
            % without expanding an implicit row times vector
            subs = dimObj.timerange2subs(obj.first,obj.last,obj.type);

            % timerange2subs asserts if endpoint time types do not match row times type.
        end
    end 
    
    methods(Hidden, Static)
        function out = matlabCodegenFromRedirected(tr)
            out = timerange(tr.first, tr.last, tr.type);
        end
        
        function out = matlabCodegenToRedirected(tr)
            out = matlab.internal.coder.timerange(tr.first, tr.last, tr.type);
        end
    end
    
    methods(Hidden, Static)
        function name = matlabCodegenUserReadableName
            % Make this look like a timerange (not the redirected timerange) in the codegen report
            name = 'timerange';
        end
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% helpers %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function timetype = convertNonFiniteNumericEndpoint(endpoint,template,errID)
    % Convert numeric Inf/NaN endpoint to either datetime or duration
    coder.internal.prefer_const(template);
    if nargin >= 2
        if isa(template,'datetime')
            % Numeric Inf becomes a datetime, but numeric NaN is a duration.
            coder.internal.errorIf(~isinf(endpoint),errID); % NaN
            timetype = datetime(endpoint,0,0); % Inf
        else % duration
            % Numeric Inf and NaN both become a duration.
            timetype = duration(endpoint,0,0); % NaN or +/-Inf
        end
    else
        timetype = duration(endpoint,0,0); % Inf/NaN -> duration for backwards compatibility
    end
end

%-----------------------------------------------------------------------
function traits = endpointTraits(in)
    coder.internal.prefer_const(in);
    
    % Conversion from text is not supported in codegen
    coder.internal.errorIf(matlab.internal.coder.datatypes.isScalarText(in),'MATLAB:timerange:TextInputsNotSupported');

    traits_isscalar = coder.internal.isConst(size(in)) && isscalar(in);
    traits_isDatetime = isa(in,'datetime'); % "new fields cannot be added when structure has been read or used"
    traits.isDatetime = traits_isDatetime;
    traits.isDuration = ~traits_isDatetime && isa(in,'duration'); % short-circuit to avoid isa
    traits.isNonFiniteNum = traits_isscalar && isnumeric(in) && coder.internal.isConst(in) && ~isfinite(in); % +/- Inf or NaN
    
    % Check for error cases in endpoint

    % Error if type is invalid - finite numeric values are not allowed.
    coder.internal.errorIf(~(traits.isDatetime || traits.isDuration || traits.isNonFiniteNum),'MATLAB:timerange:InvalidTimes');
    % Endpoints must be scalars
    coder.internal.assert(traits_isscalar,'MATLAB:timerange:NonScalarInput');
end

%-----------------------------------------------------------------------
function tf = isequalUtil(testFun,objs)
    
    % No timezone support in codegen, so no checks here to match a "flexible
    % unzoned endpoint "as if" it were zoned.

    n = length(objs);
    tr_i = objs{1}; % always at least one
    if ~isa(tr_i,"timerange")
        tf = false;
        return
    end
    type = tr_i.type;
    first = tr_i.first;
    last = tr_i.last;
    for i = 2:n
        tr_i = objs{i};
        if ~isa(tr_i,"timerange") ...
                || ~strcmp(tr_i.type,type) ...
                || ~testFun(tr_i.first,first) || ~testFun(tr_i.last,last)
            tf = false;
            return
        end
    end
    tf = true;
end
