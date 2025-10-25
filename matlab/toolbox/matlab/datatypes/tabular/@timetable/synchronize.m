function ttOut = synchronize(varargin)
%

%   Copyright 2016-2024 The MathWorks, Inc.

import matlab.internal.datatypes.getChoice
import matlab.internal.datatypes.isScalarText
import matlab.internal.datatypes.partialMatch

try %#ok<ALIGN>

% Count the number of timetable inputs, get their workspace names, and make sure they all
% have the same kind of time vector.
timetableInputNames = cell(1,nargin);
ntimetables = 0;
haveDurations = false;
for i = 1:nargin
    if ~isa(varargin{i},'timetable'), break; end
    ntimetables = i;
    timetableInputNames{i} = inputname(i);
    
    if isa(varargin{i}.rowDim.labels,'duration') ~= haveDurations
        if ntimetables > 1
            error(message('MATLAB:timetable:synchronize:MixedTimeTypes'));
        else
            haveDurations = true;
        end
    end
end
timetableInputs = varargin(1:ntimetables);
timetableInputNames = timetableInputNames(1:ntimetables);

endValues = 'extrap';
includedEdge = 'left';
fillConstant = 0;
isAggregation = false;
isMethodProvided = false;
method = 'default';
createAsRegular = false;

if ntimetables == 0
    error(message('MATLAB:timetable:synchronize:NonTimetableInput'));
elseif nargin == ntimetables
    % Sync to the union of the time vectors, fill unmatched rows with missing
    [newTimes,timesMinMax] = processNewTimesInput('union',timetableInputs);
    copyFirstLastInput = [false false];
elseif nargin == ntimetables + 1
    % Sync to the specified time vector, fill unmatched rows with missing
    newTimesArg = varargin{ntimetables+1};
    [newTimes,timesMinMax,isRegular] = processNewTimesInput(newTimesArg,timetableInputs);
    if isRegular
        % 'regular' requires additional parameters
        error(message('MATLAB:timetable:synchronize:RegularWithoutParams'));
    end
    copyFirstLastInput = strcmp(newTimes,["first" "last"]); %newTimes could be non-text
else % nargin >= ntimetables + 2
    % Sync to the specified time vector.
    newTimesArg = varargin{ntimetables+1};
    [newTimes,timesMinMax,createAsRegular] = processNewTimesInput(newTimesArg,timetableInputs);
    % processNewTimesInput does not create newTimes for 'regular', it leaves that for
    % processRegularNewTimesInput to handle below.
    
    % Sync using the specified method. Call processMethodInput to get errors on the
    % method before errors on the optional inputs.
    methodArg = varargin{ntimetables+2};
    [method,isMethodProvided,isPreservingMethod,isAggregation] = processMethodInput(methodArg);
    if isMethodProvided
        % Found a method, start the name value pairs after that input arg.
        nvPairsStart = 3;
    else
        % If the third input arg was anything other than a name or a function
        % handle, processMethodInput will have errored. Only possibility left is
        % if the third input is the name of _something_, just not a recognized
        % method name. If no other inputs, error as an unrecognized method,
        % otherwise try it as a param name.
        if nargin == (ntimetables + 2)
            error(message('MATLAB:timetable:synchronize:UnrecognizedMethod',methodArg));
        end
        nvPairsStart = 2;
        method = 'default';
    end
    
    if nargin > ntimetables + 2
        pnames = {   'Constant' 'EndValues' 'IncludedEdge'  'SampleRate'  'TimeStep'};
        dflts =  {fillConstant   endValues   includedEdge            []          [] };
        try
            [fillConstant,endValues,includedEdge,sampleRate,timeStep,supplied] ...
                = matlab.internal.datatypes.parseArgs(pnames, dflts, varargin{ntimetables+nvPairsStart:end});
            
            if (supplied.SampleRate || supplied.TimeStep) && ~createAsRegular
                error(message('MATLAB:timetable:RowTimesParamConflict'));
            end

        catch ME
            if isMethodProvided
                % The method was correctly provided, must be a param error, just rethrow.
                rethrow(ME);
            else
                % At this point, the first of the varargins passed to parseArgs
                % must be a name, but not a method name. All that's left is to
                % decide to flag a bad method name or bad params.
                % An odd number of varargins, assume the first was a bad method
                % name - throw UnrecognizedMethod. Otherwise, for an even number]
                % of varargins, assume all params.
                matlab.internal.datatypes.throwInstead(ME,...
                    "MATLAB:table:parseArgs:WrongNumberArgs",...
                    message('MATLAB:timetable:synchronize:UnrecognizedMethod',methodArg));
            end
        end
        
        % Constant has to be a scalar, and EndValues has to be either 'extrap' or a
        % scalar. These scalar values are otherwise validated by assignment in retime.
        % IncludedEdge must be 'left' or 'right'.
        if ~isscalar(fillConstant)
            error(message('MATLAB:timetable:synchronize:InvalidConstant'));
        end
        [endValues,isPartialMatch] = partialMatch(endValues,{'extrap'});
        if ~isscalar(endValues) && ~isPartialMatch % endValues could be non-text
            error(message('MATLAB:timetable:synchronize:InvalidEndValues'));
        end
        
        [~,includedEdge] = getChoice(includedEdge,{'left','right'},'MATLAB:timetable:synchronize:InvalidIncludedEdge');
        
        if createAsRegular
            % Parameters have been processed, create the target time vector using a
            % time step or a sample rate. This will be used in retimeIt, but
            % ultimately the output will be created without storing it explicitly.
            [newTimes,timesMinMax,timeStep,sampleRate] = ...
                processRegularNewTimesInput(supplied,timeStep,sampleRate,timetableInputs);
        end
    elseif createAsRegular
        % 'regular' requires additional parameters
        error(message('MATLAB:timetable:synchronize:RegularWithoutParams'));
    end
    
    copyFirstLastInput = strcmp(varargin{ntimetables+1},{'first' 'last'}) & isPreservingMethod;
