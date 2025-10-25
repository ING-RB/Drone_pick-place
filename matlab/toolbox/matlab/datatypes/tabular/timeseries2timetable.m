function t = timeseries2timetable(ts, varargin)
%

%   Copyright 2020-2024 The MathWorks, Inc.

import matlab.lang.makeUniqueStrings;
import matlab.internal.tabular.private.varNamesDim.makeValidName;
import matlab.internal.datatypes.ordinalString;

if ~isa(ts,'timeseries')
    error(message("MATLAB:timeseries2timetable:InputType"));
end

numTS = nargin;
if ~isscalar(ts) && numTS > 1
    error(message("MATLAB:timeseries2timetable:NonscalarInput"));
end

if ~isscalar(ts) && isequal(numTS,1)
    if isempty(ts)
        error(message("MATLAB:timeseries2timetable:EmptyTimeseriesArray"));
    end
    
    % If a non-scalar input is given, the number of time series is redefined
    % as the number of elements in the non-scalar input.
    numTS = numel(ts);
    varargin = num2cell(ts(2:end));
    ts = ts(1);
end

% Preallocate memory for the relevant time series properties that will be
% used to construct the timetable.
tsStruct.VariableNames = cell(1,numTS);
tsStruct.Variables = cell(1,numTS);
tsStruct.VariableContinuity = matlab.tabular.Continuity("unset");
tsStruct.VariableUnits = cell(1,numTS);
tsStruct.HasUnits = false;
tsStruct.UserData = [];
tsStruct.Events = cell(1,numTS);
tsStruct.IgnoreEvents = false(1,numTS);
tsStruct.IgnoreQuality = false;

tsStruct = extractAndValidateTS(ts,1,tsStruct);

% The row dimension to reference. If more than one time series is given, all
% row dimensions should match the reference.
numRows = size(tsStruct.Variables{1},1);

for i = 1:(numTS-1)
    ts_i = varargin{i};

    % Array inputs are only supported for the single input syntax.
    if ~isscalar(ts_i) || ~isa(ts_i,'timeseries')
        error(message("MATLAB:timeseries2timetable:NonscalarInput"));
    end

    tsStruct = extractAndValidateTS(ts_i,i+1,tsStruct);
    
    % Check for row dimension mismatch.
    if ~isequal(numRows, size(tsStruct.Variables{i+1},1))
        error(message("MATLAB:timeseries2timetable:NumberOfRowsMismatch"));
    end

    % Check that time vector matches all inputs.
    sameTimes = isequal(ts.Time,ts_i.Time);
    sameUnits = isequal(ts.TimeInfo.Units,ts_i.TimeInfo.Units);
    sameStartDate = isequal(ts.TimeInfo.StartDate,ts_i.TimeInfo.StartDate);
    if ~sameTimes || ~sameUnits || ~sameStartDate
        error(message("MATLAB:timeseries2timetable:TimeVectorMismatch"));
    end
end

tsStruct.VariableNames = makeUniqueStrings(tsStruct.VariableNames);
tsStruct.VariableNames = makeValidName(tsStruct.VariableNames,"warnLength");

% Generate the output timetable according to the time series's data.
if isnan(ts.TimeInfo.Increment) % explicit rowtime timetable
    time = tsTimeToDuration(ts.Time,ts.TimeInfo.Units);
    if ~isempty(ts.TimeInfo.StartDate)
        % timeseries validates that StartDate must be a datestr.
        d = datetime(ts.TimeInfo.StartDate);
        time = d+time;
    end
    t = timetable.init(tsStruct.Variables,numRows,time,numTS,tsStruct.VariableNames);
else % optimized regular timetable
    starttime = tsTimeToDuration(ts.TimeInfo.Start,ts.TimeInfo.Units);
    if ~isempty(ts.TimeInfo.StartDate)
        starttime = datetime(ts.TimeInfo.StartDate)+starttime;
    end
    timestep = tsTimeToDuration(ts.TimeInfo.Increment,ts.TimeInfo.Units);

    % Always use timestep rather than sample rate.
    t = timetable.initRegular(tsStruct.Variables,numRows,starttime,timestep,[],numTS,tsStruct.VariableNames);
end

t.Properties.VariableContinuity = tsStruct.VariableContinuity;

if tsStruct.HasUnits
    t.Properties.VariableUnits = tsStruct.VariableUnits;
end

t.Properties.UserData = tsStruct.UserData;

if ~all(cellfun(@isempty,tsStruct.Events)) % At least one time series contains events.
    try
        tsStruct.Events = vertcat(tsStruct.Events{:}); % Collect all events as a struct.
        et = tsEvents2eventtable(tsStruct.Events);     % Effectively "struct2eventtable".
        t.Properties.Events = sortrows(et);            % Consistent with timetable.
    catch ME % Inconsistent time conventions. Ignore events.
        msgid = ME.identifier;
        if strcmp(msgid,"MATLAB:timetable:InvalidEventsIncompatibleType")
            tsStruct.IgnoreEvents = true;
        end
    end
