function that = dateshift(this,whereTo,unit,rule)
%

%   Copyright 2014-2024 The MathWorks, Inc.

import matlab.internal.datetime.getDayNames
import matlab.internal.datetime.datetimeSubtract
import matlab.internal.datatypes.isScalarText;
import matlab.internal.datatypes.isIntegerVals;
import matlab.internal.datatypes.isScalarInt;
import matlab.internal.datatypes.getChoice;

ucal = datetime.dateFields;
thisData = this.data;
tz = this.tz;

% Not enough input arguments.
if nargin < 3
    error(message('MATLAB:datetime:dateshift:NotEnoughInputs'));
end

% Only unit needs to be converted into char.
if nargin > 2
    unit = convertStringsToChars(unit);
    if isnumeric(unit)
        unit = double(unit);
    end
end

isIntegerRule = false;
isNearest = false;

if nargin == 4
    % If rule is a set of integers, we do not need to do more here.
    if isnumeric(rule)
        rule = double(rule);
    end
    isIntegerRule = isIntegerVals(rule);
    % Otherwise, we need to parse if rule is either "current", "next",
    % "previous", or "nearest". We then convert rule to the correct
    % corresponding integer.
    if ~isIntegerRule
        rule = getChoice(rule,["current","next","previous","nearest"],'MATLAB:datetime:dateshift:InvalidRule');
    end
end
whereTo = getChoice(whereTo,["start" "end" "dayofweek"],"MATLAB:datetime:dateshift:InvalidWhereTo");
if (whereTo == 1) || (whereTo == 2) % 'start', 'end'
    % Accept plurals to allow other functions to pass through their plural inputs, but accept singular as partial
    % match (only the singular form is documnted).
    unit = getChoice(unit,["years" "quarters" "months" "weeks" "days" "hours" "minutes" "seconds"], ...
        ["MATLAB:datetime:dateshift:InvalidUnit" "MATLAB:datetime:dateshift:AmbiguousUnit"]);

    % Figure out how many units to shift ahead or back.
    if isIntegerRule
        if isscalar(rule)
            rule = repmat(rule,size(thisData));
        elseif isscalar(thisData)
            thisData = repmat(thisData,size(rule));
        elseif ~isequal(size(thisData),size(rule))
            error(message('MATLAB:datetime:dateshift:InputSizeMismatch'));
        end

        % Move n units from the current unit.
        n = rule;

    elseif (nargin < 4) || rule == 1 % rule = 'current'
        % Already in current unit.
        n = 0;
    elseif rule == 2 % rule = 'next'
        n = 1;
    elseif rule == 3 % rule = 'previous'
        n = -1;
    elseif rule == 4 % rule = 'nearest'
        % First look at the start of current unit (or end/prev), will compare to start of
        % next (or end/current) below.
        n = 0;
        isNearest = true;
    else
        error(message('MATLAB:datetime:dateshift:InvalidRule'));
    end

    if whereTo == 2 && ~isNearest % 'end', but not for nearest
        % Shift ahead one extra unit for 'end'. The shift to that unit's beginning below
        % will be the desired position for second, minute, hour, day, but will be one day
        % ahead of the desired position for week, month, quarter, year. Fix that below.
        n = n + 1;
    end

    fieldIDs = [ucal.EXTENDED_YEAR;
                ucal.QUARTER;
                ucal.MONTH;
                ucal.WEEK_OF_YEAR;
                ucal.DAY_OF_MONTH;
                ucal.HOUR_OF_DAY;
                ucal.MINUTE;
                ucal.SECOND];
    fieldID = fieldIDs(unit);

    % Shift to the desired unit, or to the first (earlier) candidate for 'nearest'
    [thatData,thisDataFloor] = shifttoDestination(thisData,n,unit,whereTo,fieldID,tz);

    if isNearest % rule == 'nearest'
        % Already looked at the start of the current unit (or end/prev), now look at the
        % second (later) candidate, i.e. start of the next (or end/current) unit. Reuse
        % start of current unit to save work for non-calendar units.
        thatData2 = shifttoDestination(thisData,1,unit,whereTo,fieldID,tz,thisDataFloor);
        
        % Shift to the nearer of the two.
        dBackwards = datetimeSubtract(thisData,thatData,true); % full precision in the inner subtractions
        dForwards = datetimeSubtract(thatData2,thisData,true);
        k = datetimeSubtract(dForwards,dBackwards) <= 0; % elements closer (or equal) to next start (or current end) than current start (or prev end)
        thatData(k) = thatData2(k);
    end