end

if ~(haveDurations == isa(newTimes,'duration'))
    error(message('MATLAB:timetable:synchronize:MixedTimeTypesNewTimes'));
end

% Unlike horzcat, but like inner/outerjoin, synchronize will allow duplicate var
% names in the two inputs, and make them unique.
if ntimetables > 1
    timetableInputs = timetable.makeUniqueVarNames(timetableInputs,timetableInputNames);
end

% Maintain tabular-wide properties, left most non-empty is preserved

% Call retimeIt to do the actual work. If syncing to the first input, and the
% method is one that just copies data for matching times, there's no need to
% call retimeIt on the first input, just copy it. Ditto the last input.
timetableOutputs = timetableInputs;
overrideVarContinuity = isMethodProvided && ~strcmp(method,'default');
for i = (1+copyFirstLastInput(1)):(ntimetables-copyFirstLastInput(2))
    ttIn = timetableInputs{i};
    if overrideVarContinuity || isempty(ttIn.varDim.continuity)
        [newTimesOut,newData] = retimeIt(ttIn,newTimes,method,isAggregation,endValues,includedEdge,fillConstant,timesMinMax);
    else
        % If VariableContinuity property is not empty and a method was not
        % provided to override that, apply the method corresponding to each
        % variable's VariableContinuity, and merge the results.
        continuityVals = enumeration('matlab.tabular.Continuity');
        newData = cell(1,ttIn.varDim.length);
        for j = continuityVals(:)' % need row vector in the for-loop index
            whichVars = (ttIn.varDim.continuity == j);
            % Only retimeIt if there are variables to work on with that method.
            if nnz(whichVars)
                ttSubset = ttIn(:,whichVars);
                interpMethod = j.InterpolationMethod;
                [newTimesOut,newDataOut] = retimeIt(ttSubset,newTimes,interpMethod,isAggregation,endValues,includedEdge,fillConstant,timesMinMax);
                % Build up new combined .data
                newData(whichVars) = newDataOut;
            end
        end
    end
    if createAsRegular
        timetableOutputs{i} = ...
            noCheckInitRegular(newData,length(newTimesOut),newTimesOut(1),timeStep,sampleRate,ttIn);
    else
        timetableOutputs{i} = ...
            noCheckInit(newData,newTimesOut,ttIn);
    end
    timetableOutputs{i}.arrayProps = ttIn.arrayProps;
end

% All the output timetables have the same time vector (explicitly or implicitly),
% and their var names have already been made unique, just mash them together.
ttOut = primitiveHorzcat(timetableOutputs{:}); % copies/merges properties

% Check for any cross variable incompatability that could have been introduced
% due to the size or type of the variables changing after synchronization.
% Currently, this is only required for eventtables and is a no-op for other
% tabular types.
ttOut.validateAcrossVars();

catch ME, throw(ME); end % keep the stack trace to one level


%-------------------------------------------------------------------------------
function [method,isRecognized,isPreserving,isAggregation] = processMethodInput(method)
% Validate the method input, and classify it according to whether it preserves
% the original data if evaluated at the original times 
import matlab.internal.datatypes.isScalarText
import matlab.internal.datatypes.partialMatch
isRecognized = true;
if isScalarText(method)
    method = partialMatch(method, ...
        {'previous' 'next' 'nearest' 'makima' 'linear' 'spline' 'pchip' 'fillwithmissing' 'fillwithconstant' ...
         'count' 'sum' 'mean' 'median' 'mode' 'prod' 'min' 'max' 'firstvalue' 'lastvalue' 'default'});
    switch method
    case {'previous' 'next' 'nearest' 'makima' 'linear' 'spline' 'pchip' 'fillwithmissing' 'fillwithconstant'}
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
elseif isa(method,'function_handle')
    isPreserving = false;
    isAggregation = true;
else
    % The argument was not a method name or a function handle.
    error(message('MATLAB:timetable:synchronize:InvalidMethod'));
end

%-------------------------------------------------------------------------------
function [newTimes,timesMinMax,isRegular] = processNewTimesInput(newTimes,timetableInputs)
% Validate the newTimeBasis, newTimeStep, or newTimes input, and compute the
% actual time vector for newTimeBasis or newTimeStep
import matlab.internal.datatypes.isScalarText
import matlab.internal.datatypes.partialMatch

ntimetables = length(timetableInputs);
timesMinMax = [];
isRegular = false;

if isa(newTimes,'datetime') || isa(newTimes,'duration')
    if ~isvector(newTimes)
        error(message('MATLAB:timetable:synchronize:NotVectorNewTimes'));
    end
    requireMonotonic(newTimes,true); % require strictly monotonic and non-missing in target
