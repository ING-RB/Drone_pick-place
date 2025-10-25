function tt = extractTimetable(ds, varargin)
%EXTRACTTIMETABLE Extracts timetable from a Simulink.SimulationData.Dataset
% or a Simulink.SimulationData.Signal.
%   TT = EXTRACTTIMETABLE(DS) Extracts the timetable TT containing the
%   timeseries and timetable data from all signals found in the
%   Simulink.SimulationData.Dataset DS or a single
%   Simulink.SimulationDataset S. If the data in the signals are
%   differently sized or have different sample times/timesteps, the
%   synchronized union padded with missing values will be returned in a
%   single timetable TT.
%
%   TT = EXTRACTTIMETABLE(DS, Name, Value) specifies additional parameters
%   using one or more name-value pair arguments.
%
%   Name-Value Pairs to specify TimeSeries and Name-Value Pairs to specify
%   Timetables may be used together to extract data from both timeseries
%   data and timetable data contained in the input respectively.
%
%   Name-Value Pairs for all Simulink.SimulationData.Dataset or Simulink.SimulationData.Signal inputs:
%   --------------------------------------------------------------------------------------------------
%
%   "OutputFormat"         - The datatype and grouping of the output.
%                            - "timetable" (default): The output will be a
%                              timetable containing the synchronized union of
%                              all signal data padded with missing values.
%                            - "cell-by-signal": The output will be a cell
%                              array containing a single-variable timetable
%                              for each timeseries or timetable
%                              found in the input.
%                            - "cell-by-sampletime" or "cell-by-timestep":
%                              The output will be a cell
%                              array containing one timetable per sample
%                              time found in the input.
%
%   "SignalNames"          - Specify the names of the signals or dataset elements to be
%                            extracted into a timetable as a character vector,
%                            string array, or cell array of character vectors
%                            or a <a href="matlab: help pattern">pattern</a>.
%                          - SignalNames may be combined with all other
%                            methods of specifying data to be extracted.
%
%   "Template"             - Extracts the timetable containing data from all
%                            the signals with the same time properties as
%                            the provided template which may be a:
%                               * timeseries
%                               * timetable
%                               * Simulink.SimulationData.Signal
%                               * Name of a Signal in DS.
%                          - Template may not be combined with other
%                            methods of specifying TimeSeries or Timetables
%                            contained in the input.
%
%
%   Name-Value Pairs to specify TimeSeries contained in Input:
%   ----------------------------------------------------------------------------------------------------
%
%   "SampleTime"           - Extracts the timetable containing data from all
%                            timeseries objects in the input with the
%                            specified sample time. If multiple sample
%                            times are provided in a vector, then the
%                            output will be a synchronized timetable,
%                            unless an 'OutputFormat' is provided.
%                            The sample time must be specified as positive
%                            numeric values.
%
%   "TimeVector"           - Extracts the timetable containing data from all
%                            the timeseries objects in the input with the
%                            time vector matching the provided time vector.
%                            "TimeVector" must be specified as a double
%                            vector.
%
%
%   Name-Value Pairs to specify Timetables contained in Input:
%   ----------------------------------------------------------------------------------------------------
%
%   "SampleRate"           - Extracts the timetable containing data from all
%                            timetables in the input with the specified
%                            sample rate. If multiple sample rates are
%                            provided in a vector, then the output will be
%                            a synchronized timetable, unless an
%                            'OutputFormat' is provided. The sample rate
%                            must be specified in Hz.
%
%   "TimeStep"             - Extracts the timetable containing data from all
%                            timetables in the input with the specified
%                            time step. If multiple time steps are provided
%                            in a vector, then the output will be a
%                            synchronized timetable, unless an
%                            'OutputFormat' is provided. The time step must
%                            be duration values.
%
%   "RowTimes"             - Extracts the timetable containing data from all
%                            the timetables contained in the input with the
%                            RowTimes matching the provided datetime or
%                            duration vector.
%
%   "StartTime"            - Extracts the timetable containing data from
%                            all the timetables contained in the
%                            input with a matching StartTime. The start time
%                            must be a scalar datetime or duration value.
%                          - StartTime may be combined with either
%                            SampleRate or TimeStep. The extracted
%                            timetable will contain data from all the
%                            timetables contained in the input with both a
%                            matching StartTime value and a matching
%                            TimeStep/SampleRate.
%
%
%   See also TIMETABLE, TIMESERIES2TIMETABLE

