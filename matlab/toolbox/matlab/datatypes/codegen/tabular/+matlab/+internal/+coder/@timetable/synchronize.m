function ttOut = synchronize(varargin)   %#codegen
%SYNCHRONIZE Synchronize timetables.

%   Copyright 2020-2022 The MathWorks, Inc.

% Count the number of timetable inputs, and make sure they all
% have the same kind of time vector.
ntimetables = 0;
haveDurations = false;
coder.unroll();
for i = 1:nargin
    if ~isa(varargin{i},'timetable'), break; end
    ntimetables = i;
    
    if isa(varargin{i}.rowDim.labels,'duration') ~= haveDurations
        coder.internal.errorIf(ntimetables > 1, 'MATLAB:timetable:synchronize:MixedTimeTypes');
        haveDurations = true;
    end
end
timetableInputs = cell(1,coder.const(ntimetables));
coder.unroll();
for i = 1:ntimetables
    timetableInputs{i} = varargin{i};
end

isAggregation = false;
isMethodProvided = false;
createAsRegular = false;

coder.internal.errorIf(ntimetables == 0, 'MATLAB:timetable:synchronize:NonTimetableInput');
if nargin == ntimetables
    % Sync to the union of the time vectors, fill unmatched rows with missing
    [newTimes,timesMinMax] = processNewTimesInput('union',timetableInputs);
    method = 'default';
    fillConstant = 0;
    includedEdge = 'left';
    endValues = 'extrap';
    firstRetimeIndex = 1;
    lastRetimeIndex = ntimetables;
elseif nargin == ntimetables + 1
    % Sync to the specified time vector, fill unmatched rows with missing
    newTimesArg = varargin{ntimetables+1};
    [newTimes,timesMinMax,isRegular] = processNewTimesInput(newTimesArg,timetableInputs);
    method = 'default';
    fillConstant = 0;
    includedEdge = 'left';
    endValues = 'extrap';
    % 'regular' requires additional parameters
    coder.internal.errorIf(isRegular, 'MATLAB:timetable:synchronize:RegularWithoutParams');
    if strcmp(newTimes, 'first')
        firstRetimeIndex = 2;
    else
        firstRetimeIndex = 1;
    end
    if strcmp(newTimes, 'last')
        lastRetimeIndex = ntimetables-1;
    else
        lastRetimeIndex = ntimetables;
    end
else % nargin >= ntimetables + 2
    % Sync to the specified time vector.
    newTimesArg = varargin{ntimetables+1};
    [newTimesReturned,timesMinMaxReturned,createAsRegular] = processNewTimesInput(...
        newTimesArg,timetableInputs);
    % processNewTimesInput does not create newTimes for 'regular', it leaves that for
    % processRegularNewTimesInput to handle below.
    
    % Sync using the specified method. Call processMethodInput to get errors on the
    % method before errors on the optional inputs.
    methodArg = varargin{ntimetables+2};
    [methodReturned,isMethodProvided,isPreservingMethod,isAggregation] = processMethodInput(methodArg);
    if isMethodProvided
        % Found a method, start the name value pairs after that input arg.
        nvPairsStart = 3;
        method = methodReturned;
    else
        % If the third input arg was anything other than a name or a function
        % handle, processMethodInput will have errored. Only possibility left is
        % if the third input is the name of _something_, just not a recognized
        % method name. If no other inputs, error as an unrecognized method,
        % otherwise try it as a param name.
        coder.internal.errorIf(nargin == (ntimetables + 2), ...
            'MATLAB:timetable:synchronize:UnrecognizedMethod',methodArg);
        nvPairsStart = 2;
        method = 'default';
    end
    
    if nargin > ntimetables + 2
        pnames = {   'Constant' 'EndValues' 'IncludedEdge'  'SampleRate'  'TimeStep'};
        poptions = struct('CaseSensitivity', false, 'PartialMatching', 'unique', ...
            'StructExpand', false);

        pstruct = coder.internal.parseParameterInputs(pnames, poptions, ...
            varargin{ntimetables+nvPairsStart:end});
        fillConstant = coder.internal.getParameterValue(pstruct.Constant, 0, ...
            varargin{ntimetables+nvPairsStart:end});
        endValuesRaw = coder.internal.getParameterValue(pstruct.EndValues, 'extrap', ...
            varargin{ntimetables+nvPairsStart:end});
        includedEdgeIn = coder.internal.getParameterValue(pstruct.IncludedEdge, ...
            'left', varargin{ntimetables+nvPairsStart:end});
        sampleRate = coder.internal.getParameterValue(pstruct.SampleRate, ...
            [], varargin{ntimetables+nvPairsStart:end});
        timeStep = coder.internal.getParameterValue(pstruct.TimeStep, [], ...
            varargin{ntimetables+nvPairsStart:end});
        useTimeStep = (pstruct.TimeStep ~= 0);
        useSampleRate = (pstruct.SampleRate ~= 0);
        
        % Constant has to be a scalar, and is otherwise validated by assignment in retime.
        % IncludedEdge must be 'left' or 'right'.
        coder.internal.assert(coder.internal.isConst(size(fillConstant)), 'MATLAB:timetable:synchronize:NonconstantConstant');
        coder.internal.assert(isscalar(fillConstant), 'MATLAB:timetable:synchronize:InvalidConstant');
        [~,includedEdge] = matlab.internal.coder.datatypes.getChoice(includedEdgeIn,{'left','right'},'MATLAB:timetable:synchronize:InvalidIncludedEdge');
        
        % Check EndValues for a partial match to 'extrap'. defaultExtrap is true only if the
        % partial match to 'extrap' is constant.
        [endValues,isPartialMatch] = matlab.internal.coder.datatypes.partialMatch(endValuesRaw,{'extrap'});
        defaultExtrap = coder.internal.isConst(endValues) && isPartialMatch;
        % Must be either a constant partial match to 'extrap', or a scalar with constant
        % size. The latter need not itself be constant. No way to differentiate non-constant
        % 'extrap' from an arbitray char vector, so this error is a catch-all.
        coder.internal.assert(defaultExtrap || (coder.internal.isConst(size(endValues)) && isscalar(endValues)), ...
            'MATLAB:timetable:synchronize:NonconstantEndValues');
        
        if createAsRegular
            % Parameters have been processed, create the target time vector using a
            % time step or a sample rate. This will be used in retimeIt, but
            % ultimately the output will be created without storing it explicitly.
            [newTimes,timesMinMax,~,sampleRate] = ...
                processRegularNewTimesInput(timeStep,useTimeStep,sampleRate,useSampleRate,timetableInputs);
        else
            newTimes = newTimesReturned;
            timesMinMax = timesMinMaxReturned;
        end
    else
        % 'regular' requires additional parameters
        coder.internal.errorIf(createAsRegular, 'MATLAB:timetable:synchronize:RegularWithoutParams');
        fillConstant = 0;
        includedEdge = 'left';
        endValues = 'extrap';
        newTimes = newTimesReturned;
        timesMinMax = timesMinMaxReturned;
    end
    
    if strcmpi(newTimesArg, 'first') && isPreservingMethod
        firstRetimeIndex = 2;
    else
        firstRetimeIndex = 1;
    end
    if strcmpi(newTimesArg, 'last') && isPreservingMethod
        lastRetimeIndex = ntimetables-1;
    else
        lastRetimeIndex = ntimetables;
    end
end

coder.internal.assert(haveDurations == isa(newTimes,'duration'), ...
    'MATLAB:timetable:synchronize:MixedTimeTypesNewTimes');

% Maintain tabular-wide properties, left most non-empty is preserved

% Call retimeIt to do the actual work. If syncing to the first input, and the
% method is one that just copies data for matching times, there's no need to
% call retimeIt on the first input, just copy it. Ditto the last input.
timetableOutputs = cell(size(timetableInputs));
overrideVarContinuity = isMethodProvided && ~strcmp(method,'default');
% if we have determined we can just copy first input, do the copy
if firstRetimeIndex > 1
    timetableOutputs{1} = timetableInputs{1};