elseif isScalarText(newTimes)
    switch partialMatch(newTimes,{'union','intersection','commonrange','first','last','regular'})
    case 'union'
        newTimes = sort(timetableInputs{1}.rowDim.labels);
        for i = 2:ntimetables
            newTimes = union(newTimes,timetableInputs{i}.rowDim.labels,'sorted');
        end
        requireNonMissing(newTimes); % target already monotonic, require non-missing
    case 'intersection'
        newTimes = sort(timetableInputs{1}.rowDim.labels);
        for i = 2:ntimetables
            newTimes = intersect(newTimes,timetableInputs{i}.rowDim.labels,'sorted');
        end
        requireNonMissing(newTimes); % target already monotonic, require non-missing
    case 'commonrange'
        [tmin,tmax] = getCommonTimeRange(timetableInputs,'intersection');
        newTimes = timetableInputs{1}.rowDim.labels([]);
        for i = 1:ntimetables
            times = timetableInputs{i}.rowDim.labels;
            times = times(tmin <= times & times <= tmax);
            newTimes = union(newTimes,times,'sorted');
        end
        requireNonMissing(newTimes); % target already monotonic, require non-missing
    case 'first'
        newTimes = timetableInputs{1}.rowDim.labels;
        requireMonotonic(newTimes,true); % require strictly monotonic and non-missing in target
    case 'last'
        newTimes = timetableInputs{end}.rowDim.labels;
        requireMonotonic(newTimes,true); % require strictly monotonic and non-missing in target
    case 'regular'
        % processRegularNewTimesInput will handle this case
        isRegular = true;
    otherwise 
        newTimeStep = newTimes;
        [tmin,tmax] = getCommonTimeRange(timetableInputs,'union');

        % For aggregation with a newTimeStep ('hourly', 'minutely', ...), we'll need the min
        % and max bin edges in retimeIt for dealing with deciding whether there are any times
        % that exactly match the first/last bin edge (which one depends on IncludedEdge) and
        % therefore whether there should be a degenerate bin.
        timesMinMax = [tmin tmax];
        
        [tleft,tright,newTimeStep] = getSpanningTimeLimits(tmin,tmax,newTimeStep);
        newTimes = (tleft:newTimeStep:tright)'; % no round-off issues at seconds or greater resolution
        requireNonMissing(newTimes); % target already monotonic, require non-missing
    end
else
    error(message('MATLAB:timetable:synchronize:InvalidNewTimes'));
end

newTimes = newTimes(:); % force everything to a column

%-------------------------------------------------------------------------------
function [newTimes,timesMinMax,timeStep,sampleRate] = ...
    processRegularNewTimesInput(supplied,timeStep,sampleRate,timetableInputs)
% Validate the TimeStep or SampleRate parameter and values, and compute the corresponding
% regular time vector
import matlab.internal.tabular.validateTimeVectorParams
import matlab.internal.tabular.private.rowTimesDim.regularRowTimesFromTimeStep
import matlab.internal.tabular.private.rowTimesDim.regularRowTimesFromCalDurTimeStep

[tmin,tmax] = getCommonTimeRange(timetableInputs,'union');
timesMinMax = [tmin tmax];

supplied.RowTimes = false;
supplied.StartTime = true;
[rowTimesDefined,~,~,timeStep,sampleRate] = validateTimeVectorParams(supplied,[],tmin,timeStep,sampleRate);
if ~rowTimesDefined
    error(message('MATLAB:timetable:synchronize:RegularWithoutParams'));
end
if supplied.TimeStep
    % Find limits to span the data, nicely aligned w.r.t. the time step
    [unit,timeStep] = getRegularTimeVectorAlignment(timeStep);
    [tleft,~] = getSpanningTimeLimits(tmin,tmax,unit);

    % Calculate the number of rows for the time vector
    if isa(timeStep,'duration')
        % For a duration time step, start newTimes at the nicely aligned origin
        % from getSpanningTimeLimits plus a whole multiple of the time step
        dt = seconds(timeStep);
        tleft = tleft + seconds(floor(seconds(tmin-tleft)/dt)*dt);
        numRows = ceil((tmax - tleft)/timeStep) + 1;
        newTimes = regularRowTimesFromTimeStep(tleft,timeStep,numRows);
    else
        newTimes = regularRowTimesFromCalDurTimeStep(tleft,timeStep,tmax);
        if newTimes(end) < tmax
            newTimes(end+1) = newTimes(end) + timeStep;
        end
    end
else % supplied.SampleRate
    % Start newTimes on a whole second plus a whole multiple of the time step
    [tleft,~] = getSpanningTimeLimits(tmin,tmax,'secondly');
    tleft = tleft + seconds(floor(seconds(tmin-tleft)*sampleRate)/sampleRate);
    numRows = ceil(seconds(tmax - tleft)*sampleRate) + 1;
    newTimes = matlab.internal.tabular.private.rowTimesDim.regularRowTimesFromSampleRate(tleft,sampleRate,numRows);
end

%-------------------------------------------------------------------------------
function [tleft,tright,timeStep] = getSpanningTimeLimits(tmin,tmax,timeStep)
% Given a choice of time step name and the min/max times of the data being synchronized,
% return nicely-aligned spanning time limits and the actual time step.
import matlab.internal.datatypes.partialMatch

