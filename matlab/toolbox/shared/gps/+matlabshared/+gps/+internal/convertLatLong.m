function LatLong = convertLatLong(data,direction)
% Function to extract and convert latitude and longitude into degrees

% Copyright 2020 The MathWorks, Inc.
tempMinutes = nan;
tempDegrees = nan;
idx = find(data == '.',1);
% The latitude of format ddmm.mmm and longitude is of format dddmm.mmm. Two digits before decimal
% point is always starting of minutes
if(idx>0)
    len = strlength(data(1:idx(1)-1));
    if ( len>=4 && len <= 5)
        tempMinutes = real(str2double(data(idx(1)-2:end))/60);
        tempDegrees = real(str2double(data(1:idx(1)-3)));
    end
else
    % If no decimal point
    len = strlength(data);
    if (len>=4 && len <= 5)
        tempMinutes = real(str2double(data(end-1:end))/60);
        tempDegrees = real(str2double(data(1:end-2)));
    end
end
LatLong = tempDegrees + tempMinutes;
if ~isnan(LatLong)
    if direction == 'S' || direction == 'W'
        LatLong = -1*LatLong;
    end
end
end