end
coder.unroll();
for i = firstRetimeIndex:lastRetimeIndex
    ttIn = timetableInputs{i};
    if overrideVarContinuity || isempty(ttIn.varDim.continuity) || ...
            ~coder.internal.isConst(ttIn.varDim.continuity) || ...
            all(ttIn.varDim.continuity == matlab.internal.coder.tabular.Continuity.unset)
        [newTimesOut,newData] = retimeIt(ttIn,newTimes,method,isAggregation,endValues,includedEdge,fillConstant,timesMinMax);
    else
        % If VariableContinuity property is not empty and a method was not
        % provided to override that, apply the method corresponding to each
        % variable's VariableContinuity, and merge the results.
        continuityVals = enumeration('matlab.internal.coder.tabular.Continuity');
        newData = cell(1,ttIn.varDim.length);
        coder.unroll();
        for j = continuityVals(:)' % need row vector in the for-loop index
            whichVars = (ttIn.varDim.continuity == j);
            % Only retimeIt if there are variables to work on with that method.
            if nnz(whichVars)
                ttSubset = ttIn.parenReference(':',whichVars);
                interpMethod = matlab.internal.coder.tabular.getInterpolationMethod(j);
                [newTimesOut,newDataOut] = retimeIt(ttSubset,newTimes,interpMethod,isAggregation,endValues,includedEdge,fillConstant,timesMinMax);
                % Build up new combined .data
                idx = 1;
                coder.unroll();
                for k = 1:numel(whichVars)
                    if whichVars(k)
                        newData{k} = newDataOut{idx};
                        idx = idx + 1;
                    end
                end
            end
        end
    end
    if createAsRegular
        timetableOutputs{i} = ...
            noCheckInitRegular(newData,length(newTimesOut),newTimesOut(1),timeStep,sampleRate,ttIn.varDim,ttIn.metaDim);
    else
        timetableOutputs{i} = ...
            noCheckInit(newData,newTimesOut,ttIn.varDim,ttIn.metaDim);
    end
    timetableOutputs{i}.arrayProps = ttIn.arrayProps;
end
% if we have determined we can just copy last input, do the copy
if lastRetimeIndex < ntimetables
    timetableOutputs{ntimetables} = timetableInputs{ntimetables};
end

% All the output timetables have the same time vector (explicitly or implicitly),
% and their var names have already been made unique, just mash them together.
ttOut = primitiveHorzcat(timetableOutputs{:}); % copies/merges properties


%-------------------------------------------------------------------------------
function [method,isRecognized,isPreserving,isAggregation] = processMethodInput(method)
% Validate the method input, and classify it according to whether it preserves
% the original data if evaluated at the original times 
isRecognized = true;
if matlab.internal.coder.datatypes.isScalarText(method)
    coder.internal.assert(coder.internal.isConst(method), ...
        'MATLAB:timetable:synchronize:NonconstantMethod');
    lowerMethod = matlab.internal.coder.datatypes.partialMatch(method, ...
        {'previous' 'next' 'nearest' 'makima' 'linear' 'spline' 'pchip' 'fillwithmissing' 'fillwithconstant' ...
         'count' 'sum' 'mean' 'median' 'mode' 'prod' 'min' 'max' 'firstvalue' 'lastvalue' 'default'});
    switch lowerMethod
    case {'previous' 'next' 'nearest' 'makima' 'linear' 'spline' 'pchip' 'fillwithmissing' 'fillwithconstant'}
        % 'makima' is not supported in code generation
        coder.internal.errorIf(lowerMethod == "makima", 'Coder:toolbox:FunctionDoesNotSupportDatatype',lowerMethod,'timetable');
        % When evaluated at times that are in an input's time vector, these
        % methods simply repeat that input's data, untouched. So if the target
        % is one of the inputs' time vectors, that input need not be worked on.
        isPreserving = true;
        isAggregation = false;
    case {'count' 'sum' 'mean' 'median' 'mode' 'prod' 'min' 'max' 'firstvalue' 'lastvalue'}
        % These methods (potentially) modify data even when evaluated at times
        % that are in an input's original time vector. So even if the target is
        % one of the inputs' time vectors, calculation must still be done on
        % that input.
        isPreserving = false;
        isAggregation = true;
    case 'default'
        isPreserving = false;
        isAggregation = false;
    otherwise
        % The argument was a name, but not a method name. Caller will try to
        % recognize it as the start of param names/values, but return a flag
        % that no method was provided. 
        isRecognized = false;
        isPreserving = false;
        isAggregation = false;
    end
else
    coder.internal.assert(isa(method,'function_handle'), 'MATLAB:timetable:synchronize:InvalidMethod');
    isPreserving = false;
    isAggregation = true;
end

%-------------------------------------------------------------------------------
function [newTimes,timesMinMax,isRegular] = processNewTimesInput(newTimesIn,timetableInputs)
% Validate the newTimeBasis, newTimeStep, or newTimes input, and compute the
% actual time vector for newTimeBasis or newTimeStep

ntimetables = length(timetableInputs);
isRegular = false;

if isa(newTimesIn,'datetime') || isa(newTimesIn,'duration')
    coder.internal.assert(isvector(newTimesIn),'MATLAB:timetable:synchronize:NotVectorNewTimes');
    timesMinMax = [];
    requireMonotonic(newTimesIn,true); % require strictly monotonic and non-missing in target
    newTimes = newTimesIn;
else
    coder.internal.assert(matlab.internal.coder.datatypes.isScalarText(newTimesIn), ...
        'MATLAB:timetable:synchronize:InvalidNewTimes')
    coder.internal.assert(coder.internal.isConst(newTimesIn), ...
        'MATLAB:timetable:synchronize:NonconstantNewTimes')
    switch matlab.internal.coder.datatypes.partialMatch(newTimesIn,{'union','intersection','commonrange','first','last','regular'})
    case 'union'
        timesMinMax = [];
            if numel(timetableInputs) > 1
                % with more than one timetable, union between the rowtimes
                % result in variable size in the first dimension
                % newTimes is variable sized and grows in each iteration of
                % the for loop
                newTimes = union(sort(timetableInputs{1}.rowDim.labels), ...
                    sort(timetableInputs{2}.rowDim.labels));
                coder.unroll();
                for i = 3:ntimetables
                    newTimes = union(newTimes,sort(timetableInputs{i}.rowDim.labels),'sorted');
                end
            else
                % with just one timetable input, the first dimension remains
                % fix sized
                newTimes = sort(timetableInputs{1}.rowDim.labels);
            end
        requireNonMissing(newTimes); % target already monotonic, require non-missing
    case 'intersection'
        timesMinMax = [];
            if numel(timetableInputs) > 1
                % with more than one timetable, intersect between the rowtimes
                % result in variable size in the first dimension
                % newTimes is variable sized and shrinks in each iteration of
                % the for loop
                newTimes = intersect(sort(timetableInputs{1}.rowDim.labels), ...
                    sort(timetableInputs{2}.rowDim.labels));
                coder.unroll();
                for i = 3:ntimetables
                    newTimes = intersect(newTimes,sort(timetableInputs{i}.rowDim.labels),'sorted');
                end
            else
                % with just one timetable input, the first dimension remains
                % fix sized
                newTimes = sort(timetableInputs{1}.rowDim.labels);
            end
        requireNonMissing(newTimes); % target already monotonic, require non-missing
    case 'commonrange'
        timesMinMax = [];
        if numel(timetableInputs) > 1
            [tmin,tmax] = getCommonTimeRange(timetableInputs,'intersection');
            timesIn1 = timetableInputs{1}.rowDim.labels;
            timesIn2 = timetableInputs{2}.rowDim.labels;
            % newTimes is variable sized and grows in each iteration of
            % the for loop
            newTimes = union(sort(timesIn1(tmin <= timesIn1 & timesIn1 <= tmax,1)), ...
                sort(timesIn2(tmin <= timesIn2 & timesIn2 <= tmax,1)), 'sorted');
            coder.unroll();
            for i = 3:ntimetables
                timesIn = timetableInputs{i}.rowDim.labels;
                times = timesIn(tmin <= timesIn & timesIn <= tmax,1);
                newTimes = union(newTimes,sort(times),'sorted');
            end
        else
            % with just one timetable input, just return the sorted row times
            newTimes = sort(timetableInputs{1}.rowDim.labels);
        end
            requireNonMissing(newTimes); % target already monotonic, require non-missing
    case 'first'
        timesMinMax = [];
        newTimes = timetableInputs{1}.rowDim.labels;
        requireMonotonic(newTimes,true); % require strictly monotonic and non-missing in target
    case 'last'
        timesMinMax = [];
        newTimes = timetableInputs{end}.rowDim.labels;
        requireMonotonic(newTimes,true); % require strictly monotonic and non-missing in target
    case 'regular'
        % processRegularNewTimesInput will handle this case
        timesMinMax = [];
        newTimes = newTimesIn;
        isRegular = true;
    otherwise 
        newTimeStep = newTimesIn;
        [tmin,tmax] = getCommonTimeRange(timetableInputs,'union');

        % For aggregation with a newTimeStep ('hourly', 'minutely', ...), we'll need the min
        % and max bin edges in retimeIt for dealing with deciding whether there are any times
        % that exactly match the first/last bin edge (which one depends on IncludedEdge) and
        % therefore whether there should be a degenerate bin.
        timesMinMax = [tmin tmax];
        
        [tleft,tright,newTimeStep] = getSpanningTimeLimits(tmin,tmax,newTimeStep);
        if isempty(tleft) || isempty(tright)  % codegen does not allow empty colon operands
            newTimes = tleft(zeros(1,0));
        else
            newTimes = (tleft:newTimeStep:tright)'; % no round-off issues at seconds or greater resolution
        end
        requireNonMissing(newTimes); % target already monotonic, require non-missing
    end