if isa(tmin,'datetime')
    switch partialMatch(timeStep,{'secondly','minutely','hourly','daily','weekly','monthly','quarterly','yearly'})
    case 'secondly',  timeStepName = 'second';  timeStep = seconds(1);
    case 'minutely',  timeStepName = 'minute';  timeStep = minutes(1);
    case 'hourly',    timeStepName = 'hour';    timeStep = hours(1);
    case 'daily',     timeStepName = 'day';     timeStep = caldays(1);
    case 'weekly',    timeStepName = 'week';    timeStep = calweeks(1);
    case 'monthly',   timeStepName = 'month';   timeStep = calmonths(1);
    case 'quarterly', timeStepName = 'quarter'; timeStep = calquarters(1);
    case 'yearly',    timeStepName = 'year';    timeStep = calyears(1);
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
else
    switch partialMatch(timeStep,{'secondly','minutely','hourly','daily','weekly','monthly','quarterly','yearly'})
    case 'secondly',  timeStepName = 'seconds';  timeStep = seconds(1);
    case 'minutely',  timeStepName = 'minutes';  timeStep = minutes(1);
    case 'hourly',    timeStepName = 'hours';    timeStep = hours(1);
    case 'daily',     timeStepName = 'days';     timeStep = days(1);
    case 'yearly',    timeStepName = 'years';    timeStep = years(1);
    case {'weekly' 'monthly' 'quarterly'}
        error(message('MATLAB:timetable:synchronize:UnknownNewTimeStepDuration',timeStep));
    otherwise
        error(message('MATLAB:timetable:synchronize:UnknownNewTimeStep',timeStep));
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
    if dt <= 0
        error(message('MATLAB:timetable:synchronize:NonPositiveTimeStep'));
    elseif dt <= 1000       %     0 < step <= 1 sec => secondly alignment
        unit = 'secondly';
    elseif dt <= 60*1000    % 1 sec < step <= 1 min => minutely alignment
        unit = 'minutely';
    elseif dt <= 60*60*1000 % 1 min < step <= 1 hr  => hourly alignment
        unit = 'hourly';
    else                    % 1 hr  < step          => daily alignment
        unit = 'daily';
    end
else
    [m,d,t] = split(timeStep,{'months' 'days' 'time'});
    if m > 0
        % For a pure months TimeStep, align the new row times to months, even if
        % TimeStep is a whole number of quarters or years
        unit = 'monthly';
    elseif d > 0
        % For a pure days TimeStep, align the new row times to days, even if
        % TimeStep is a whole number of weeks
        unit = 'daily';
    elseif t > 0
        % timeStep is a calendarDuration containing only time, treat as a duration
        timeStep = time(timeStep);
        unit = getRegularTimeVectorAlignment(timeStep);
    else
        % Assuming the calendarDuration is pure, then its one non-zero component
        % must have been non-positive.
        error(message('MATLAB:timetable:synchronize:NonPositiveTimeStep'));
    end
end

%-------------------------------------------------------------------------------
function [tmin,tmax] = getCommonTimeRange(timetableInputs,rangeType)
% Find the common time range of the timetable's tme vectors

% Get min/max times for each timetable - some may be empty and need to be
% propagated along so the 'all-empty' case flows through properly.
ntimetables = length(timetableInputs);
tmin = cell(1,ntimetables);
tmax = tmin;
for i = 1:ntimetables
    times = timetableInputs{i}.rowDim.labels;
    tmin{i} = min(times);
    tmax{i} = max(times);
end

% Expand and concatenate tmin/tmax. Empties will be ignored if at least one
% of the 'tmin/tmax's is non-empty; if all of tmin/tmax is empty, vertcat
% (correctly) returns empty to proprogate it along.
% vertcat: rowTimes are always column
tmin = vertcat(tmin{:});
tmax = vertcat(tmax{:});

switch rangeType
case 'union' % the union of the ranges
    tmin = min(tmin);
    tmax = max(tmax);
case 'intersection' % the intersection of the ranges
    tmin = max(tmin);
    tmax = min(tmax);
otherwise
    assert(false);
end


%-------------------------------------------------------------------------------
function [newTimes,newData] = retimeIt(tt1,newTimes,method,~,endValues,includedEdge,fillConstant,timesMinMax)
% Synchronize one timetable to a new time vector using the specified method
tt1_data = tt1.data;

if isa(method,'function_handle') % allow the switch to control this case
    fun = method;
    method = 'fun';
end
    