%   Copyright 2021 The MathWorks, Inc.

if ~(isa(ds, 'Simulink.SimulationData.Signal') || isa(ds, 'Simulink.SimulationData.Dataset'))|| ~isscalar(ds)
    error(message('MATLAB:extractTimetable:InvalidArray'))
end


pnames = {'TimeVector' 'RowTimes' 'SampleRate' 'TimeStep' 'SampleTime' 'StartTime' 'Template' 'SignalNames' 'OutputFormat'};
dflts  = {       []           []           []         []           []         []        []      string(nan)    'timetable'};

[timeVals, rowTimes, sampleRate, timeStep, sampleTime, startTime, template, signalNames, outputFormat, supplied] = matlab.internal.datatypes.parseArgs(pnames,dflts,varargin{:});

% Only one way to specify a subset of a dataset to avoid conflicing
% specifications.
if supplied.Template && any([supplied.SampleTime, supplied.TimeVector, supplied.RowTimes, supplied.SampleRate, supplied.TimeStep])
    error(message("MATLAB:extractTimetable:TemplateAndOtherFilter"))
end

if sum([supplied.TimeVector, supplied.SampleTime]) > 1
    error(message("MATLAB:extractTimetable:TooManyTSInputs"))
end

if sum([supplied.RowTimes, supplied.SampleRate, supplied.TimeStep]) > 1
    error(message("MATLAB:extractTimetable:TooManyTTInputs"))
end

if supplied.TimeStep && isa(timeStep,'calendarDuration')
    error(message('MATLAB:extractTimetable:InvalidTimeStep'));
end

[~,rowTimes,startTime,timeStep,sampleRate] ...
    = matlab.internal.tabular.validateTimeVectorParams(supplied,rowTimes,startTime,timeStep,sampleRate,"extractTimetable");


if supplied.SampleTime && ~(isnumeric(sampleTime) && isreal(sampleTime) ...
        && isvector(sampleTime) && all(sampleTime >= 0))
    error(message("MATLAB:extractTimetable:InvalidSampleTime"))
end

if supplied.TimeVector
    if ~(isa(timeVals,'double') && (isvector(timeVals) || isempty(timeVals)))
        error(message("MATLAB:extractTimetable:InvalidTimeVector"));
    end
    % Force it into a column vector.
    timeVals = timeVals(:);
end

if supplied.RowTimes
    if ~((isvector(rowTimes) || isempty(rowTimes)) && (isa(rowTimes,'duration') || isa(rowTimes,'datetime')))
        error(message("MATLAB:timetable:InvalidRowTimes"));
    end
    % Force it into a column vector.
    rowTimes = rowTimes(:);
end

allowedOutputFormats = {'timetable' 'cell-by-signal' 'cell-by-sampletime' 'cell-by-timestep'};
if supplied.OutputFormat
    outputFormat = matlab.internal.datatypes.getChoice(outputFormat,allowedOutputFormats,'MATLAB:extractTimetable:InvalidOutputFormat');
else
    % Default to 'timetable'
    outputFormat = 1;
end

% Extract all signals from leaves.
[signalArray, increments, varNames, tsUnits] = extractSignals(ds,supplied.SignalNames,signalNames);

% Short circuit if nothing is found.
if isempty(signalArray)
    tt = timetable.empty();
    if outputFormat > 1
        tt = {};
    end
    return
end

tsCondition = [];
ttCondition1 = [];
ttCondition2 = [];
suppliedIncrements = seconds([]);
if supplied.Template % No other NV pairs allowed with template
    if matlab.internal.datatypes.isScalarText(template)
        if matches(template,ds.getElementNames)
            template = ds.getElement(template);
            if isa(template, "Simulink.SimulationData.Signal")
                template = template.Values;
            else
                error(message("MATLAB:extractTimetable:MultipleTemplatesFound"))
            end
        else
            error(message("MATLAB:extractTimetable:UnrecognizedTemplateName",template))
        end
    elseif isa(template,"Simulink.SimulationData.Signal")
        template = template.Values;
    end

    if isa(template,"timeseries")
        tsFilter = @(tsi,template) isequalTimeInfo(tsi.TimeInfo,template.TimeInfo);
        tsCondition = template;
        ttFilter = @(tti,condition1,condition2) eq(1,2);
    elseif isa(template,"timetable")
        ttFilter = @(tti, template, ttCondition2) isequalTime(tti.Properties.RowTimes,template.Properties.RowTimes);
        ttCondition1 = template;
        tsFilter = @(tti,condition) eq(1,2);
    else
        error(message("MATLAB:extractTimetable:InvalidTemplate"))
    end
