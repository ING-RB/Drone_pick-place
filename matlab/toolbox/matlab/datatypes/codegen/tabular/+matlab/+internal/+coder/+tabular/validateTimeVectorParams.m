function [wasSpecified,startTime,timeStep,sampleRate] = validateTimeVectorParams(...
    foundrt,startTimeIn,foundst,timeStep,foundts,sampleRateIn,foundsr)   %#codegen
% VALIDATETIMEVECTORPARAMS process the StartTime, TimeStep, and SampleRate
% parameters to the timetable constructor and other functions

%   Copyright 2019-2020 The MathWorks, Inc.

wasSpecified = true;
if foundrt     % RowTimes
    % RowTimes is mutually exclusive with SampleRate, TimeStep, and StartTime
    coder.internal.errorIf(foundsr || foundts || foundst, 'MATLAB:timetable:RowTimesParamConflict');   
    startTime = startTimeIn;
    sampleRate = sampleRateIn;
elseif foundsr   % SampleRate
    % SampleRate is mutually exclusive with TimeStep
    coder.internal.errorIf(foundts, 'MATLAB:timetable:RowTimesParamConflict');
    % SampleRate must be a scalar number, but may be negative, zero, or non-finite
    coder.internal.assert(isnumeric(sampleRateIn) && coder.internal.isConst(size(sampleRateIn)) && ...
        isscalar(sampleRateIn) && isreal(sampleRateIn), ...
        'MATLAB:timetable:InvalidSampleRate');    
    sampleRate = double(sampleRateIn);
    % StartTime is optional with SampleRate, can be a datetime or a duration
    startTime = startTimeIn;
elseif foundts   % TimeStep
    % Give a helpful error for numeric
    coder.internal.errorIf(isnumeric(timeStep), 'MATLAB:timetable:InvalidTimeStepNumeric');
    % TODO: specifying TimeStep as text not supported yet
    coder.internal.errorIf(matlab.internal.coder.datatypes.isScalarText(timeStep), ...
        'MATLAB:timetable:InvalidTimeStep');
    % duration or calendarDuration timeStep must be a scalar
    coder.internal.assert(coder.internal.isConst(size(timeStep)) && isscalar(timeStep), ...
        'MATLAB:timetable:InvalidTimeStep');
    
    % TimeStep must be a duration. CalendarDuration is not supported in
    % codegen yet
    coder.internal.assert(isa(timeStep,'duration'), ...
        'MATLAB:timetable:InvalidTimeStep');
    
    
    % StartTime is optional with TimeStep
    if ~foundst % default StartTime is seconds(0)
        % The row times will take on StartTime's display format. If that
        % is not supplied, the default format is 's', which is good for
        % sub-second sampling, but if TimeStep has another format, use
        % that instead. Otherwise, if TimeStep is a whole number of seconds,
        % use a timer format.
        
        % When changing duration format, the length of the format char
        % vector may change. This will result in the Format property
        % becoming variable sized, and thus the entire duration cannot be
        % made constant. It is better to create a new duration and specify
        % the new format.
        secs = seconds(timeStep);
        if ~strcmp(timeStep.Format,'s')
            startTime = duration(0,0,seconds(startTimeIn),'Format',timeStep.Format); 
        elseif round(secs) == secs
            startTime = duration(0,0,seconds(startTimeIn),'Format','hh:mm:ss'); 
        else
            startTime = startTimeIn;
        end
    else
        startTime = startTimeIn;
    end
    sampleRate = sampleRateIn;

else % neither RowTimes, nor TimeStep, nor SampleRate was provided
    wasSpecified = false;
    startTime = startTimeIn;
    sampleRate = sampleRateIn;
end

% By now, if StartTime has been supplied, it must have been with TimeStep or SampleRate
if foundst % && ~supplied.RowTimes
    % Give a helpful error for numeric
    coder.internal.errorIf(isnumeric(startTime), 'MATLAB:timetable:InvalidStartTimeNumeric');
    % TODO: specifying StartTime as text not supported yet
    coder.internal.errorIf(matlab.internal.coder.datatypes.isScalarText(startTime), ...
        'MATLAB:timetable:InvalidStartTime');  
    % StartTime must be a scalar duration or datetime
    coder.internal.assert(coder.internal.isConst(size(startTime)) && isscalar(startTime) ...
        && (isa(startTime,'datetime') || isa(startTime,'duration')), 'MATLAB:timetable:InvalidStartTime');
    % Make sure a calendarDuration TimeStep has a datetime StartTime
    %if supplied.TimeStep && isa(timeStep,'calendarDuration') && ~isa(startTime,'datetime')
    %    error(message('MATLAB:timetable:DurationStartTimeWithCalDurTimeStep'));
    %end
end
