% Convert a given string duration, like "3 sec" or "1 month", into a duration.
%
% Motivation: One cannot call `duration("3 sec")`, as that results in an error.
% This function painlessly converts a string duration (using an accompanying
% format character that matches the format in the string duration) into a duration.
function newDuration = convertStringUnitDurationToDuration(stringDuration, durationFormat, useHHMMSSFormat)
    arguments
        stringDuration string
        durationFormat char {mustBeMember(durationFormat, {'s', 'm', 'h', 'd', 'y'})}
        useHHMMSSFormat logical = false
    end

    splitDuration = strsplit(stringDuration, ' ');
    quantity = double(string(splitDuration(1))); % Grab the number from the unit duration

    switch durationFormat
        case 's'
            newDuration = seconds(quantity);
        case 'm'
            newDuration = minutes(quantity);
        case 'h'
            newDuration = hours(quantity);
        case 'd'
            newDuration = days(quantity);
        case 'y'
            newDuration = years(quantity);
    end

    if useHHMMSSFormat
        newDuration.Format = 'hh:mm:ss';
    end
end