elseif (whereTo == 3) % 'dayofweek'
    dow = unit;
    if isScalarText(unit)
        dow = getChoice(dow,[getDayNames('short') getDayNames('long') 'weekday' 'weekend'],[1:7 1:7 23456 17], ...
            ["MATLAB:datetime:dateshift:InvalidDOW" "MATLAB:datetime:dateshift:AmbiguousDOW"]);
    elseif isScalarInt(dow,1,7)
        % OK
    else
        error(message('MATLAB:datetime:dateshift:InvalidDOW'));
    end

    [thisDay,thisDow] = matlab.internal.datetime.getDateFields(thisData,[ucal.DAY_OF_MONTH ucal.DAY_OF_WEEK],tz);
    nonFinites = ~isfinite(thisData);
    if any(nonFinites)
        % thisDay and thisDow are (correctly) NaN for NaT or Inf datetimes. Set thisDay to
        % NaN or Inf for the desired NaT or Inf result, and set thisDow to an arbitrary
        % value to allow it to flow through without any effect on thisDay.
        thisDay(nonFinites) = thisData(nonFinites);
        thisDow(nonFinites) = 1;
    end
    
    if dow <= 7 % specified day
        if isIntegerRule
            if isscalar(rule)
                rule = repmat(rule,size(thisData));
            elseif isscalar(thisData) % && ~isscalar(rule)
                thisData = repmat(thisData,size(rule));
                thisDay = repmat(thisDay,size(rule));
                thisDow = repmat(thisDow,size(rule));
            elseif ~isequal(size(thisData),size(rule))
                error(message('MATLAB:datetime:dateshift:InputSizeMismatch'));
            end
            sgn = sign(rule);
            thatDay = thisDay + sgn.*mod(sgn.*(dow-thisDow),7) + 7*(rule-sgn); % n'th occurrence on or after/before
            k = (rule == 0);
            if any(k(:))
                thatDay(k) = thisDay(k) - thisDow(k) + dow; % occurrence during current week
            end
        elseif (nargin < 4) || (rule == 2) % rule = 'next'
            thatDay = thisDay + mod(dow-thisDow,7); % 1st occurrence on or after
        elseif rule == 1 || isequal(rule,0) % rule = 'current'
            thatDay = thisDay - thisDow + dow; % occurrence during current week
        elseif rule == 3 % rule = 'previous'
            thatDay = thisDay - mod(-(dow-thisDow),7); % 1st occurrence on or before
        elseif rule == 4 % rule = 'nearest'
            ndays = mod(dow-thisDow,7);
            thatDay = thisDay + ndays - 7*(ndays>3);
        else
            error(message('MATLAB:datetime:dateshift:InvalidRule'));
        end
    else % 'weekday' or 'weekend'
        if isIntegerRule
            if any(rule == 0,'all')
                error(message('MATLAB:datetime:dateshift:InvalidNumericRuleForWeekDayWeekEnd'));
            elseif isscalar(rule)
                rule = repmat(rule,size(thisData));
            elseif isscalar(thisData) % && ~isscalar(rule)
                thisData = repmat(thisData,size(rule));
                thisDay = repmat(thisDay,size(rule));
                thisDow = repmat(thisDow,size(rule));
            elseif ~isequal(size(thisData),size(rule))
                error(message('MATLAB:datetime:dateshift:InputSizeMismatch'));
            end
            % Flip the week and work in its mirror image if the rule is negative; that will be
            % backed out at the end.
            sgn = sign(rule);
            rule = abs(rule);
            thisDow(sgn<0) = 8 - thisDow(sgn<0);
            if dow == 23456 % weekday
                % Starting from a monday, weekdays are contiguous for five days, then skip two, etc.
                % Calculate the necessary date shift as if "this" was a monday; that will be backed out
                % at the end.
                ruleAdjustment = [0 0 1 2 3 4 5]; % number of weekdays back to previous or current monday
                offset = (rule-1) + ruleAdjustment(thisDow); % number of weekdays from the "anchor" monday to desired day
                nWorkWeeks = fix(offset/5);
                nWorkDays = offset - 5*nWorkWeeks; % always <= 4
                % Move forward from the anchor monday by whole weeks, then to the desired weekday,
                % then back up to account for having started from the anchor monday.
                adjust = 7*nWorkWeeks + nWorkDays - (thisDow - 2);
            else % dow == 17, weekend
                % Starting from a saturday, weekends are contiguous for two days, then skip five days,
                % etc. Calculate the necessary date shift as if "this" a saturday; that will be backed
                % out at the end.
                ruleAdjustment = [1 2 2 2 2 2 0]; % number of weekend days back to previous or current saturday
                offset = (rule-1) + ruleAdjustment(thisDow); % number of weekend days from the "anchor" saturday to desired day
                nWeekends = fix(offset/2);
                nWeekendDays = offset - 2*nWeekends; % always <= 1
                % Move forward from the anchor saturday by whole weeks, then to the desired weekend day,
                % then back up to account for having started from the anchor saturday.
                adjust = 7*nWeekends + nWeekendDays - mod(thisDow,7);
            end
            % Negate the date shift to account for using the mirror image for negative rules.
            adjust = sgn .* adjust;
        elseif (nargin < 4) || (rule == 2) % rule = 'next'
            if dow == 23456 % weekday
                adjust = [1 0 0 0 0 0 2]; adjust = adjust(thisDow); % 1st occurrence on or after
            else
                adjust = [0 5 4 3 2 1 0]; adjust = adjust(thisDow); % 1st occurrence on or after
            end
        elseif rule == 3 % rule = 'previous'
            if dow == 23456 % weekday
                adjust = [-2 0 0 0 0 0 -1]; adjust = adjust(thisDow); % 1st occurrence on or before
            else
                adjust = [0 -1 -2 -3 -4 -5 0]; adjust = adjust(thisDow); % 1st occurrence on or before
            end
        elseif rule == 4 % rule = 'nearest'
            if dow == 23456 % weekday
                adjust = [1 0 0 0 0 0 -1]; adjust = adjust(thisDow);
            else
                adjust = [0 -1 -2 -3 2 1 0]; adjust = adjust(thisDow); % wed goes to sun, but adjust wed pm to go to (next) sat
                isWedPM = (thisDow == 4) & (matlab.internal.datetime.getDateFields(thisData,ucal.AM_PM,tz) == 1);
                thisDay(isWedPM) = thisDay(isWedPM) + 6;
            end
        elseif (rule == 1)
            error(message('MATLAB:datetime:dateshift:InvalidRuleForWeekDayWeekEnd'));
        else
            error(message('MATLAB:datetime:dateshift:InvalidRule'));
        end
        thatDay = thisDay + reshape(adjust,size(thisDay));
    end
    thatData = matlab.internal.datetime.setDateField(thisData,thatDay,ucal.DAY_OF_MONTH,tz);