else

    if supplied.TimeVector
        tsFilter = @(tsi,timeVals) isequalTime(seconds(tsi.Time),seconds(timeVals));
        tsCondition = timeVals;
        hasTSFilter = true;
    elseif supplied.SampleTime
        tsFilter = @(tsi,increment) any(tsi.TimeInfo.Increment == sampleTime);
        tsCondition = sampleTime;
        hasTSFilter = true;
        suppliedIncrements = seconds(unique(sampleTime,'stable'));
    else % Default filter which allows for all timeseries.
        hasTSFilter = false;
        tsFilter = @(tti,condition) eq(1,1);
    end


    if supplied.RowTimes
        ttFilter = @(tti,rowTimes,ttCondition2) isequalTime(tti.Properties.RowTimes,rowTimes);
        ttCondition1 = rowTimes;
        hasTTFilter = true;
    elseif supplied.SampleRate && supplied.StartTime
        ttFilter = @(tti,sampleRate,startTime) any(tti.Properties.SampleRate == sampleRate) && isequal(tti.Properties.StartTime, startTime);
        ttCondition1 = sampleRate;
        ttCondition2 = startTime;
        hasTTFilter = true;
        suppliedIncrements = unique([suppliedIncrements seconds(1./sampleRate)],'stable');
    elseif supplied.TimeStep && supplied.StartTime
        ttFilter = @(tti,timeStep,startTime) any(tti.Properties.TimeStep == timeStep) && isequal(tti.Properties.StartTime, startTime);
        ttCondition1 = timeStep;
        ttCondition2 = startTime;
        hasTTFilter = true;
        suppliedIncrements = unique([suppliedIncrements timeStep],'stable');
    elseif supplied.SampleRate
        ttFilter = @(tti,sampleRate,ttCondition2) any(tti.Properties.SampleRate == sampleRate);
        ttCondition1 = sampleRate;
        hasTTFilter = true;
        suppliedIncrements = unique([suppliedIncrements seconds(1./sampleRate)],'stable');
    elseif supplied.TimeStep
        ttFilter = @(tti,timeStep,ttCondition2) any(tti.Properties.TimeStep == timeStep);
        ttCondition1 = timeStep;
        hasTTFilter = true;
        suppliedIncrements = unique([suppliedIncrements timeStep],'stable');
    elseif supplied.StartTime
        ttFilter = @(tti,startTime,ttCondition2) isequal(tti.Properties.StartTime, startTime);
        ttCondition1 = startTime;
        hasTTFilter = true;
    else % Default filter which allows for all timetables.
        hasTTFilter = false;
        ttFilter = @(tti,condition1,condition2) eq(1,1);
    end

    if hasTSFilter && ~hasTTFilter
        % Ignore all timetables, only filtering for TS
        ttFilter = @(tti,condition1,condition2) eq(1,2);
    elseif ~hasTSFilter && hasTTFilter
        % Ignore all timeseries, only filtering for TT
        tsFilter = @(tsi,condition1) eq(1,2);
    end



end


ttCollection = {};
namesSubset = {};
incrementsSubset = seconds([]);
unitsSubset = string.empty();
for i = 1:numel(signalArray)
    if isa(signalArray{i},'timeseries') && tsFilter(signalArray{i},tsCondition)
        ttCollection{end+1} = timeseries2timetable(signalArray{i});
        namesSubset = [namesSubset varNames(i)];
        incrementsSubset(end+1) = increments(i);
        unitsSubset = [unitsSubset tsUnits(i)];
    elseif isa(signalArray{i},'timetable') && ttFilter(signalArray{i},ttCondition1,ttCondition2)
        ttCollection{end+1} = signalArray{i};
        incrementsSubset(end+1) = increments(i);
        namesSubset = [namesSubset varNames(i)];
        unitsSubset = [unitsSubset tsUnits(i)];
    end
end

tt = formatOutput(ttCollection,outputFormat,incrementsSubset,suppliedIncrements, namesSubset,supplied.SignalNames,signalNames, unitsSubset);