end

if any(tsStruct.IgnoreEvents) % Only due to inconsistent time conventions.
    % Find the positions of the inputs with invalid events.
    idx = num2cell(find(tsStruct.IgnoreEvents));

    % Convert positional values (i.e., indices) to workspace names or
    % ordinal strings if workspace names are unavailable.
    try
        namesOrPositions = cellfun(@inputname, idx, UniformOutput=false);
    catch % Assume MATLAB:inputname:argNumberNotValid.
        namesOrPositions = cellfun(@ordinalString, idx, UniformOutput=false);
    end

    % Collect information about bad time series inputs as a single string.
    badInputs = "";
    for i = 1:length(namesOrPositions)-1
        badInputs = badInputs + namesOrPositions{i} + ", ";
    end
    badInputs = badInputs + namesOrPositions(end);

    % Provide information about any invalid time series events to the user.
    warning(message("MATLAB:timeseries2timetable:IgnoringEvents", badInputs));
end

if tsStruct.IgnoreQuality
    warning(message("MATLAB:timeseries2timetable:IgnoringQuality"));
end
end


%% HELPER FUNCTIONS
% ------------------------------------------------------------------------------
function s = extractAndValidateTS(ts,i,s)
    if ~isempty(ts.Events) && ~s.IgnoreEvents(i)
        try
            tsEvents = extracttsEvents(ts);
            s.Events{i} = validatetsEvents(tsEvents);
        catch ME % Invalid time units.
            s.IgnoreEvents(i) = true;
        end
    end
    
    if ~isempty(ts.Quality)
        s.IgnoreQuality = true;
    end
    
    varname = (ts.Name);
    if isempty(varname) || isequal(varname,"unnamed")
        varname = 'Data';
    end
    s.VariableNames{i} = varname;
    
    data = ts.Data;
    if ~ts.IsTimeFirst % For timetable, time is always the first dimension.
        data = tsReorientData(data, length(ts.Time));
    end
    
    s.VariableContinuity(i) = interpolation2Continuity(getinterpmethod(ts));
    if isempty(s.UserData) % Take first non-empty
        s.UserData = ts.UserData;
    end

    units = ts.DataInfo.Units;
    if isempty(units)
        s.VariableUnits{i} = '';
    else
        s.HasUnits = true;
        s.VariableUnits(i) = transferUnits(units);
    end
    
    s.Variables{i} = data;
    
    if isempty(ts.Time)
        error(message("MATLAB:timeseries2timetable:EmptyTimeVector"));
    end
end

% ------------------------------------------------------------------------------
function time = tsTimeToDuration(time,units)
    if isempty(units)
        time = seconds(time);
    else
        % Timeseries.TimeInfo.Units can be set to anything, but has a
        % documented list of allowed values.
        if ~matlab.internal.datatypes.isScalarText(units)
            error(message('MATLAB:timeseries2timetable:InvalidTimeUnit'))
        elseif ~isnumeric(time)
            error(message('MATLAB:timeseries2timetable:InvalidTime'));
        end
        switch units
            case 'weeks'
                time = days(7*time);
            case 'days'
                time = days(time);
            case 'hours'
                time = hours(time);
            case 'minutes'
                time = minutes(time);
            case 'seconds'
                time = seconds(time);
            case 'milliseconds'
                time = milliseconds(time);
            case 'microseconds'
                time = milliseconds(1e-3*time);
            case 'nanoseconds'
                time = milliseconds(1e-6*time);
            otherwise
                error(message('MATLAB:timeseries2timetable:InvalidTimeUnit'))
        end
    end

    % Leave the (duration) time's single-unit format alone, i.e. as the default for
    % the unit. For a timeseries with a StartDate, the format of this duration is
    % dropped when adding to the StartDate datetime, and for a timeseries without a
    % StartDate (leading to a duration timetable), the single-unit duration format
    % is likely to be more useful than any format set in the timeseries TimeInfo.
    % No duration-like datestr-style format from the timeseries (e.g. MM:SS or SS.FFF)
    % is legal for a duration, so would need to be translated. And any datestr-style
    % format probably made no sense for the duration-like Time property of a timeseries
    % to begin with because, e.g., SS only counts up to 59 before wrapping back to 0.
end

% ------------------------------------------------------------------------------
function cont = interpolation2Continuity(interp)
    switch interp
        case ""
            cont = matlab.tabular.Continuity("unset");
        case "linear"
            cont = matlab.tabular.Continuity("continuous");
        case "zoh"
            cont = matlab.tabular.Continuity("step");
        otherwise
            error(message('MATLAB:timeseries2timetable:InvalidInterpMethod'));
    end
end