end

that = this;
that.data = thatData;


%-----------------------------------------------------------------------------------------
function [thatData,thisDataFloor] = shifttoDestination(thisData,n,unit,whereTo,fieldID,tz,thisDataFloor)
import matlab.internal.datetime.addToDateField
import matlab.internal.datetime.datetimeFloor
import matlab.internal.datetime.datetimeSubtract

if unit <= 5 % years, quarters, months, weeks, days
    % For calendar arithmetic, first shift to the desired destination unit, but not
    % necessarily to its beginning (yet).
    thatData = thisData; % in case all(n==0)
    if any(n~=0), thatData = addToDateField(thisData,n,fieldID,tz); end

    % Once in the correct destination unit, move back to its beginning. Doing that
    % only after shifting into the destination ensures that the result is at the
    % beginning of the destination unit, e.g. for cases where the unit is day and the
    % source day had no midnight (because of a DST "spring ahead"),
    thatData = datetimeFloor(thatData,fieldID,tz);

    % End of week, month, quarter, year: back up to the start of last day of previous
    % week, month, quarter, year.
    if whereTo==2 && unit<=4
        ucal = datetime.dateFields;
        thatData = addToDateField(thatData,-1,ucal.DAY_OF_MONTH,tz);
        thatData = datetimeFloor(thatData,ucal.DAY_OF_MONTH,tz); % in case EOW/M/Q/Y had no midnight
    end

    if nargout > 1, thisDataFloor = []; end % not used for calendar units

else % hours, minutes, seconds
    % For exact time arithmetic, move to the beginning of the current unit first, then
    % shift the required number of units. This has the effect of doing the shift "in"
    % the original UTC offset, and if necessary standardizing the timestamp afterwards.
    % Reuse start of current unit if passed in, to save some work.
    if nargin < 7, thisDataFloor = datetimeFloor(thisData,fieldID,tz); end
    thatData = thisDataFloor; % in case all(n==0)
    if any(n~=0), thatData = addToDateField(thatData,n,fieldID,tz); end
end