switch method
case {'default' 'fillwithmissing'}
    requireMissingAware(tt1,method);
    % Find the correspondence between rows in the input and in the output by
    % matching up existing and new row times. Select the first among dup input
    % row times. copyTo is logical to allow easy negation; it says which output
    % rows will have input data copied into them. copyFromInds is indices to
    % preserve the order for a non-monotonic correspondence; it says which input
    % rows will be copied to the output.
    [copyTo,locs] = ismember(newTimes,tt1.rowDim.labels);
    copyFromInds = locs(locs > 0);
    tt2_data = cell(1,length(tt1_data));
    for j = 1:length(tt2_data)
        % Initialize the output var with the same number of rows as the target
        % time vector, with the trailing size(s) of the input var, filled with
        % default values.
        var_j = tt1_data{j};
        szOut = size(var_j); szOut(1) = length(newTimes);
        tt2_data{j} = matlab.internal.datatypes.defaultarrayLike(szOut,'like',var_j);
        % Copy data from the input var to matching rows in the output var, all
        % columns at once, leaving the other output rows as default values. This
        % might copy missing data, which is fine for fillWithMissing.
        tt2_data{j}(copyTo,:) = var_j(copyFromInds,:);
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
    [copyTo,locs] = ismember(newTimes,tt1.rowDim.labels); % true for target rows
    copyFromInds = locs(locs > 0); % list of source rows, in specified (possibly not sorted) order
    tt2_data = cell(1,length(tt1_data));
    for j = 1:length(tt2_data)
        % Initialize the output var with the same number of rows as the target
        % time vector, with the trailing size(s) of the input var, filled with
        % the specified constant.
        var_j = tt1_data{j};
        szOut = size(var_j); szOut(1) = length(newTimes);
        tt2_data{j} = matlab.internal.datatypes.defaultarrayLike(szOut,'like',var_j);
        % Copy data from the input var to rows with matching row times in the
        % output var, leaving the fill value in elements of the output var where
        % the row time did not exist in the input.
        missingMask = safeIsMissing(var_j);
        if any(missingMask,'all')
            for k = 1:prod(szOut(2:end))
                % Copy only each column's non-missing data, fill the other
                % elements. Treat input and output "as if" matrices. 
                missingMaskFrom = missingMask(copyFromInds,k); % which source rows have missing data
                copyFromIndsSkipMissing = copyFromInds(~missingMaskFrom); % remove source rows with missing data
                copyToSkipMissing = copyTo; copyToSkipMissing(copyTo) = ~missingMaskFrom; % remove target rows corresponding to missing data
                tt2_data{j}(copyToSkipMissing,k) = var_j(copyFromIndsSkipMissing,k);
                tt2_data{j}(~copyToSkipMissing,k) = fillConstant;
            end
        else
            % No missing data, copy all data from the matching rows. The input
            % var might have one or more columns (including N-D), copy and fill
            % all at once.
            tt2_data{j}(copyTo,:) = var_j(copyFromInds,:);
            tt2_data{j}(~copyTo,:) = fillConstant;
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

    rowLocsCache = []; % initialize cache that saves work when there's no missing data
    
    tt1_time = tt1.rowDim.labels;
    tt2_data = cell(1,length(tt1_data));
    for j = 1:length(tt2_data)
        t = tt1_time;
        var_j = tt1_data{j};
        missingMask = safeIsMissing(var_j);
        
        if any(missingMask,'all')
            % Create the output var with the same number of rows as the target
            % time vector, with the trailing size(s) of the input var, filled
            % with default values.
            szOut = size(tt1_data{j}); szOut(1) = length(newTimes); % output size for j-th var
            tt2_data{j} = matlab.internal.datatypes.defaultarrayLike(szOut,'like',var_j);
            for k = 1:prod(szOut(2:end))
                % Interpolate for each column on non-missing data only. Treat
                % input and output "as if" matrices.
                nonMissing_k = ~missingMask(:,k);
                t_k = t(nonMissing_k);
                v_k = var_j(nonMissing_k,k);
                tt2_data{j}(:,k) = nnbrInterp1Local(t_k,v_k,newTimes,method,endValues);
            end
        else
            % The input var might have one or more columns (including N-D),
            % interpolate all at once. Save work by reusing the source and
            % target row locations for vars that don't have missing data.
            [tt2_data{j},rowLocsCache] = nnbrInterp1Local(t,var_j,newTimes,method,endValues,rowLocsCache);
        end
    end

case {'linear' 'spline' 'pchip' 'makima'}
    requireNumeric(tt1,1,method);
    requireMonotonic(tt1.rowDim.labels,true,method); % require strictly monotonic
    t = tt1.rowDim.labels;
    tt2_data = cell(1,length(tt1_data));
    for j = 1:length(tt2_data)
        var_j = tt1_data{j};
        missingMask = safeIsMissing(var_j); % requireNumeric() doesn't guarantee that ismissing() won't error
        try
            if any(missingMask,'all')
                % Create the output var with the same number of rows as the
                % target time vector, with the trailing size(s) of the input
                % var, filled with default values.
                szOut = size(var_j); szOut(1) = length(newTimes); % output size for j-th var
                tt2_data{j} = matlab.internal.datatypes.defaultarrayLike(szOut,'like',var_j);
                for k = 1:prod(szOut(2:end))
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
        catch ME
            matlab.internal.datatypes.throwInstead(ME,...
                ["MATLAB:griddedInterpolant:NonFloatValuesErrId" "MATLAB:interp1:NonFloatValues"],...
                message('MATLAB:timetable:synchronize:Interp1Failed',tt1.varDim.labels{j},method,ME.message));
        end
    end

case {'count' 'sum' 'mean' 'median' 'mode' 'prod' 'min' 'max' 'firstvalue' 'lastvalue' 'fun'}
    % For aggregation, get the name of a user-supplied function, or the actual
    % function corresponding to a method name, depending on what's still needed.
    isUserFun = (method == "fun");
    if isUserFun
        % No checks on the data variables for a user-supplied function, it may error.
        method = func2str(fun);
    else
        % str2funcLocal also checks the data type using requireNumeric at
        % various levels of strictness for 'sum', 'mean', 'prod', 'min', and
        % 'max', or using requireMonotonic for 'firstValue' and 'lastValue (no
        % check for 'count').
        fun = str2funcLocal(tt1,method);
    end
    
    % The target time vector has already been checked for monotonicity, but
    % aggregation requires increasing time.
    if (length(newTimes) > 1) && (newTimes(1) > newTimes(2))
        error(message('MATLAB:timetable:synchronize:DecreasingNewTimesForAggregation',method));
    end
    
    ngroups = length(newTimes)-1;
    if ngroups >= 1
        groupIdx = discretize(tt1.rowDim.labels,newTimes,'IncludedEdge',includedEdge);
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
        groupIdx = nan(size(tt1.rowDim.labels));
        if ~isempty(newTimes) % no degenerate bin for empty output timetable case
            % create a group and assign it to the rows where the times match the (scalar)
            % newTimes.
            ngroups = 1;
            groupIdx(tt1.rowDim.labels == newTimes) = 1;
        end
    end

    tt2_data = groupedApply(groupIdx,ngroups,tt1_data,tt1.varDim.labels,fun,method,isUserFun);
    