end

newTimes = newTimes(:); % force everything to a column

%-------------------------------------------------------------------------------
function [newTimes,timesMinMax,timeStep,sampleRate] = ...
    processRegularNewTimesInput(timeStep,useTimeStep,sampleRate,useSampleRate,timetableInputs)
% Validate the TimeStep or SampleRate parameter and values, and compute the corresponding
% regular time vector
[tmin,tmax] = getCommonTimeRange(timetableInputs,'union');
timesMinMax = [tmin tmax];
[rowTimesDefined,~,~,sampleRate] = matlab.internal.coder.tabular.validateTimeVectorParams(...
    false,tmin,true,timeStep,useTimeStep,sampleRate,useSampleRate);
coder.internal.assert(rowTimesDefined, 'MATLAB:timetable:synchronize:RegularWithoutParams');

if useTimeStep
    % Find limits to span the data, nicely aligned w.r.t. the time step
    unit = getRegularTimeVectorAlignment(timeStep);
    [tleft,~] = getSpanningTimeLimits(tmin,tmax,unit);

    % Calculate the number of rows for the time vector
    if isa(timeStep,'duration')
        % For a duration time step, start newTimes at the nicely aligned origin
        % from getSpanningTimeLimits plus a whole multiple of the time step
        dt = seconds(timeStep);
        tleft = tleft + seconds(floor(seconds(tmin-tleft)/dt)*dt);
        numRows = ceil((tmax - tleft)/timeStep) + 1;
        newTimes = matlab.internal.coder.tabular.private.rowTimesDim.regularRowTimesFromTimeStep(tleft,timeStep,numRows);
    else % calendarDuration
        % DEAD CODE: currently not supported
        assert(false);
    end
else % useSampleRate
    % Start newTimes on a whole second plus a whole multiple of the time step
    [tleft,~] = getSpanningTimeLimits(tmin,tmax,'secondly');
    tleft = tleft + seconds(floor(seconds(tmin-tleft)*sampleRate)/sampleRate);
    numRows = ceil(seconds(tmax - tleft)*sampleRate) + 1;
    newTimes = matlab.internal.coder.tabular.private.rowTimesDim.regularRowTimesFromSampleRate(tleft,sampleRate,numRows);
end

%-------------------------------------------------------------------------------
function [tleft,tright,timeStepDur] = getSpanningTimeLimits(tmin,tmax,timeStep)
% Given a choice of time step name and the min/max times of the data being synchronized,
% return nicely-aligned spanning time limits and the actual time step.
coder.internal.prefer_const(timeStep);
if isa(tmin,'datetime')
    % FIXME: wait until dateshift is supported
    %{
    switch lower(timeStep)
    case 'secondly',  timeStepName = 'second';  timeStepDur = seconds(1);
    case 'minutely',  timeStepName = 'minute';  timeStepDur = minutes(1);
    case 'hourly',    timeStepName = 'hour';    timeStepDur = hours(1);
    case 'daily',     timeStepName = 'day';     timeStepDur = caldays(1);
    case 'weekly',    timeStepName = 'week';    timeStepDur = calweeks(1);
    case 'monthly',   timeStepName = 'month';   timeStepDur = calmonths(1);
    case 'quarterly', timeStepName = 'quarter'; timeStepDur = calquarters(1);
    case 'yearly',    timeStepName = 'year';    timeStepDur = calyears(1);
    otherwise
        error(message('MATLAB:timetable:synchronize:UnknownNewTimeStep',timeStep));
    end
    % Choose newTimes to span the row times of the inputs, as the floor/ceil of
    % tmin/tmax w.r.t the specified unit, equal to tmin/tmax if that falls on a
    % whole unit.
    tleft = dateshift(tmin,'start',timeStepName); % floor
    tright = dateshift(tmax,'start',timeStepName); % first step in ceil
    if (tright < tmax)
        tright = tright + timeStep; % second step in ceil
    end
    %}
    lowerTimeStep = matlab.internal.coder.datatypes.partialMatch(timeStep,{'secondly','minutely','hourly','daily','weekly','monthly','quarterly','yearly'});
    switch lowerTimeStep
        case 'secondly'
            [~,~,~,~,~,tminseconds] = datevec(tmin);
            [~,~,~,~,~,tmaxseconds] = datevec(tmax);
            tleft = tmin - seconds(tminseconds - floor(tminseconds));
            tright = tmax + seconds(ceil(tmaxseconds) - tmaxseconds);
            timeStepDur = seconds(1);
        case 'minutely'
            [~,~,~,~,~,tminseconds] = datevec(tmin);
            [~,~,~,~,~,tmaxseconds] = datevec(tmax);
            tleft = tmin - seconds(tminseconds);  % floor
            tright = tmax - seconds(tmaxseconds);  % first step in ceil
            if (tright < tmax)
                tright = tright + minutes(1); % second step in ceil
            end
            timeStepDur = minutes(1);
        case 'hourly'
            [~,~,~,~,tminminutes,tminseconds] = datevec(tmin);
            [~,~,~,~,tmaxminutes,tmaxseconds] = datevec(tmax);
            tleft = tmin - minutes(tminminutes) - seconds(tminseconds);  % floor
            tright = tmax - minutes(tmaxminutes) - seconds(tmaxseconds);  % first step in ceil   
            if (tright < tmax)
                tright = tright + hours(1); % second step in ceil
            end
            timeStepDur = hours(1);
        case 'daily'
            [~,~,~,tminhours,tminminutes,tminseconds] = datevec(tmin);
            [~,~,~,tmaxhours,tmaxminutes,tmaxseconds] = datevec(tmax);
            tleft = tmin - hours(tminhours) - minutes(tminminutes) - seconds(tminseconds);  % floor
            tright = tmax - hours(tmaxhours) - minutes(tmaxminutes) - seconds(tmaxseconds);  % first step in ceil   
            % Use days instead of caldays since calendarDuration is not yet
            % supported in codegen. This is only acceptable as long as
            % time zones are not supported. caldays and days are not
            % identical in datetime with time zone.
            if (tright < tmax)
                tright = tright + days(1); % second step in ceil
            end
            timeStepDur = days(1);
        otherwise
            invalidForDatetime = strcmpi(lowerTimeStep, 'weekly') || ...
                strcmpi(lowerTimeStep, 'monthly') || ...
                strcmpi(lowerTimeStep, 'quarterly') || ...
                strcmpi(lowerTimeStep, 'yearly');
            coder.internal.errorIf(invalidForDatetime, ...
                'MATLAB:timetable:synchronize:UnsupportedNewTimeStepDatetime',timeStep)
            coder.internal.errorIf(~invalidForDatetime,...
                'MATLAB:timetable:synchronize:UnknownNewTimeStep',timeStep);
            % this code branch should always error. If error is deferred to
            % runtime, need to specify output to some default value to
            % satisfy coder at compile time
            tleft = tmin;
            tright = tmax;
            timeStepDur = seconds(0);
    end
else
    lowerTimeStep = matlab.internal.coder.datatypes.partialMatch(timeStep,{'secondly','minutely','hourly','daily','weekly','monthly','quarterly','yearly'});
    switch lowerTimeStep
        case 'secondly',  timeStepName = 'seconds';  timeStepDur = seconds(1);
        case 'minutely',  timeStepName = 'minutes';  timeStepDur = minutes(1);
        case 'hourly',    timeStepName = 'hours';    timeStepDur = hours(1);
        case 'daily',     timeStepName = 'days';     timeStepDur = days(1);
        case 'yearly',    timeStepName = 'years';    timeStepDur = years(1);       
        otherwise
            timeStepName = 'bogus';   % to satisfy coder that timeStepName is defined on all code branches
            invalidForDuration = strcmpi(lowerTimeStep, 'weekly') || ...
                strcmpi(lowerTimeStep, 'monthly') || ...
                strcmpi(lowerTimeStep, 'quarterly');
            coder.internal.errorIf(invalidForDuration, ...
                'MATLAB:timetable:synchronize:UnknownNewTimeStepDuration',timeStep)
            coder.internal.errorIf(~invalidForDuration,...
                'MATLAB:timetable:synchronize:UnknownNewTimeStep',timeStep);
    end
    % Choose newTimes to span the row times of the inputs. See comments above.
    tleft = floor(tmin,timeStepName);
    tright = ceil(tmax,timeStepName);
