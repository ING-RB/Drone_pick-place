function jsonCompatibleValue = convertMatlabDateTimeToJSONCompatible(matlabValue)
% CONVERTMATLABDATETIMETOJSONCOMPATIBLE 
% Converts a MATLAB datetime to a struct or a string when it's NAT to send
% to client side (view)

% Copyright 2017 The MathWorks, Inc.

    % Default output will keep unchanged
    jsonCompatibleValue = matlabValue;
    
    if isdatetime(matlabValue)
        if isnat(matlabValue)
            % The peernode controller doesn't handle NaT or NaN
            % We're going to check and replace NaT here  (datetime
            % NaN to represent Month, Day, Year value when date is NaT.
            jsonCompatibleValue = 'NaT';
        else
            % Convert datetime to a struct with 'year/month/day'
            jsonCompatibleValue = struct();
            jsonCompatibleValue.Month = month(matlabValue);
            jsonCompatibleValue.Day = day(matlabValue);
            jsonCompatibleValue.Year = year(matlabValue);          
        end
    end
end

