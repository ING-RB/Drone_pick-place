function [wasSpecified,rowTimes,startTime,timeStep,sampleRate] = validateTimeVectorParams(supplied,rowTimes,startTime,timeStep,sampleRate,callerFcn)
% VALIDATETIMEVECTORPARAMS process the StartTime, TimeStep, and SampleRate
% parameters to the timetable constructor and other functions

%   Copyright 2017-2021 The MathWorks, Inc.
import matlab.internal.datatypes.isScalarText
import matlab.internal.datetime.text2timetype

if nargin < 6
    % Assume timetable as the default caller. This flag is mainly used to
    % determine if we should allow vector inputs for SampleRate and TimeStep and
    % also throw caller specific error messages.
    callerFcn = 'timetable';
end

% extractTimetable allows vector inputs for SampleRate and TimeStep.
allowNonScalarInputs = (callerFcn == "extractTimetable");

try %#ok<ALIGN>
wasSpecified = true;
if supplied.RowTimes
    if supplied.SampleRate || supplied.TimeStep || supplied.StartTime
        % RowTimes is mutually exclusive with SampleRate, TimeStep, and StartTime
        error(message('MATLAB:timetable:RowTimesParamConflict'));
    end
elseif supplied.SampleRate
    if supplied.TimeStep % already caught SampleRate+RowTimes
        % SampleRate is mutually exclusive with TimeStep
        error(message('MATLAB:timetable:RowTimesParamConflict'));
    elseif ~(isnumeric(sampleRate) && isreal(sampleRate)) || ~(isscalar(sampleRate) || (allowNonScalarInputs && isvector(sampleRate)))
        % SampleRate must be a scalar number, but may be negative, zero, or non-finite
        error(message(append('MATLAB:',callerFcn,':InvalidSampleRate')));
    end
    sampleRate = double(sampleRate);
    % StartTime is optional with SampleRate, can be a datetime or a duration
elseif supplied.TimeStep
    % Already caught TimeStep+RowTimes or TimeStep+SampleRate
    if isnumeric(timeStep)
        % Give a helpful error for numeric
        error(message('MATLAB:timetable:InvalidTimeStepNumeric'));
    elseif isScalarText(timeStep)
        timeStep = text2timetype(timeStep,'MATLAB:datetime:InvalidTextInput');
        % This falls through to the duration or calendarDuration cases.
    elseif ~(isscalar(timeStep) || (allowNonScalarInputs && isvector(timeStep)))
        % duration or calendarDuration timeStep must be a scalar
        error(message(append('MATLAB:',callerFcn,':InvalidTimeStep')));
    end
    if isa(timeStep,'duration')
        % StartTime is optional with TimeStep
        if ~supplied.StartTime % default StartTime is seconds(0)
            % The row times will take on StartTime's display format. If that
            % is not supplied, the default format is 's', which is good for
            % sub-second sampling, but if TimeStep has another format, use
            % that instead. Otherwise, if TimeStep is a whole number of seconds,
            % use a timer format.
            secs = seconds(timeStep);
            if timeStep.Format ~= "s"
                startTime.Format = timeStep.Format;
            elseif round(secs) == secs
                startTime.Format = 'hh:mm:ss';
            end
        end
    elseif isa(timeStep,'calendarDuration')
        % StartTime is required if TimeStep is a calendarDuration
        if ~supplied.StartTime
            error(message('MATLAB:timetable:DurationStartTimeWithCalDurTimeStep'));
        end
        % A calendarDuration TimeStep must be "pure", only one unit, but allow a
        % zero, NaN, or Inf calendarDuration time step (even though it will not be
        % useful for anything).
        [m,d,t] = split(timeStep,{'months' 'days' 'time'});
        if (sum((m~=0) + (d~=0) + (t~=0)) > 1) && isfinite(timeStep)
            error(message('MATLAB:timetable:ImpureCalDurTimeStep'));
        end
    else
        % TimeStep must be a duration or calendarDuration
        error(message(append('MATLAB:',callerFcn,':InvalidTimeStep')));
    end
else % neither RowTimes, nor TimeStep, nor SampleRate was provided
    wasSpecified = false;
end

% By now, if StartTime has been supplied, it must have been with TimeStep or SampleRate
if supplied.StartTime % && ~supplied.RowTimes
    if isnumeric(startTime)
        % Give a helpful error for numeric
        error(message('MATLAB:timetable:InvalidStartTimeNumeric'));
    elseif isScalarText(startTime)
        startTime = text2timetype(startTime,'MATLAB:datetime:InvalidTextInput');
        % Falls through to datetime check
    elseif ~isscalar(startTime) || ~(isa(startTime,'datetime') || isa(startTime,'duration'))
        % TimeStep must be a scalar duration or datetime
        error(message('MATLAB:timetable:InvalidStartTime'));
    end
    % Make sure a calendarDuration TimeStep has a datetime StartTime
    if supplied.TimeStep && isa(timeStep,'calendarDuration') && ~isa(startTime,'datetime')
        error(message('MATLAB:timetable:DurationStartTimeWithCalDurTimeStep'));
    end
end

catch ME, throwAsCaller(ME); end