otherwise
    assert(false);
end
newData = tt2_data;


%-------------------------------------------------------------------------------
function b_data = groupedApply(groupIdx,ngroups,a_data,a_varnames,fun,funName,isUserFun)
% Apply a function to each variable by group. Similar to the grouped, table
% output case in varfun, but here the output includes rows for groups that are
% not present in the data, so the function should be prepared to accept a
% possibly empty input.
import matlab.internal.datatypes.ordinalString

grprows = matlab.internal.datatypes.getGroups(groupIdx,ngroups);

ndataVars = length(a_data);

% Each cell will contain the result from applying FUN to one variable,
% an ngroups-by-.. array with one row for each group's result
b_data = cell(1,ndataVars);

% Each cell will contain the result from applying FUN to one group
% within the current variable
outVals = cell(ngroups,1);

for jvar = 1:ndataVars
    var_j = a_data{jvar};
    varname_j = a_varnames{jvar};
    for igrp = 1:ngroups
        inArg = getVarRows(var_j,grprows{igrp});
        try
            outVal = fun(inArg);
        catch ME
            m = message('MATLAB:table:varfun:FunFailedGrouped',funName,ordinalString(igrp),varname_j);
            throw(MException(m).addCause(ME));
        end
        if size(outVal,1) ~= 1
            error(message('MATLAB:timetable:synchronize:FunMustReturnOneRow',funName));
        end
        outVals{igrp} = outVal;
    end
    
    % vertcat the results from the current var, checking that each group has the
    % same number of rows as it did in the other vars
    if ngroups > 0
        try
            b_data{jvar} = vertcat(outVals{:});
        catch ME
            error(message('MATLAB:table:varfun:VertcatFailed',funName,varname_j,ME.message));
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
        if (funName == "count") || isUserFun % (1) and (3)
            b_data{jvar} = zeros(sz);
        else % (2)
            b_data{jvar} = matlab.internal.datatypes.defaultarrayLike(sz,'like',a_data{jvar});
        end
    end
end


%-------------------------------------------------------------------------------
function var_ij = getVarRows(var_j,i)
% Extract rows of a variable, regardless of its dimensionality
if ismatrix(var_j)
    var_ij = var_j(i,:); % without using reshape, may not have one
else
    % Each var could have any number of dims, no way of knowing,
    % except how many rows they have.  So just treat them as 2D to get
    % the necessary rows, and then reshape to their original dims.
    sizeOut = size(var_j); sizeOut(1) = numel(i);
    var_ij = reshape(var_j(i,:), sizeOut);
end


%-------------------------------------------------------------------------------
function fun = str2funcLocal(tt,method)
% Convert a method input argument into a function handle, with some pre-checks
% on the data it will be applied to
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
if any(ismissing(times))
    error(message('MATLAB:timetable:synchronize:NotMonotonicNewTimes'));
end


%-------------------------------------------------------------------------------
function requireMonotonic(times,strict,method)
% Require a target time vector (nargin==2) or the time vector from an input
% timetable (nargin==3) to be monotonically increasing or decreasing.
diffTimes = diff(times);
if strict
    tf = all(diffTimes > 0) || all(diffTimes < 0);
else
    tf = all(diffTimes >= 0) || all(diffTimes <= 0);
end
if ~tf
    if any(diffTimes == 0)
        if nargin < 3
            error(message('MATLAB:timetable:synchronize:NotUniqueNewTimes'));
        else
            error(message('MATLAB:timetable:synchronize:NotUnique',method));
        end
    else
        if nargin < 3
            error(message('MATLAB:timetable:synchronize:NotMonotonicNewTimes'));
        else
            error(message('MATLAB:timetable:synchronize:NotMonotonic',method));
        end
    end
end


%-------------------------------------------------------------------------------
function requireNumeric(tt,strictness,method)
% Require all variables in an input timetable to be numeric-like to some degree
switch strictness
case 0
    % Require all variables to be "numeric-like" in the sense that they are ordered, so
    % support min/max/mode/median
    isNumericIsh = @(x) isnumeric(x) || islogical(x) || isa(x,'datetime') || isa(x,'duration') ...
        || (isa(x,'categorical') && (isordinal(x) || matches(method,'mode')));
    which = cellfun(isNumericIsh,tt.data);
    if nargout == 0 && ~all(which)
        if matches(method,'mode')
            % Mode does not require the categorical to be ordinal
            error(message('MATLAB:timetable:synchronize:NotNumeric0Mode',method));
        else
            error(message('MATLAB:timetable:synchronize:NotNumeric0',method));
        end
    end
case 1
    % Require all variables to be "numeric-like", and have mean/min/max methods as
    % well as support interpolation
    if matches(method,'mean')
        isNumericIsh = @(x) isnumeric(x) || islogical(x) || isa(x,'datetime') || isa(x,'duration');
    else
        isNumericIsh = @(x) isnumeric(x) || isa(x,'datetime') || isa(x,'duration');
    end
    which = cellfun(isNumericIsh,tt.data);
    if nargout == 0 && ~all(which)
        error(message('MATLAB:timetable:synchronize:NotNumeric1',method));
    end