end


function out = formatOutput(collection,outputFormat,increments,suppliedIncrements, names, signalNamesSupplied, suppliedNames, units)
timetableOutput = (outputFormat == 1);
cellBySignalOutput = (outputFormat == 2);
cellByIncrementOutput = (outputFormat >= 3);

units(units == "ttPlaceholder") = [];
if ~isempty(units) && ~(cellBySignalOutput)
    % Check that ts Units are not ambiguous for synchronizing.

    units(units == "") = "seconds";
    if ~all(units(1) == units)
        error(message('MATLAB:extractTimetable:AmbiguousTSUnits'));
    end
end

if isempty(collection)
    if timetableOutput
        out =  timetable.empty();
    else
        out = {};
    end
    return
end

if timetableOutput
    try
        % get unique variable names for collection
        collection = timetable.makeUniqueVarNames(collection);
        out = [collection{:}];
    catch
        try
            % To avoid apparent duplicate rows from floating point differences
            % between timeseries (double) times stored as seconds and duration
            % stored as millis, figure out if the two are intended to be the
            % same (within floating point) using similar logic to time-based
            % subscripting.
            % 1)do they have nominally the same start?
            % 2) are they the same length?
            % 3) are the differences in the time vectors within a tolerance
            % equivalent to that defined by subscripting?
            % If so, overwrite one of the time vectors and horzcat. If that
            % fails, fall back to synchronize.
            isNearlySynchronous = true;
            for i = 2:(numel(collection))
                if isNearlySynchronous
                    isNearlySynchronous = isNearlySynchronous && isequalTime(collection{1}.Properties.RowTimes,collection{i}.Properties.RowTimes);
                else
                    break
                end
            end

            if isNearlySynchronous
                try
                    % Update the RowTimes/TimeStep. Also use the names from the
                    % trivial synchronize (above) in empties to rename variables.
                    for ii = 1:numel(collection)
                        if ismissing(increments(ii))
                            collection{ii}.Properties.RowTimes = collection{1}.Properties.RowTimes;
                        else % regular
                            collection{ii}.Properties.TimeStep = increments(1);
                        end
                    end
                    out = [collection{:}];
                catch
                    out = synchronize(collection{:},"union","fillwithmissing");
                end
            else
                out = synchronize(collection{:},"union","fillwithmissing");
            end
        catch ME
            throwAsCaller(addCause(MException(message('MATLAB:extractTimetable:SynchronizeDataError')),ME));
        end
    end
    % Flatten out any names from multi-variable timetables.
    if ~iscellstr(names) %#ok<ISCLSTR>
        names = [names{:}];
    end
    names = matlab.lang.makeUniqueStrings(names);
    names = matlab.internal.tabular.private.varNamesDim.makeValidName(names,'warnLength');
    % Also may need to modify dimnames to avoid clashes with varnames.
    % Don't warn because dimnames are not user-set here.
    [dimnames,modified] = matlab.lang.makeUniqueStrings(out.Properties.DimensionNames,names,namelengthmax);
    if any(modified)
        out.Properties.DimensionNames = dimnames;
    end
    out.Properties.VariableNames = names;

elseif cellBySignalOutput
    if ~iscellstr(names)
        names = [names{:}];
    end
    names =  matlab.internal.tabular.private.varNamesDim.makeValidName(names,'warnLength');
    namesIdx = 1;
    for i = 1:numel(collection)
        [dimnames,modified] = matlab.lang.makeUniqueStrings(collection{i}.Properties.DimensionNames,names(i),namelengthmax);
        if any(modified)
            collection{i}.Properties.DimensionNames = dimnames;
        end

        collection{i}.Properties.VariableNames = names(namesIdx:(namesIdx+width(collection{i})-1));
        namesIdx = namesIdx+width(collection{i});
    end

    if signalNamesSupplied
        out = {};
        for j = 1:numel(suppliedNames)
            out = [out collection(matches(names,suppliedNames(j)))];
        end
    else
        out = collection;
    end

