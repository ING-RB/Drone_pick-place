function bData = timeZoneAdjustment(aData,fromTZ,toTZ,useFirstRepeatedWalltime)
% Shift a time (milliseconds since epoch) from one time zone to another.

%   Copyright 2014-2022 The MathWorks, Inc.
import matlab.internal.datetime.addLeapSeconds
import matlab.internal.datetime.removeLeapSeconds
import matlab.internal.datetime.getDateFields


try 
    % fromTZ is never string, only need to convert toTZ for shallow adoption.
    toTZ = convertStringsToChars(toTZ);
    
    % If going from UTCLeapSeconds to something else, transform to the non-leap-seconds
    % timeline by removing leap seconds. This loses track of which times were originally
    % during a 60th sec, so don't do this if going from UTCLeapSeconds to itself.
    fromLeapSeconds = (fromTZ == datetime.UTCLeapSecsZoneID);
    toLeapSeconds = (toTZ == datetime.UTCLeapSecsZoneID);
    if fromLeapSeconds && ~toLeapSeconds
        aData = removeLeapSeconds(aData);
    end
    
    if isempty(fromTZ) == isempty(toTZ)
        % Zoned->zoned, or unzoned->unzoned. Don't need to account for any time zone
        % differences, internal data are either UTC or unzoned, and can stay that way.
        bData = aData;
    elseif strcmp(toTZ,'UTC') || strcmp(fromTZ,'UTC')
        % Unzoned <-> UTC preserves clockface time, so the internal value is unchanged.
        % Zoned <-> UTC is caught above.
        bData = aData;
    else
        if isempty(fromTZ) % && ~isempty(toTz)
            % Recreate the unzoned data in the specified time zone, using
            % its components. This leaves the timestamp unchanged (unless
            % it happens to fall in a "spring ahead" DST gap), but gives a
            % different actual time. First, strip off the fractional
            % seconds and then add them back at the end to avoid
            % sub-millisecond floating point errors.
            ucal = datetime.dateFields;
            aDataToSec = matlab.internal.datetime.datetimeFloor(aData,ucal.SECOND, fromTZ);
            aDataSubSec = matlab.internal.datetime.datetimeSubtract(aData,aDataToSec);
            fieldIDs = [ucal.EXTENDED_YEAR; ucal.MONTH; ucal.DAY_OF_MONTH;
                        ucal.HOUR_OF_DAY; ucal.MINUTE; ucal.SECOND];
            [y,mo,d,h,m,s] = getDateFields(aDataToSec,fieldIDs,'');
            if nargin < 4
                bData = matlab.internal.datetime.createFromDateVec({y,mo,d,h,m,s},toTZ);
            else
                % The 'useFirstRepeatedWalltime' flag is only true when datetime('now') is
                % called during the hour immediately before a "fall back" DST shift, whose
                % clockface times are the same as during the first hour after the shift.
                % createFromDateVec's default behavior is to use the second version of
                % that overlapping hour; true tells it to use the first version.
                bData = matlab.internal.datetime.createFromDateVec({y,mo,d,h,m,s},toTZ,useFirstRepeatedWalltime);
            end
            
            % Add the sub-second 
            bData = matlab.internal.datetime.datetimeAdd(bData,aDataSubSec);  %add back the sub-second time
        else % ~isempty(fromTz) && isempty(toTz)
            % Convert the zoned input array to an unzoned array, by adding the data's time
            % zone offset (raw offset plus DST) to the internal UTC value. This leaves the
            % timestamp unchanged, but gives a different actual time.
            ucal = datetime.dateFields;
            [zoneOffset,dstOffset] = getDateFields(aData,[ucal.ZONE_OFFSET ucal.DST_OFFSET],fromTZ);
            bData = matlab.internal.datetime.datetimeAdd(aData,(zoneOffset+dstOffset)*1000); % s -> ms
        end

        % Preserve Infs. These have become NaTs from NaNs in either the date/time
        % components or in the tz offsets.
        infs = isinf(aData);
        bData(infs) = aData(infs);
    end

    % Transform to the leap-seconds timeline by adding leap seconds only when going to
    % UTCLeapSeconds from something else.
    if toLeapSeconds && ~fromLeapSeconds
        if isempty(fromTZ)
            % If converting from unzoned, bData was already created in 'UTCLeapSecs', so no
            % need to add in the leap seconds.
        else
            bData = addLeapSeconds(bData);
        end
    end

catch ME
    throwAsCaller(ME);
end