case 2
    % Require all variables to be even more "numeric-like", and have a sum
    % method as well
    isNumericIsh = @(x) isnumeric(x) || islogical(x) || isa(x,'duration');
    which = cellfun(isNumericIsh,tt.data);
    if nargout == 0 && ~all(which)
        error(message('MATLAB:timetable:synchronize:NotNumeric2',method));
    end
case 3
    % Require all variables to be strictly numeric
    isNumericIsh = @(x) isnumeric(x) || islogical(x);
    which = cellfun(isNumericIsh,tt.data);
    if nargout == 0 && ~all(which)
        error(message('MATLAB:timetable:synchronize:NotNumeric3',method));
    end
otherwise
    assert(false);
end


%-------------------------------------------------------------------------------
function requireMissingAware(tt,method)
% Require all variables in an input timetable to have some standard way to represent missing values
import matlab.internal.datatypes.isText
isMissingAware = @(x) isfloat(x) ...
                   || isa(x,'categorical') ...
                   || isa(x,'datetime') || isa(x,'duration') || isa(x,'calendarDuration') ...
                   || isText(x,true) ...
                   || (ischar(x) && ismatrix(x)); % a data variable might be a char matrix
which = cellfun(isMissingAware,tt.data);
if nargout == 0 && ~all(which)
    error(message('MATLAB:timetable:synchronize:NotMissingAware',method));
end


%-------------------------------------------------------------------------------
% "Canned" methods that omit missing values automatically. In cases that
% explicitly use ismissing, recover from an error by assuming all values are
% non-missing. In cases that rely on 'omitnan', recover from an error by
% assuming that 'omitnan' was the problem, and retrying without it.
function y = countLocal(x)
y = sum(~safeIsMissing(x),1);
%-------------------------------------------------------------------------------
function y = sumLocal(x)
try
    y = sum(x,1,'omitnan');
catch
    y = sum(x,1);
end
%-------------------------------------------------------------------------------
function y = prodLocal(x)
try
    y = prod(x,1,'omitnan');
catch
    y = prod(x,1);
end
%-------------------------------------------------------------------------------
function y = meanLocal(x)
try
    y = mean(x,1,'omitnan');
catch
    y = mean(x,1);
end
%-------------------------------------------------------------------------------
function y = medianLocal(x)
try
    y = median(x,1,'omitnan');
catch
    y = median(x,1);
end
%-------------------------------------------------------------------------------
function y = modeLocal(x)
    y = mode(x,1);
%-------------------------------------------------------------------------------
function y = minLocal(x)
if size(x,1) > 0
    try
        y = min(x,[],1,'omitnan');
    catch
        y = min(x,[],1);
    end
else
    sz = size(x); sz(1) = 1;
    y = matlab.internal.datatypes.defaultarrayLike(sz,'like',x);
end
%-------------------------------------------------------------------------------
function y = maxLocal(x)
if size(x,1) > 0
    try
        y = max(x,[],1,'omitnan');
    catch
        y = max(x,[],1);
    end
else
    sz = size(x); sz(1) = 1;
    y = matlab.internal.datatypes.defaultarrayLike(sz,'like',x);
end
%-------------------------------------------------------------------------------
function y = firstvalueLocal(x)
sz = size(x); sz(1) = 1;
y = matlab.internal.datatypes.defaultarrayLike(sz,'like',x);
for k = 1:prod(sz(2:end))
    hasValue = ~safeIsMissing(x(:,k));
    if any(hasValue,1)
        y(1,k) = x(find(hasValue,1,'first'),k);
    end
end
%-------------------------------------------------------------------------------
function y = lastvalueLocal(x)
sz = size(x); sz(1) = 1;
y = matlab.internal.datatypes.defaultarrayLike(sz,'like',x);
for k = 1:prod(sz(2:end))
    hasValue = ~safeIsMissing(x(:,k));
    if any(hasValue,1)
        y(1,k) = x(find(hasValue,1,'last'),k);
    end
end


%-------------------------------------------------------------------------------
function tf = safeIsMissing(x)
% A local version of ismissing that never errors.
try
    tf = ismissing(x);
catch
    % ismissing may error, even for a "numeric" type. Assume there are no
    % missing values.
    tf = false(size(x,1),1);
end


%-------------------------------------------------------------------------------
function [vq,rowLocs] = nnbrInterp1Local(t,v,tq,method,endValues,rowLocs)
% A local version of interp1 that supports nearest-neighbor interpolation with
% non-numeric data.