elseif cellByIncrementOutput
    % sort by increment
    % loop over unique increment values list

    if isempty(suppliedIncrements)
        uincs = unique(increments);
    else
        uincs = suppliedIncrements;
    end

    out = {};
    for i = 1:numel(uincs)
        inds = uincs(i)==increments;
        subC = collection(inds);
        if isempty(subC)
            % Nothing found with this increment. Move on to the next.
            continue
        end

        try
            out{i} = [subC{:}];
        catch
            try
                out{i} = synchronize(subC{:},"union","fillwithmissing");
            catch ME
                throwAsCaller(addCause(MException(message('MATLAB:extractTimetable:SynchronizeDataError')),ME));
            end
        end

        namesSubset = names(inds);
        if ~iscellstr(namesSubset)
            namesSubset = [namesSubset{:}];
        end
        namesSubset = matlab.lang.makeUniqueStrings(namesSubset);
        [dimnames,modified] = matlab.lang.makeUniqueStrings(out{i}.Properties.DimensionNames,namesSubset,namelengthmax);
        if any(modified)
            out{i}.Properties.DimensionNames = dimnames;
        end
        namesSubset =  matlab.internal.tabular.private.varNamesDim.makeValidName(namesSubset,'warnLength');
        out{i}.Properties.VariableNames = namesSubset;

    end

    % Handle NaN increments
    nanInds = isnan(increments);
    subC = collection(nanInds);

    % Now, we rename each timetable with NaN increment individually.
    namesSubset = names(nanInds);
    for i = 1:numel(subC)
        currName = namesSubset(i);
        if ~iscellstr(namesSubset)
            currName = [namesSubset{:}];
        end
        currName = matlab.lang.makeUniqueStrings(currName);
        [dimnames,modified] = matlab.lang.makeUniqueStrings(subC{i}.Properties.DimensionNames,currName,namelengthmax);
        if any(modified)
            subC{i}.Properties.DimensionNames = dimnames;
        end
        currName = matlab.internal.tabular.private.varNamesDim.makeValidName(currName,'warnLength');
        subC{i}.Properties.VariableNames = currName;
    end
    % tack timetables with NaN increments to the end.
    out = [out subC];
end

end



function [signalArray, increments, varNames, tsUnits] = extractSignals(ds,signalNameSupplied,signalNames)

if isa(ds, 'Simulink.SimulationData.Signal')
    numSignals = 1;
    ds = {ds};
else % isa(ds, 'Simulink.SimulationData.Dataset')
    numSignals = ds.numElements;
end

% Preallocate values as empties, since we do not know how many signal values we
% will find.
signalArray = {};
increments = [];
varNames = {};
tsUnits = string.empty;
for i = 1:numSignals
    if (signalNameSupplied && ~matches(ds{i}.Name,signalNames)) || ...
            ~(isa(ds{i}, 'Simulink.SimulationData.Signal') || isa(ds{i},'timeseries') || isa(ds{i},'timetable') || isa(ds{i},'struct'))
        % Skip signal if the name isn't listed in SignalName or element is
        % not a signal.
        continue
    end


    if isa(ds{i}, 'Simulink.SimulationData.Signal')
        values = ds{i}.Values;
    else
        values = ds{i};
    end

    name = ds{i}.Name;
    % Use the default name of 'Data' if empty.
    if isempty(ds{i}.Name)
        name = 'Data';
    end

    % Leaf values can be either a timeseries, timetable, bus, or something
    % else. Recurse over each signal to pull out the values of each signal.
    [sig,inc,names,units] = getSignalsRecursion(values,name);
    signalArray = [signalArray sig];
    increments = [increments inc];
    varNames = [varNames names];
    tsUnits = [tsUnits units];
end

end


function [signalVal, incs, names, tsUnits] = getSignalsRecursion(values,SignalName)

% Inialize as empties, because we do not know how many signal values we
% will find.
signalVal = {};
incs = seconds([]);
names = {};
tsUnits = string.empty();
if isa(values, 'timeseries')
    for j = 1:numel(values)
        signalVal = [signalVal {values(j)}];
        incs(end+1) = seconds(values(j).TimeInfo.increment);
        names = [names SignalName];
        tsUnits = [tsUnits values(j).TimeInfo.Units];
    end
    return;
elseif isa(values,'timetable')
    values = {values};
end
if isa(values, 'cell')
    for j = 1:numel(values)
        if isa(values{j},'timetable')
            signalVal = [signalVal values(j)];
            if isa(values{j}.Properties.TimeStep,'duration')
                step = values{j}.Properties.TimeStep;
            else %isa(values{j}.Properties.TimeStep,calendarDuration)
                step = seconds(NaN);
            end
            incs(end+1) = step;
            tsUnits = [tsUnits "ttPlaceholder"];

            if width(values{j}) == 1
                names = [names SignalName];
            else
                names = [names {append([SignalName '.'],values{j}.Properties.VariableNames)}];
            end
        end
    end
    return;