end


%-------------------------------------------------------------------------------
function [unit,timeStep] = getRegularTimeVectorAlignment(timeStep)
% Given a time step, return the time unit or calendar unit at which to align the
% "origin" for a regular time vector (the actual time vector will be offset by a
% multiple of the time step from that alignment). The time step is required to
% be positive. A calendarDuration time step is assumed to be "pure". If it is
% "pure time" it's transformed into a duration.
if isa(timeStep,'duration')
    dt = milliseconds(timeStep);
    coder.internal.assert(dt>0, 'MATLAB:timetable:synchronize:NonPositiveTimeStep');
    if dt <= 1000       %     0 < step <= 1 sec => secondly alignment
        unit = 'secondly';
    elseif dt <= 60*1000    % 1 sec < step <= 1 min => minutely alignment
        unit = 'minutely';
    elseif dt <= 60*60*1000 % 1 min < step <= 1 hr  => hourly alignment
        unit = 'hourly';
    else                    % 1 hr  < step          => daily alignment
        unit = 'daily';
    end
else  % calendarDuration -- currently not supported
    assert(false);
end

%-------------------------------------------------------------------------------
function [tmin,tmax] = getCommonTimeRange(timetableInputs,rangeType)
% Find the common time range of the timetable's tme vectors

coder.internal.prefer_const(rangeType);

% Get min/max times for each timetable - some may be empty and need to be
% propagated along so the 'all-empty' case flows through properly.
ntimetables = length(timetableInputs);
tminc = cell(1,ntimetables);
tmaxc = cell(1,ntimetables);
coder.unroll();
for i = 1:ntimetables
    % reshape needed when rowtimes are implicit and rowDim.labels is
    % computed at runtime and thus variable sized. The rowDimLength timetable 
    % method also inspects timetable data to determine number of rows. The 
    % reshaped vector is much more likely to be fix sized.
    currtimetable = timetableInputs{i};
    times = reshape(currtimetable.rowDim.labels,rowDimLength(currtimetable),1);
    % check for varsize empty and throw a runtime error
    coder.internal.errorIf(~coder.internal.isConst(numel(times)) && isempty(times), ...
        'MATLAB:timetable:synchronize:VarsizeEmpty');

    tminc{i} = min(times);
    tmaxc{i} = max(times);
end

% Expand and concatenate tmin/tmax. Empties will be ignored if at least one
% of the 'tmin/tmax's is non-empty; if all of tmin/tmax is empty, vertcat
% (correctly) returns empty to proprogate it along.
% vertcat: rowTimes are always column
tminv = vertcat(tminc{:});
tmaxv = vertcat(tmaxc{:});

switch rangeType
    case 'union' % the union of the ranges
        tmin = min(tminv);
        tmax = max(tmaxv);
    case 'intersection' % the intersection of the ranges
        tmin = max(tminv);
        tmax = min(tmaxv);
    otherwise
        assert(false);
end

%-------------------------------------------------------------------------------
function [newTimes,newData] = retimeIt(tt1,newTimes,methodinput,~,endValues,includedEdge,fillConstant,timesMinMax)
% Synchronize one timetable to a new time vector using the specified method
tt1_data = tt1.data;

if isa(methodinput,'function_handle') % allow the switch to control this case
    fun = methodinput;
    method = 'fun';
else
    method = matlab.internal.coder.datatypes.partialMatch(methodinput, ...
        {'default','fillwithmissing','fillwithconstant','previous','next','nearest','linear','spline', ...
         'pchip','makima','count','sum','mean','median','mode','prod','min','max','firstvalue','lastvalue','fun'});
end
    
switch method
case {'default' 'fillwithmissing'}
    % Find the correspondence between rows in the input and in the output by
    % matching up existing and new row times. Select the first among dup input
    % row times. copyTo is logical to allow easy negation; it says which output
    % rows will have input data copied into them. copyFromInds is indices to
    % preserve the order for a non-monotonic correspondence; it says which input
    % rows will be copied to the output.
    requireMissingAware(tt1,method);
    [copyTo,locs] = ismember(newTimes,tt1.rowDim.labels); % select the first among dups
    tt2_data = cell(1,length(tt1_data));
    coder.unroll();
    for j = 1:numel(tt2_data)
        var_j = tt1_data{j};
        szOut = size(var_j); szOut(1) = length(newTimes);
        numcols = prod(szOut(2:end));
        if iscell(var_j)
            % force homogeneous
            var_jc = var_j;
            if coder.ignoreConst(false) && ~isempty(var_jc)
                [~] = var_jc{coder.ignoreConst(1)};
            end
            tt2_dataj = matlab.internal.coder.datatypes.defaultarrayLike(szOut,'like',var_jc);
            for k = 1:numcols
                for i = 1:szOut(1)
                    if copyTo(i)
                        tt2_dataj{i,k} = var_jc{locs(i),k};
                    end
                end
            end
            tt2_data{j} = tt2_dataj;
        else
            % Initialize the output var with the same number of rows as the target
            % time vector, with the trailing size(s) of the input var, filled with
            % default values.
            tt2_data{j} = matlab.internal.coder.datatypes.defaultarrayLike(szOut,'like',var_j);
            % Copy data from the input var to matching rows in the output var, all
            % columns at once, leaving the other output rows as default values. This
            % might copy missing data, which is fine for fillWithMissing.
            for i = 1:szOut(1)
                if copyTo(i)
                    tt2_data{j}(i,:) = var_j(locs(i),:);
                end
            end
        end
    end

case 'fillwithconstant'
    % Find the correspondence between rows in the input and in the output by
    % matching up existing and new row times. Select the first among dup input
    % row times. copyTo is logical to allow easy negation; it says which output
    % rows will have input data copied into them: a "target row". copyFromInds
    % is indices to preserve the order for a non-monotonic correspondence; it
    % says which input rows will be copied to the output: a "source row". Both
    % of those may need to be thinned if the input data in a source row is
    % missing.
    [copyTo,locs] = ismember(newTimes,tt1.rowDim.labels); % select the first among dups
    tt2_data = cell(1,length(tt1_data));
    coder.unroll();
    for j = 1:numel(tt2_data)
        var_j = tt1_data{j};
        szOut = size(var_j); szOut(1) = length(newTimes);
        numcols = prod(szOut(2:end));
        missingMask = safeIsMissing(var_j);
        if iscell(var_j)
            % force homogeneous
            var_jc = var_j;
            if coder.ignoreConst(false) && ~isempty(var_jc)
                [~] = var_jc{coder.ignoreConst(1)};
            end
            tt2_dataj = coder.nullcopy(cell(szOut));
            for k = 1:numcols
                hasValue = ~missingMask(:,k);
                for i = 1:szOut(1)
                    if copyTo(i) && hasValue(locs(i))
                        tt2_dataj{i,k} = var_jc{locs(i),k};
                    else  % fill constant value
                        tt2_dataj{i,k} = fillConstant{1};
                    end
                end
            end
            tt2_data{j} = tt2_dataj;
        else
            % Initialize the output var with the same number of rows as the target
            % time vector, with the trailing size(s) of the input var, filled with
            % default values.
            tt2_data{j} = matlab.internal.coder.datatypes.defaultarrayLike(szOut,'like',var_j);
            % Copy data from the input var to rows with matching row times in the
            % output var, assigning the specified constant in elements of the output
            % var where the row time did not exist in the input.
            if any(missingMask,'all')
                for k = 1:numcols
                    % Copy only each column's non-missing data, fill the other
                    % elements. Treat input and output "as if" matrices. 
                    hasValue = ~missingMask(:,k);
                    for i = 1:szOut(1)
                        if copyTo(i) && hasValue(locs(i))
                            tt2_data{j}(i,k) = var_j(locs(i),k);
                        else
                            tt2_data{j}(i,k) = fillConstant;
                        end
                    end
                end
            else
                % No missing data, copy all data from the matching rows. The input
                % var might have one or more columns (including N-D), copy and fill
                % all at once.
                for i = 1:szOut(1)
                    if copyTo(i)
                        tt2_data{j}(i,:) = var_j(locs(i),:);
                    else
                        tt2_data{j}(i,:) = fillConstant;
                    end
                end
            end
        end
    end