% ------------------------------------------------------------------------------
function data = tsReorientData(data, len)
    if len > 1
        data = permute(data, circshift(1:ndims(data),1));
    else
        % For a single sample, the last dimension (representing time) is
        % missing because trailing singleton dimensions are cropped. For
        % example, logging a row vector for one sample results in 1x3x1 and
        % the trailing singleton dimension is cropped: 1x3. Adding the
        % leading dimension to represent time results in a 1x1x3. Note that
        % aligning time with the first dimension results in a 1xN array for
        % column vectors because we are left with a 1x3x1 and the last
        % singleton dimension is cropped.
        data = reshape(data, [1 size(data)]);
    end
end

% ------------------------------------------------------------------------------
function ttUnit = transferUnits(units)
    if isa(units,"Simulink.SimulationData.Unit")
        if isscalar(units)
            ttUnit = {units.Name};
        else
            error(message("MATLAB:timeseries2timetable:InvalidUnit"))
        end
    elseif matlab.internal.datatypes.isScalarText(units)
        ttUnit = {convertStringsToChars(units)};
    else
        error(message("MATLAB:timeseries2timetable:InvalidUnit"))
    end
end

% ------------------------------------------------------------------------------
function tsEvents = extracttsEvents(ts)
    % EXTRACTTSEVENTS Parses the events in a time series input.

    % The number of events in each time series. This number need not be
    % uniform across time series inputs.
    numEvents = length(ts.Events);

    % Preallocate memory to store the event information that will be used to
    % generate the event table.
    tsEvents = struct("EventTimes",  {}, ...
                      "StartDates",  {}, ...
                      "TimeUnits",   {}, ...
                      "EventLabels", {}, ...
                      "EventData",   {});
    
    for j = 1:numEvents
        event_j = ts.Events(j);
        
        % Event times are temporarily stored as numeric values but will be
        % converted to duration values later.
        tsEvents(j,1).EventTimes = event_j.Time;

        % Start dates are captured and converted to datetime.
        if ~isempty(event_j.StartDate)
            tsEvents(j,1).StartDates = datetime(event_j.StartDate);
        end

        % Capture the event time units and check for uniformity later.
        tsEvents(j,1).TimeUnits = string(event_j.Units);

        % Event names will become the event labels of the event table.
        if ~isempty(event_j.Name)
            tsEvents(j,1).EventLabels = string(event_j.Name);
        else
            tsEvents(j,1).EventLabels = missing;
        end

        % Event data will be interpreted as an additional variable of the
        % event table.
        if ~isempty(event_j.EventData)
            tsEvents(j,1).EventData = event_j.EventData;
        else
            tsEvents(j,1).EventData = missing;
        end
    end
end

function tsEventsOut = validatetsEvents(tsEventsIn)
    % VALIDATETSEVENTS Validates the information obtained from one or more
    % time series events.

    % Copy the event labels.
    tsEventsOut.EventLabels = vertcat(tsEventsIn.EventLabels);

    % Attempt to convert the event time information to duration if the
    % units are valid.
    units = vertcat(tsEventsIn.TimeUnits);
    if all(units(1) == units)
        eventTimes = vertcat(tsEventsIn.EventTimes);
        tsEventsOut.EventTimes = tsTimeToDuration(eventTimes,units(1));
        
        % The event times become date times if the start dates are
        % non-empty.
        startDates = vertcat(tsEventsIn.StartDates);
        if ~isempty(startDates)
            tsEventsOut.EventTimes = startDates + tsEventsOut.EventTimes;
        end
    else
        error(message("MATLAB:timeseries2timetable:TimeInfoNotUniform"));
    end

    try % Assume uniform event data.
        tsEventsOut.EventData = vertcat(tsEventsIn.EventData);
    catch ME % Handle non-uniform event data.
        tsEventsOut.EventData = {tsEventsIn.EventData}';
    end
end

function et = tsEvents2eventtable(tsEvents)
    % TSEVENTS2EVENTTABLE Converts information from time series events to
    % an event table with variables "EventLabels" and "EventData".

    if ~isempty(tsEvents)
        % Gather row times and labels.
        eventTimes = vertcat(tsEvents(:).EventTimes);
        etVars = {vertcat(tsEvents(:).EventLabels)};
        etLabels = {'EventLabels'};
        
        if ~all(cellfun(@isempty, {tsEvents(:).EventData}))
            try % Assume uniform event data.
                etVars{2} = vertcat(tsEvents(:).EventData);
            catch ME % Handle non-uniform event data.
                % If the event data is not uniform we need to manually walk
                % through it.
                eventData = {};
                for i = 1:numel(tsEvents)
                    if iscell(tsEvents(i).EventData)
                        % If the event data is already a cell array we can
                        % tack it on.
                        eventData = [eventData;tsEvents(i).EventData];
                    else
                        % If the event data is not a cell array we convert
                        % each element to a cell using num2cell first.
                        eventData = [eventData;num2cell(tsEvents(i).EventData)];
                    end
                end
                etVars{2} = eventData;
            end
            etLabels{2} = 'EventData';
        end
        et = eventtable.init(eventTimes, etVars, etLabels);
        if strcmp(class(et.EventData), "missing")
            et.EventData = []; % Discard event data if all missing.
        end
    else % No events.
        et = eventtable.empty();
    end
end
