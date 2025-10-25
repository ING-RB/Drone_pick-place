function [tf,dt] = isRegularTimeVector(t,unit)
% Determine if a duration or datetime vector is regular with respect to a given
% time/date unit, i.e., has a unique non-zero time step that can be expressed
% entirely in terms of that unit and nothing larger or smaller. E.g., a time
% step of 3q is regular with respect to quarters and months but not with respect
% to years or days.
%
% Also return the time step in the specified unit.

%   Copyright 2017-2022 The MathWorks, Inc.

if nargin < 2
    unit = 'time';
elseif matlab.internal.datatypes.isScalarText(unit,false) % only one unit allowed
    componentNames = {'years' 'quarters' 'months' 'weeks' 'days' 'time'};
    unit = componentNames{...
        matlab.internal.datatypes.getChoice(...
        unit, componentNames, 'MATLAB:datetime:InvalidSingleComponent')};
else
    error(message('MATLAB:datetime:InvalidSingleComponent'));
end

haveDatetime = isa(t,'datetime');
haveDuration = isa(t,'duration');

if ~(haveDatetime || haveDuration) || ~(isvector(t) || all(size(t) == 0)) % 0x0 is a special case
    error(message('MATLAB:datetime:MustBeTimeVector'));
end

if isempty(t) || isscalar(t)
    % An empty or scalar timetable is not regular -- no well-defined time step.
    tf = false;
    if unit == "time"
        dt = duration.fromMillis(NaN);
    else
        dt = caldays(NaN); % all NaN calendarDurations are equal
    end
elseif unit == "time"
    % Find the mean time step. If the times are not sorted, this is not really
    % meaningful, but the signs of the time differences will change and the
    % tolerance test will fail anyway.
    range = t(end) - t(1);
    dtMean = range / (length(t)-1);
    
    if range == 0
        % A timetable with constant row times is not regular - no well-defined sample rate
        tf = false;
    else
        if haveDatetime
            % The time differences must be effectively equal, i.e. all close to
            % their mean, within a relative tolerance based on round-off for the
            % magnitude of the timestamps' range (as if we had a datetime origin
            % plus a duration vector). But also, the mean time step itself must
            % be large enough in a (somewhat arbitrary) absolute sense.
            tolMean = 1e-9; % 1e-12s
            tolVariation = 4*eps(abs(milliseconds(range)));
        else
            % The time differences must be effectively equal, i.e. all close to
            % their mean, within a relative tolerance based on round-off for the
            % largest timestamp. But also, the mean time step itself must be
            % large enough to avoid cases where diff(t) is [0 tiny 0 tiny ...],
            % which might pass the "effectively equal" test but is clearly not
            % regular.
            tolMean = 4*eps(max(abs(milliseconds(t))));
            tolVariation = tolMean;
        end
        tf = all(abs(milliseconds(diff(t) - dtMean)) < tolVariation) ...
          && (abs(milliseconds(dtMean)) > tolMean);
    end
    
    if tf
        dt = dtMean;
        if milliseconds(dt) < 1000
            % Display a sub-second time step as pure seconds.
            dt.Format = 's';
        end
    else
        dt = duration.fromMillis(NaN);
    end

elseif haveDatetime % and unit is a calendar unit
    % Find the unique successive differences in terms of the specified calendar
    % unit and any remaining time and split them into those components.
    try
        dt = unique(caldiff(t,{unit 'time'}));
    catch ME
        if ME.identifier == "MATLAB:datetime:mexErrors:RangeError"
            % Calendar calculations only go out 1970 +/- 2^53 ms (about 285Ky).
            % Beyond that, call it not regular.
            dt = caldays(NaN);
        else
            rethrow(ME);
        end
    end
    [dtSplit,dtSplitTime] = split(dt,{unit 'time'});
    
    % There must be a unique time step with no pure time component and a finite
    % non-zero calendar unit component.
    if isscalar(dtSplit) && (dtSplitTime == 0) && (dtSplit ~= 0) && isfinite(dtSplit)
        tf = true;
        % dt is already calculated
    else
        tf = false;
        dt = caldays(NaN);
    end
    
elseif haveDuration % and unit is a calendar unit
    % A duration time vector is never regular w.r.t. a calendar unit
    tf = false;
    dt = caldays(NaN);
end