case {'previous' 'next' 'nearest'}
    requireMonotonic(tt1.rowDim.labels,false,method); % don't require strictly monotonic
    % interp1 only works on numeric and datetime/duration. To support nearest
    % neighbor interpolation on other types, interpolate on the indices of the
    % data rather than on the data themselves. The actual data will be copied
    % from input to output based on which indices are selected.
    %
    % interp1 also does not allow repeated grid points. To support nearest neighbor
    % interpolation even when there are repeated row times, use the unique times and
    % let interp1 interpolate their indices, returning the appropriate member from
    % each group of repeats.
    
    % Initialize cache to hold interpolated indices when there is no missing data
    rowLocsCache = zeros(length(newTimes),1);
    isRowLocsCacheEmpty = true;
    
    tt1_time = tt1.rowDim.labels;
    tt2_data = cell(1,length(tt1_data));
    coder.unroll();
    for j = 1:numel(tt2_data)
        t = tt1_time;
        var_j = tt1_data{j};
        szOut = size(var_j); szOut(1) = length(newTimes);
        numcols = prod(szOut(2:end));
        missingMask = safeIsMissing(var_j);
        hasMissing = any(missingMask,'all');
        if iscell(var_j)
            var_jc = var_j;
            if coder.ignoreConst(false) && ~isempty(var_jc)
                [~] = var_jc{coder.ignoreConst(1)};
            end
            if ~coder.internal.isConst(hasMissing) || hasMissing
                tt2_dataj = coder.nullcopy(cell(szOut));
                for k = 1:numcols
                    nonMissing_k = ~missingMask(:,k);
                    t_k = t(nonMissing_k);
                    nonMissingIdx_k = find(nonMissing_k);
                    v_k = coder.nullcopy(cell(length(nonMissingIdx_k),1));
                    for i = 1:length(nonMissingIdx_k)
                        v_k{i} = var_jc{nonMissingIdx_k(i),k};
                    end
                    tt2_datajk = nnbrInterp1Local(t_k,v_k,newTimes,method,endValues,true);
                    for i = 1:szOut(1)
                       tt2_dataj{i,k} = tt2_datajk{i};
                    end
                end
                tt2_data{j} = tt2_dataj;
            else
                [tt2_data{j},rowLocsCache] = nnbrInterp1Local(t,var_jc,newTimes,method,endValues,isRowLocsCacheEmpty,rowLocsCache);
                isRowLocsCacheEmpty = false;
            end
        else
            if ~coder.internal.isConst(hasMissing) || hasMissing
                % Create the output var with the same number of rows as the target
                % time vector, with the trailing size(s) of the input var, filled
                % with default values.
                tt2_data{j} = matlab.internal.coder.datatypes.defaultarrayLike(szOut,'like',var_j);
                for k = 1:numcols
                    % Interpolate for each column on non-missing data only. Treat
                    % input and output "as if" matrices.
                    nonMissing_k = ~missingMask(:,k);
                    t_k = t(nonMissing_k);
                    v_k = var_j(nonMissing_k,k);
                    tt2_data{j}(:,k) = nnbrInterp1Local(t_k,v_k,newTimes,method,endValues,true);
                end
            else
                % The input var might have one or more columns (including N-D),
                % interpolate all at once. Save work by reusing the source and
                % target row locations for vars that don't have missing data.
                [tt2_data{j},rowLocsCache] = nnbrInterp1Local(t,var_j,newTimes,method,endValues,isRowLocsCacheEmpty,rowLocsCache);
                isRowLocsCacheEmpty = false;
            end
        end
    end

case {'linear' 'spline' 'pchip' 'makima'}
    requireNumeric(tt1,1,method);
    requireMonotonic(tt1.rowDim.labels,true,method); % require strictly monotonic
    t = tt1.rowDim.labels;
    tt2_data = cell(1,numel(tt1_data));
    coder.unroll();
    for j = 1:numel(tt2_data)
        var_j = tt1_data{j};
        ndimsOut = coder.internal.ndims(var_j); % don't use ndims, may not be constant
        szOut = [length(newTimes) size(var_j,2:ndimsOut)];
        numcols = prod(szOut(2:end));
        missingMask = safeIsMissing(var_j); % requireNumeric() doesn't guarantee that ismissing() won't error
        if any(missingMask,'all')
            % Create the output var with the same number of rows as the
            % target time vector, with the trailing size(s) of the input
            % var, filled with default values.
            tt2_data{j} = matlab.internal.coder.datatypes.defaultarrayLike(szOut,'like',var_j);
            for k = 1:numcols
                % Interpolate for each column on non-missing data only.
                % Treat input and output "as if" matrices.
                nonMissing_k = ~missingMask(:,k);
                t_k = t(nonMissing_k);
                v_k = var_j(nonMissing_k,k);
                tt2_data{j}(:,k) = interp1Local(t_k,v_k,newTimes,method,endValues);
            end
        else
            % The input var might have one or more columns (including N-D),
            % interpolate all at once when there's no missing data to remove.
            tt2_data{j} = interp1Local(t,var_j,newTimes,method,endValues);
        end
    end

    case {'count' 'sum' 'mean' 'median' 'mode' 'prod' 'min' 'max' 'firstvalue' 'lastvalue' 'fun'}
    % For aggregation, get the name of a user-supplied function, or the actual
    % function corresponding to a method name, depending on what's still needed.
    isUserFun = (method == "fun");
    if isUserFun
        % No checks on the data variables for a user-supplied function, it may error.
        methodname = func2str(fun);
    else
        % str2funcLocal also checks the data type using requireNumeric at
        % various levels of strictness for 'sum', 'mean', 'prod', 'min', and
        % 'max', or using requireMonotonic for 'firstValue' and 'lastValue (no
        % check for 'count').
        fun = str2funcLocal(tt1,method);
        methodname = method;
    end
    
    % The target time vector has already been checked for monotonicity, but
    % aggregation requires increasing time.
    coder.internal.errorIf((length(newTimes) > 1) && (newTimes(1) > newTimes(2)), ...
        'MATLAB:timetable:synchronize:DecreasingNewTimesForAggregation',methodname);
    
    ngroups = length(newTimes)-1;
    if ngroups >= 1
        % groupIdx = discretize(tt1.rowDim.labels,newTimes,'IncludedEdge',includedEdge);        
        groupIdx = nan(numel(tt1.rowDim.labels),1);
        if includedEdge == "left"
            for i = 1:numel(newTimes)-1
                groupIdx(tt1.rowDim.labels >= newTimes(i) & tt1.rowDim.labels < newTimes(i+1)) = i;
            end
        else
            for i = 1:numel(newTimes)-1
                groupIdx(tt1.rowDim.labels > newTimes(i) & tt1.rowDim.labels <= newTimes(i+1)) = i;
            end
        end
            
        % Patch up discretize groups to add the degenerate bin to the end of the output
        % timetable. The degenerate bin only includes data from the input times that are an
        % exact match.  There is no degenerate bin if using 'minutely', etc. and the last bin
        % spans the data. If the time vector is manually specified, that last degenearate bin
        % will be filled with missing values if there are no exact time matches.
        if includedEdge == "left"
            if ~isempty(timesMinMax) && timesMinMax(end) < newTimes(end) % doing 'minutely'... and max time isn't on the bin edge.
                % For aggregation using a newTimeStep (determined by timesMinMax being non-empty),
                % one of the bin edges has to be at the next/prev whole unit beyond tmax/tmin of the
                % input time vectors (which one depends on IncludedEdge).
                % If tmax falls between whole units, the ceil is already at the next whole unit, so
                % dispose of the extra bin.
                newTimes = newTimes(1:end-1);
            else
                % Assign a group index to the degenerate bin either if:
                % 1) the newTimes come from a time vector or time basis (e.g. 'union'), or
                % 2) the newTimes come from a time step (e.g. 'hourly') and the tmax matches the last
                %    bin edge in newTimes, then keep it as a degenerate bin.
                ngroups = ngroups + 1;
                groupIdx(tt1.rowDim.labels == newTimes(end)) = ngroups;
            end
        else % strcmp(includedEdge, 'right')
            if ~isempty(timesMinMax) && timesMinMax(1) > newTimes(1) % doing 'minutely'... and min time isn't on the bin edge.
                % dispose of extra bin.
                newTimes = newTimes(2:end);
            else % assign groupIdx to degenerate bin
                ngroups = ngroups + 1;
                groupIdx(tt1.rowDim.labels == newTimes(1)) = 0;
                % groupIdx must cannot include 0 for indexing.
                groupIdx = groupIdx + 1;
            end
        end
    else % For a scalar newTimes, use logical indexing rather than discretize.
        groupIdx = nan(numel(tt1.rowDim.labels),1);
        if ~isempty(newTimes) % no degenerate bin for empty output timetable case
            % create a group and assign it to the rows where the times match the (scalar)
            % newTimes.
            ngroups = 1;
            groupIdx(tt1.rowDim.labels == newTimes) = 1;
        end
    end

    tt2_data = groupedApply(groupIdx,max(ngroups,0),tt1_data,tt1.varDim.labels,fun,methodname,isUserFun);
    