end

for i = 1:numel(values)
    fNames = [];
    if ~isa(values,'timeseries')
        if isstruct(values(i))
            fNames = fieldnames(values(i));
        end
        for jdx=1:numel(fNames)
            f = values(i).(fNames{jdx});
            if isa(f,'timeseries')
                for k = 1:numel(f)
                    signalVal = [signalVal {f(k)}];
                    incs(end+1) = seconds(f(k).TimeInfo.increment);
                    names = [names [SignalName '.' fNames{jdx}]];
                    tsUnits = [tsUnits f(k).TimeInfo.Units];
                end
                continue;
            elseif isa(f,'timetable')
                f = {f};
            end
            if isa(f, 'cell')
                for k = 1:numel(f)
                    if isa(f{k},'timetable')
                        signalVal = [signalVal f(k)];
                        if width(f{k}) == 1
                            names = [names [SignalName '.' fNames{jdx}]];
                        else
                            names = [names {append([SignalName '.' fNames{jdx} '.'],f{k}.Properties.VariableNames)}];
                        end

                        if isa(f{k}.Properties.TimeStep,'duration')
                            step = f{k}.Properties.TimeStep;
                        else % isa(f{k}.Properties.TimeStep,'calendarDuration')
                            step = seconds(NaN);
                        end
                        tsUnits = [tsUnits "ttPlaceholder"];
                        incs(end+1) = step;
                    end
                end
            else
                [s, inc, n, u] = getSignalsRecursion(f,[SignalName '.' fNames{jdx}]);
                signalVal = [signalVal s];
                incs = [incs inc];
                names = [names n];
                tsUnits = [tsUnits u];
            end
        end
    end
end

end

function isNearlySynchronous = isequalTime(a,b)
% To avoid apparent duplicate rows from floating point differences
% between timeseries (double) times stored as seconds and duration
% stored as millis, figure out if the two are intended to be the
% same (within floating point) using similar logic to time-based
% subscripting.
% 1)do they have nominally the same start?
% 2) are they the same length?
% 3) are the differences in the time vectors within a tolerance
% equivalent to that defined by subscripting?

if ~isequal(class(a),class(b)) || isempty(a) || isempty(b)
    isNearlySynchronous = false;
    return
end

isNearlySynchronous = (a(1) == b(1)) && (length(a) == length(b));

if isNearlySynchronous
    % Determine the tolerance in the same way that we do for
    % subscripting in explicitRowTimesDim.validateNativeSubscripts.
    if isdatetime(a)
        % Absolute tolerance of 1e-12 sec for datetime subscripting.
        tol = duration.fromMillis(1e-9)*ones(size(height(a))); % 1e-12s
    else % duration
        tol = 1000*eps*max(abs(a),1e-6);
    end

    [isRegA, stepA] = isregular(a);
    [isRegB, stepB] = isregular(b);

    if ~isRegA || ~isRegB % irregular time vector

        % Check that the differences between time vectors are
        % less than the tolerance. First check that the timestep
        % is greater than the tolerance, otherwise it's all just
        % noise. This can narrow what is considered nearly synchronous.
        isNearlySynchronous = isNearlySynchronous && ...
            all(abs(min(diff(a))) > tol(1:end-1)) && ...
            all(abs(b - a) < tol);

    else % regular
        isNearlySynchronous = isNearlySynchronous && ...
            (abs(stepB) > max(tol)) && (abs(stepB) > max(tol)) && ...
            (stepA == stepB);
    end
end
end

function iseq = isequalTimeInfo(ts1,ts2)
% Check each property of the TimeInfo for equality, but use isequalTime for
% the time vector to get the same numerical tolerance used in time-based
% subscripting.
iseq = ~isempty(ts1) && ~isempty(ts2) && strcmp(ts1.Units,ts2.Units) && ...
    strcmp(ts1.Format,ts2.Format) && strcmp(ts1.Startdate,ts2.StartDate) && ...
    isequal(ts1.UserData,ts2.UserData) && isequalTime(seconds(ts1.getData),seconds(ts2.getData));
end