defaultExtrap = strcmp(endValues,"extrap"); % use strcmp: endValues may be non-text
if defaultExtrap
    % For 'extrap', rely on interp1 to do next/prev/nearest extrapolation on the
    % indices (or return NaN where it can't).
    extrap = 'extrap';
else
    % Otherwise tell it to just flag the locations where it would have to extrapolate.
    extrap = NaN; % extrapolation value for the INDICES, not the data
end

if nargin<8 || ~iscell(rowLocs)
    % When there are missing values in this var, or if the cache is empty, fresh
    % source/target row locations need to be computed.
    if method == "previous"
        % Interpolate to find the index of the previous grid point for each query point.
        % In each group of repeated grid points, get the last one, to make 'previous'
        % continuous from the right.
        [ut,iut] = unique(t,'last');
        rowLocs = interp1Local(ut,iut,tq,method,extrap);
    elseif method == "next"
        % Interpolate to find the index of the next grid point for each query point.
        % In each group of repeated grid points, get the first one, to make 'next'
        % continuous from the left.
        [ut,iut] = unique(t,'first');
        rowLocs = interp1Local(ut,iut,tq,method,extrap);
    else % 'nearest'
        % Find the first in each group of duplicate grid points.
        [ut,itFirst] = unique(t,'first');
        % Find the last in each group of duplicate grid points.
        [~,itLast] = unique(t,'last');
        % Find the index of the nearest unique grid point for each query point.
        iut = interp1Local(ut,(1:length(ut))',tq,method,extrap);
        if defaultExtrap && ~isempty(ut)
            % For 'extrap', interp1 using 'nearest' on a non-empty grid returns
            % valid indices everywhere in iut.
            nearestUt = ut(iut);
        else
            % Otherwise, interp1 returns NaNs in iut to indicate extrapolation, set
            % things up so that locs is also NaN in those elements.
            nearestUt = matlab.internal.datatypes.defaultarrayLike(size(iut),'like',ut);
            idxNonNaN = ~isnan(iut);
            nearestUt(idxNonNaN) = ut(iut(idxNonNaN));
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
    targetLocs = isfinite(rowLocs);   % locations where interp1 did NOT extrapolate
    sourceLocs = rowLocs(targetLocs); % corresponding query points
    
    % Return the row locations for reuse if requested.
    if nargout == 2
        rowLocs = {sourceLocs targetLocs};
    end
else
    % When there are no missing values in this var, the cached source/target row
    % locs from previous vars can be reused (if present).
    sourceLocs = rowLocs{1};
    targetLocs = rowLocs{2};
end

% Using 'extrap' told interp1 to use 'next'/'prev'/'nearest' for extrapolation,
% and interp1 returns NaNs for extrapolation to the left with 'prev', and to the
% right for 'next'. Anywhere loc is non-NaN is where real data goes, anywhere
% else is left as a default value from defaultarrayLike. If endValues was
% specified as a value, interp1 used NaN for _all_ extrapolation, so anywhere
% loc is NaN is where the specified endValue has to go.
szOut = size(v); szOut(1) = length(tq); % output size for j-th var
vq = matlab.internal.datatypes.defaultarrayLike(szOut,'like',v);
vq(targetLocs,:) = v(sourceLocs,:);
if ~defaultExtrap
    vq(~targetLocs,:) = endValues;
end


%-------------------------------------------------------------------------------
function vq = interp1Local(x,v,xq,method,extrap)
% A local version of interp1 that supports interpolation with zero or one data
% points. If v does not support missing (or the extrap value), this may error,
% which the caller must handle.
%
% Assumes x and xq are column vectors, and v is a column vector or a
% column-oriented array. Does not support interp1(v,xq,...)

defaultExtrap = strcmp(extrap,"extrap"); % use strcmp: endValues may be non-text

if isempty(x) % v is 0x...
    if defaultExtrap
        extrap = missing;
    end
    % Create an array of v's type, xq's height, v's width/etc, containing the
    % scalar extrap value
    vq = v([]);
    vq(1) = extrap;
    outSz = size(v); outSz(1) = length(xq);
    vq = repmat(vq,outSz);
elseif isscalar(x) % v is 1x...
    if defaultExtrap
        extrap = missing;
    end
    % Create an array of v's type, xq's height, v's width/etc, containing
    % replicates of v's one row (or slice)
    repSz = ones(1,ndims(v)); repSz(1) = length(xq);
    vq = repmat(v,repSz);
    switch method
    case 'next'
        % Leave the value from v in query points LE than x, assign the extrap
        % value to query points GT x, and to missing query points
        vq(~(xq <= x),:) = extrap;
    case 'previous'
        % Leave the value from v in query points GE than x, assign the extrap
        % value to query points LT x, and to missing query points
        vq(~(xq >= x),:) = extrap;
    case 'nearest'
        % Leave the value from v everywhere
    otherwise % spline-like, linear/spline/pchip/makima
        vq(xq ~= x,:) = extrap;
    end
else
    vq = interp1(x,v,xq,method,extrap);
end


%-------------------------------------------------------------------------------
function tt = noCheckInit(vars,rowTimes,ttRef)
import matlab.internal.tabular.private.explicitRowTimesDim
tt = ttRef.cloneAsEmpty(); % preserve type
tt.rowDim = explicitRowTimesDim(length(rowTimes),rowTimes,ttRef.rowDim.timeEvents);
tt.varDim = ttRef.varDim;
tt.metaDim = ttRef.metaDim;
tt.data = vars;


%-------------------------------------------------------------------------------
function tt = noCheckInitRegular(vars,numRows,startTime,timeStep,sampleRate,ttRef)
import matlab.internal.tabular.private.implicitRegularRowTimesDim
import matlab.internal.tabular.private.explicitRowTimesDim
tt = ttRef.cloneAsEmpty(); % preserve type
[makeImplicit,rowTimes] = implicitRegularRowTimesDim.implicitOrExplicit(numRows,startTime,timeStep,sampleRate);
if makeImplicit
    tt.rowDim = implicitRegularRowTimesDim(numRows,startTime,timeStep,sampleRate,ttRef.rowDim.timeEvents);
else
    tt.rowDim = explicitRowTimesDim(length(rowTimes),rowTimes,ttRef.rowDim.timeEvents);
end
tt.varDim = ttRef.varDim;
tt.metaDim = ttRef.metaDim;
tt.data = vars;