otherwise
    assert(false);
end
newData = tt2_data;


%-------------------------------------------------------------------------------
function b_data = groupedApply(groupIdx,ngroups,a_data,~,fun,funName,isUserFun)
% Apply a function to each variable by group. Similar to the grouped, table
% output case in varfun, but here the output includes rows for groups that are
% not present in the data, so the function should be prepared to accept a
% possibly empty input.
grprows = matlab.internal.coder.datatypes.getGroups(groupIdx,ngroups);

ndataVars = length(a_data);

% Each cell will contain the result from applying FUN to one variable,
% an ngroups-by-.. array with one row for each group's result
b_data = cell(1,ndataVars);

for jvar = 1:ndataVars
    
    % Each cell will contain the result from applying FUN to one group
    % within the current variable
    outVals = coder.nullcopy(cell(ngroups,1));
    
    var_j = a_data{jvar};
    for igrp = 1:ngroups
        inArg = getVarRows(var_j,grprows{igrp});
        outVal = fun(inArg);
        coder.internal.assert(size(outVal,1) == 1, ...
            'MATLAB:timetable:synchronize:FunMustReturnOneRow',funName);
        outVals{igrp} = outVal;
    end
    
    % vertcat the results from the current var, checking that each group has the
    % same number of rows as it did in the other vars
    if ngroups > 0 || (isUserFun && ~coder.internal.isConst(ngroups))
        % throw a runtime error if method is a function handle and there are no groups
        coder.internal.errorIf(isUserFun && ngroups == 0, ...
            'MATLAB:timetable:synchronize:CustomAggregationReturnsEmpty');
        if iscell(outVals{1})
            sz = size(outVals{1});
            sz(1) = numel(outVals);
            b_data_jvar = cell(sz);
            for i = 1:numel(outVals)
                for j = 1:prod(sz(2:end))
                    b_data_jvar{i,j} = outVals{i}{j};
                end
            end
            b_data{jvar} = b_data_jvar;
        else
            if coder.internal.isConst(numel(outVals))  % can only turn outVals into a list if fixed length
                b_data{jvar} = vertcat(outVals{:});
            else
                sz1 = size(outVals{1});
                % determine output size
                szall = sz1; 
                for i = 2:numel(outVals)
                    szall(1) = szall(1) + size(outVals{i},1);
                end
                % populate output
                b_data{jvar} = matlab.internal.coder.datatypes.defaultarrayLike(szall,'like',outVals{1});
                idx = 1;
                for i = 1:numel(outVals)
                    szcurr = size(outVals{i},1);
                    b_data{jvar}(idx:idx+szcurr-1, :) = outVals{i}(:,:);
                    idx = idx + szcurr;
                end
            end
        end
    else
        % If there are no groups, there may be three situations: 
        % 1) 'Count' returns empty doubles, the width of the input variable. 
        % 2) It's a canned function other than 'count', so we know it should returns empties
        %    the same type and size as the input variables.
        % 3) The user function has not been applied to anything, so no way to know what type
        %    and size fun would return. Default to empty double of the same width as the input var.
        sz = size(a_data{jvar});
        sz(1) = 0; % 0 rows, but can otherwise be N-D.
        if (funName == "count") || isUserFun || ... % (1) and (3)
                (islogical(a_data{jvar}) && (funName == "sum" || funName == "mean" || funName == "prod"))
            b_data{jvar} = zeros(sz);
        else % (2)
            b_data{jvar} = matlab.internal.coder.datatypes.defaultarrayLike(sz,'like',a_data{jvar});
        end
    end
end


%-------------------------------------------------------------------------------
function var_ij = getVarRows(var_j,i)
% Extract rows of a variable, regardless of its dimensionality and type
if iscell(var_j)    
    sizeOut = size(var_j); sizeOut(1) = numel(i);
    var_ij = coder.nullcopy(cell(sizeOut));
    % force input to be homogeneous, because number of rows to extract may
    % be nonconstant, which makes the loop indices to be nonconstant
    var_j_homogeneous = var_j;
    if coder.internal.isConst(size(var_j))
        coder.varsize('var_j_homogeneous', [], false(1,ndims(var_j)));
    end
    ncols = prod(sizeOut(2:end));
    for k = 1:ncols
        for j = 1:numel(i)
            var_ij{j,k} = var_j_homogeneous{i(j),k};
        end
    end
else
    if ismatrix(var_j)
        var_ij = var_j(i,:); % without using reshape, may not have one
    else
        % Each var could have any number of dims, no way of knowing,
        % except how many rows they have.  So just treat them as 2D to get
        % the necessary rows, and then reshape to their original dims.
        sizeOut = size(var_j); sizeOut(1) = numel(i);
        var_ij = reshape(var_j(i,:), sizeOut);
    end
end

%-------------------------------------------------------------------------------
function fun = str2funcLocal(tt,method)
% Convert a method input argument into a function handle, with some pre-checks
% on the data it will be applied to
coder.internal.prefer_const(method);
switch method
case 'count'
    fun = @countLocal;
case 'mean'
    requireNumeric(tt,1,method);
    fun = @meanLocal;
case 'median'
    requireNumeric(tt,0,method);
    fun = @medianLocal;
case 'mode'
    requireNumeric(tt,0,method);
    fun = @modeLocal;
case 'sum'
    requireNumeric(tt,2,method);
    fun = @sumLocal;
case 'prod'
    requireNumeric(tt,3,method);
    fun = @prodLocal;
case 'min'
    requireNumeric(tt,0,method);
    fun = @minLocal;
case 'max'
    requireNumeric(tt,0,method);
    fun = @maxLocal;
case 'firstvalue'
    requireMonotonic(tt.rowDim.labels,false,method); % don't require strictly monotonic
    fun = @firstvalueLocal;
case 'lastvalue'
    requireMonotonic(tt.rowDim.labels,false,method); % don't require strictly monotonic
    fun = @lastvalueLocal;
otherwise
    assert(false);
end


%-------------------------------------------------------------------------------
function requireNonMissing(times)
% Require a target time vector to not have missing values
coder.internal.errorIf(coder.internal.vAllOrAny('any', times, @ismissing), ...
    'MATLAB:timetable:synchronize:NotMonotonicNewTimes');


%-------------------------------------------------------------------------------
function requireMonotonic(times,strict,method)
% Require a target time vector (nargin==2) or the time vector from an input
% timetable (nargin==3) to be monotonically increasing or decreasing.
coder.internal.prefer_const(method);
if numel(times) > 1
    d = times(2)-times(1);
    if strict
        if nargin < 3
            coder.internal.assert(d > 0 || d < 0, 'MATLAB:timetable:synchronize:NotUniqueNewTimes');
        else
            coder.internal.assert(d > 0 || d < 0, 'MATLAB:timetable:synchronize:NotUnique',method);
        end
        for i = 2:numel(times)-1
            dnew = times(i+1)-times(i);
            % do not use first branch if method input is not constant but
            % data is constant, because we may try to throw a compile time
            % error
            if nargin < 3 || (~coder.internal.isConst(method) && coder.internal.isConst(dnew))
                coder.internal.assert(dnew > 0 || dnew < 0, 'MATLAB:timetable:synchronize:NotUniqueNewTimes');
                coder.internal.assert((dnew > 0) == (d > 0), 'MATLAB:timetable:synchronize:NotMonotonicNewTimes');
            else
                coder.internal.assert(dnew > 0 || dnew < 0, 'MATLAB:timetable:synchronize:NotUnique', method);
                coder.internal.assert((dnew > 0) == (d > 0), 'MATLAB:timetable:synchronize:NotMonotonic', method);
            end
            d = dnew;
        end
    else
        for i = 2:numel(times)-1
            dnew = times(i+1)-times(i);
            if nargin < 3
                coder.internal.assert((dnew >= 0) == (d >= 0), 'MATLAB:timetable:synchronize:NotMonotonicNewTimes');
            else
                coder.internal.assert((dnew >= 0) == (d >= 0), 'MATLAB:timetable:synchronize:NotMonotonic', method);
            end
            if dnew ~= 0
                d = dnew;
            end
        end
    end
end


%-------------------------------------------------------------------------------
function requireNumeric(tt,strictness,method)
% Require all variables in an input timetable to be numeric-like to some degree
coder.internal.prefer_const(strictness);
ttdata = tt.data;
switch strictness
case 0
    % Require all variables to be "numeric-like" in the sense that they are ordered, so
    % support min/max/mode/median
    for i = 1:numel(ttdata)
        ttdatai = ttdata{i};
        if matches(method,'mode')
             % Mode does not require the categorical to be ordinal
            coder.internal.assert(isnumeric(ttdatai) || islogical(ttdatai) || isa(ttdatai, 'datetime') || ...
                isa(ttdatai, 'duration') || isa(ttdatai, 'categorical'), ...
                'MATLAB:timetable:synchronize:NotNumeric0Mode',method);
        else
            coder.internal.assert(isnumeric(ttdatai) || islogical(ttdatai) || isa(ttdatai, 'datetime') || ...
                isa(ttdatai, 'duration') || (isa(ttdatai, 'categorical') && isordinal(ttdatai)), ...
                'MATLAB:timetable:synchronize:NotNumeric0',method);
        end
    end    
case 1
    % Require all variables to be "numeric-like", and have mean/min/max methods as
    % well as support interpolation
    for i = 1:numel(ttdata)
        ttdatai = ttdata{i};
        coder.internal.assert(isnumeric(ttdatai) || (matches(method,'mean') && islogical(ttdatai)) || isa(ttdatai, 'datetime') || ...
            isa(ttdatai, 'duration'), 'MATLAB:timetable:synchronize:NotNumeric1',method);
    end    
case 2
    % Require all variables to be even more "numeric-like", and have a sum
    % method as well
    for i = 1:numel(ttdata)
        ttdatai = ttdata{i};
        coder.internal.assert(isnumeric(ttdatai) || islogical(ttdatai) || isa(ttdatai, 'duration'), ...
            'MATLAB:timetable:synchronize:NotNumeric2',method);
    end    
case 3
    % Require all variables to be strictly numeric
    for i = 1:numel(ttdata)
        ttdatai = ttdata{i};
        coder.internal.assert(isnumeric(ttdatai) || islogical(ttdatai), ...
            'MATLAB:timetable:synchronize:NotNumeric3',method);
    end    
otherwise
    assert(false);
end


%-------------------------------------------------------------------------------
function requireMissingAware(tt,method)
% Require all variables in an input timetable to have some standard way to represent missing values
ttdata = tt.data;
coder.unroll();
for i = 1:numel(ttdata)
    x = ttdata{i};
    coder.internal.assert(isfloat(x) || isa(x,'categorical') ...
        || isa(x,'datetime') || isa(x,'duration') || isa(x,'calendarDuration') ...
        || matlab.internal.coder.datatypes.isText(x,true) ...
        || (ischar(x) && ismatrix(x)), 'MATLAB:timetable:synchronize:NotMissingAware',method);
end


%-------------------------------------------------------------------------------
% "Canned" methods that omit missing values automatically. In cases that
% explicitly use ismissing, recover from an error by assuming all values are
% non-missing. 
function y = countLocal(x)
y = sum(~safeIsMissing(x),1);
%-------------------------------------------------------------------------------
function y = sumLocal(x)
y = sum(x,1,'omitnan');
%-------------------------------------------------------------------------------
function y = prodLocal(x)
y = prod(x,1,'omitnan');
%-------------------------------------------------------------------------------
function y = meanLocal(x)
y = mean(x,1,'omitnan');
%-------------------------------------------------------------------------------
function y = medianLocal(x)
y = median(x,1,'omitnan');
%-------------------------------------------------------------------------------
function y = modeLocal(x)
y = mode(x,1);
%-------------------------------------------------------------------------------
function y = minLocal(x)
if size(x,1) > 0
    y = min(x,[],1,'omitnan');
else
    sz = size(x); sz(1) = 1;
    y = matlab.internal.coder.datatypes.defaultarrayLike(sz,'like',x);
end
%-------------------------------------------------------------------------------
function y = maxLocal(x)
if size(x,1) > 0
    y = max(x,[],1,'omitnan');
else
    sz = size(x); sz(1) = 1;
    y = matlab.internal.coder.datatypes.defaultarrayLike(sz,'like',x);
end
%-------------------------------------------------------------------------------
function y = firstvalueLocal(x)
% Use a for loop to populate sz. For some reason, just getting size(x) and
% changing first element to 1 results in sz being nonconstant
% and Coder failing to understand all elements of the output cell are
% filled. Same for sz = [1 size(x,2:ndims(x))]
sz = coder.nullcopy(zeros(1,numel(size(x))));
sz(1) = 1;
numcols = 1;
coder.unroll();
for i = 2:numel(sz)
    sz(i) = size(x,i);
    numcols = numcols * sz(i);
end
% sz = size(x); sz(1) = 1;
% numcols = coder.const(prod(sz(2:end)));
missingMask = safeIsMissing(x);
if iscell(x)
    y = matlab.internal.coder.datatypes.defaultarrayLike(sz,'like',x);
    if size(x,1) > 0
        for j = 1:numcols
            hasValue = ~missingMask(:,j);
            for i = 1:size(x,1)
                if hasValue(i)
                    y{j} = x{i,j};
                    break;
                end
            end
        end
    end
else
    y = matlab.internal.coder.datatypes.defaultarrayLike(sz,'like',x);
    if size(x,1) > 0
        for j = 1:numcols
            hasValue = ~missingMask(:,j);
            for i = 1:size(x,1)
                if hasValue(i)
                    y(1,j) = x(i,j);
                    break;
                end
            end
        end
    end
end
%-------------------------------------------------------------------------------
function y = lastvalueLocal(x)
% Use a for loop to populate sz. For some reason, just getting size(x) and
% changing first element to 1 more likely results in sz being nonconstant
% and Coder failing to understand all elements of the output cell are
% filled. Same for sz = [1 size(x,2:ndims(x))]
sz = coder.nullcopy(zeros(1,numel(size(x))));
sz(1) = 1;
numcols = 1;
coder.unroll();
for i = 2:numel(sz)
    sz(i) = size(x,i);
    numcols = numcols * sz(i);
end
% sz = size(x); sz(1) = 1;
% numcols = coder.const(prod(sz(2:end)));
missingMask = safeIsMissing(x);
if iscell(x)
    y = matlab.internal.coder.datatypes.defaultarrayLike(sz,'like',x);
    if size(x,1) > 0
        for j = 1:numcols
            hasValue = ~missingMask(:,j);
            for i = size(x,1):-1:1
                if hasValue(i)
                    y{j} = x{i,j};
                    break;
                end
            end
        end
    end
else
    y = matlab.internal.coder.datatypes.defaultarrayLike(sz,'like',x);
    if size(x,1) > 0
        for j = 1:numcols
            hasValue = ~missingMask(:,j);
            for i = size(x,1):-1:1
                if hasValue(i)
                    y(1,j) = x(i,j);
                    break;
                end
            end
        end
    end
end


%-------------------------------------------------------------------------------
function tf = safeIsMissing(x)
% struct and cell do not support ismissing, defaults to not missing
% An exception is cellstr, for which ismissing is supported. isConst check 
% necessary when checking for cellstr because iscellstr is nonconstant if input is
% variable sized cell array of nonchar type
if isstruct(x) || (iscell(x) && ~(coder.internal.isConst(iscellstr(x)) && iscellstr(x))) %#ok<ISCLSTR>
    tf = false(size(x,1),1);
else
    tf = ismissing(x);
end


%-------------------------------------------------------------------------------
function [vq,rowLocsCache] = nnbrInterp1Local(t,v,tq,method,endValues,createRowLocs,rowLocsCache)
% A local version of interp1 that supports nearest-neighbor interpolation with
% non-numeric data.

% 'extrap' must be constant, but the fill value for extrapolation need only be
% a scalar with constant size. This is enforced in input processing.
defaultExtrap = coder.internal.isConst(endValues) && strcmp(endValues,"extrap"); % use strcmp: endValues may be non-text

% For 'extrap', rely on interp1 to do next/prev/nearest extrapolation on the
% indices (or return NaN where it can't), otherwise tell it to just flag the
% locations where it would have to extrapolate with NaNs.
if ~coder.internal.isConst(createRowLocs) || createRowLocs
    if method == "previous"
        % Interpolate to find the index of the previous grid point for each query point.
        % In each group of repeated grid points, get the last one, to make 'previous'
        % continuous from the right.
        [ut,iut] = unique(t,'last');
        if defaultExtrap
            rowLocs = interp1Local(ut,iut,tq,method,'extrap');
        else
            % NaN extrapolation value for the INDICES, not the data
            rowLocs = interp1Local(ut,iut,tq,method,NaN);
        end
    elseif method == "next"
        % Interpolate to find the index of the next grid point for each query point.
        % In each group of repeated grid points, get the first one, to make 'next'
        % continuous from the left.
        [ut,iut] = unique(t,'first');
        if defaultExtrap
            rowLocs = interp1Local(ut,iut,tq,method,'extrap');
        else
            % NaN extrapolation value for the INDICES, not the data
            rowLocs = interp1Local(ut,iut,tq,method,NaN);
        end
    else % 'nearest'
        % Find the first in each group of duplicate grid points.
        [ut,itFirst] = unique(t,'first');
        % Find the last in each group of duplicate grid points.
        [~,itLast] = unique(t,'last');
        % Find the index of the nearest unique grid point for each query point.
        if defaultExtrap
            iut = interp1Local(ut,(1:length(ut))',tq,method,'extrap');
        else
            % NaN extrapolation value for the INDICES, not the data
            iut = interp1Local(ut,(1:length(ut))',tq,method,NaN);
        end
        if defaultExtrap && ~isempty(ut)
            % For 'extrap', interp1 using 'nearest' on a non-empty grid returns
            % valid indices everywhere in iut.
            nearestUt = ut(iut,1); % ,1 avoids Coder:FE:PotentialVectorVector for one row
        else
            % Otherwise, interp1 returns NaNs in iut to indicate extrapolation, set
            % things up so that locs is also NaN in those elements.
            nearestUt = matlab.internal.coder.datatypes.defaultarrayLike(size(iut),'like',ut);
            idxNonNaN = ~isnan(iut);
            nearestUt(idxNonNaN) = ut(iut(idxNonNaN),1); % ,1 avoids Coder:FE:PotentialVectorVector for one row
        end
        
        % Return the first in each group of duplicate grid points for query points that
        % are smaller than their nearest grid point, and the last in each group of
        % duplicate grid points for query points that are larger than their nearest grid
        % point.
        rowLocs = nan(size(tq));
        useFirst = (tq <= nearestUt);
        rowLocs(useFirst) = itFirst(iut(useFirst));
        useLast = (tq > nearestUt);
        rowLocs(useLast) = itLast(iut(useLast));
    end
    
    % Return the row locations for reuse if requested.
    if nargout == 2
        for i = 1:length(tq)
            rowLocsCache(i) = rowLocs(i);
        end
    end
else
    % When there are no missing values in this var, the cached source/target row
    % locs from previous vars can be reused (if present).
    rowLocs = rowLocsCache;
end
targetLocs = isfinite(rowLocs);   % locations where interp1 did NOT extrapolate
sourceLocs = rowLocs(targetLocs); % corresponding query points

% Using 'extrap' told interp1 to use 'next'/'prev'/'nearest' for extrapolation,
% and interp1 returns NaNs for extrapolation to the left with 'prev', and to the
% right for 'next'. Anywhere loc is non-NaN is where real data goes, anywhere
% else is left as a default value from defaultarrayLike. If endValues was
% specified as a value, interp1 used NaN for _all_ extrapolation, so anywhere
% loc is NaN is where the specified endValue has to go.
szOut = size(v); szOut(1) = length(tq); % output size for j-th var
numcols = prod(szOut(2:end));
if iscell(v)
    vq = coder.nullcopy(cell(szOut));
    % By now it's either constant 'extrap', or an end value. Also know by now the
    % latter is scalar, but check that it's a cell.
    coder.internal.assert(defaultExtrap || iscell(endValues), ...
        'MATLAB:timetable:synchronize:NonconstantEndValuesCell');
    if defaultExtrap
        extrapVal = matlab.internal.coder.datatypes.defaultarrayLike([1 1],'like',v);
    else
        extrapVal = endValues;
    end
    for i = 1:szOut(1)
        if targetLocs(i)
            for k = 1:numcols
                vq{i,k} = v{rowLocs(i),k};
            end
        else
           for k = 1:numcols
               vq{i,k} = extrapVal{1}; % would not compile for non-constant 'extrap' or non-cell endValues
           end
        end
    end
else
    vq = matlab.internal.coder.datatypes.defaultarrayLike(szOut,'like',v);
    vq(targetLocs,:) = v(sourceLocs,:);
    if ~defaultExtrap
        vq(~targetLocs,:) = endValues; % would not compile for non-constant 'extrap'
    end
end


%-------------------------------------------------------------------------------
function vq = interp1Local(x,v,xq,method,endValues)
% A local version of interp1 that supports interpolation with zero or one data
% points. If v does not support missing (or the extrap value), this may error,
% which the caller must handle.
%
% Assumes x and xq are column vectors, and v is a column vector or a
% column-oriented array. Does not support interp1(v,xq,...)
%
% interp1Local is used for the interpolation methods and the nearest
% neighbor methods. Interpolation methods are only supported for numeric
% and numeric-like variables (duration, datetime). The nearest neighbor
% methods pass in indices, not values. So it is safe to assume v/vq can be
% indexed using parentheses (No cell array indexing necessary)

% 'extrap' must be constant, but the fill value for extrapolation need only be
% a scalar with constant size. This is enforced in input processing.
defaultExtrap = coder.internal.isConst(endValues) && strcmp(endValues,"extrap"); % use strcmp: endValues may be non-text

% This code can be messy for variable sized timetables, because all 3
% branches (empty, scalar, general) will be compiled. It may be easy to run
% into some incompatibilities between the branches. We are not seeing
% problems so keeping it this way. If problems appear, consider making the
% empty and scalar branches for fixed size only. But that would introduce a
% limitation to exclude run-time empties and scalars.
if isempty(x) % v is 0x...
    % Preallocate the extrapolation fill value the correct type.
    extrap = matlab.internal.coder.datatypes.defaultarrayLike([1 1], 'like', v);
    if ~defaultExtrap
        % Convert the specified (known scalar) fill value to the output type.
        extrap(1) = endValues; % would not compile for non-constant 'extrap'
    end
    % Create an array of v's type, xq's height, v's width/etc, containing the
    % default or specified extrapolation fill value.
    ndimsv = coder.internal.ndims(v);
    outSz = [length(xq) size(v,2:ndimsv)];
    vq = repmat(extrap,outSz);
elseif isscalar(x) % v is 1x...
    if defaultExtrap
        extrap = matlab.internal.coder.datatypes.defaultarrayLike([1 1], 'like', v);
    else
        extrap = endValues;
    end
    % Create an array of v's type, xq's height, v's width/etc, containing
    % replicates of v's one row (or slice)
    % Use coder.internal.ndims(v) instead of ndims(v), ndims can return
    % nonconstant output if input is ND and variable sized
    ndimsv = coder.internal.ndims(v);
    repSz = [numel(xq) ones(1,ndimsv-1)];
    outSz = [numel(xq) size(v,2:ndimsv)];
    vq = matlab.internal.coder.datatypes.defaultarrayLike(outSz, 'like', v);
    vq(:) = repmat(v, repSz);
    switch method
    case 'next'
        % Leave the value from v in query points LE than x, assign the extrap
        % value to query points GT x, and to missing query points
        % Note indexing into the first (only) element of x is needed to
        % make the RHS of the comparison fix size scalar. Otherwise, with
        % both xq and x variable sized, Coder may not understand the need
        % to scalar expand.
        vq(~(xq <= x(1)),:) = extrap;
    case 'previous'
        % Leave the value from v in query points GE than x, assign the extrap
        % value to query points LT x, and to missing query points
        vq(~(xq >= x(1)),:) = extrap;
    case 'nearest'
        % Leave the value from v everywhere
    otherwise % spline-like, linear/spline/pchip/makima
        vq(xq ~= x(1),:) = extrap;
    end
else
    vq = interp1(x,v,xq,method,endValues);
end


%-------------------------------------------------------------------------------
function tt = noCheckInit(vars,rowTimes,varDim,metaDim)
tt = timetable(matlab.internal.coder.datatypes.uninitialized);
tt.rowDim = matlab.internal.coder.tabular.private.explicitRowTimesDim(length(rowTimes),rowTimes);
tt.varDim = varDim;
tt.metaDim = metaDim;
tt.data = vars;


%-------------------------------------------------------------------------------
function tt = noCheckInitRegular(vars,numRows,startTime,timeStep,sampleRate,varDim,metaDim)
tt = timetable(matlab.internal.coder.datatypes.uninitialized);
[makeImplicit,rowTimes] = matlab.internal.coder.tabular.private.implicitRegularRowTimesDim.implicitOrExplicit(numRows,startTime,timeStep,sampleRate);
if ~coder.internal.isConst(makeImplicit) || makeImplicit
    coder.internal.assert(makeImplicit, 'MATLAB:timetable:synchronize:CannotBeImplicit');
    tt.rowDim = matlab.internal.coder.tabular.private.implicitRegularRowTimesDim(numRows,startTime,timeStep,sampleRate);
else
    tt.rowDim = matlab.internal.coder.tabular.private.explicitRowTimesDim(length(rowTimes),rowTimes);
end
tt.varDim = varDim;
tt.metaDim = metaDim;
tt.data = vars;
