% Returns fullvalue and subsetValue as is. If numeric object, returns numeric
% converted value;

% Copyright 2015-2024 The MathWorks, Inc.

function [fullData, subsetData] = getNumericValue(fullData, subsetData)
    arguments
        fullData
        subsetData = fullData
    end
    if isobject(subsetData) && isnumeric(subsetData)
        % Handle the case where the object is a numeric sublcass
        if isa(subsetData,'single')
            fullData = single(fullData);
            subsetData = single(subsetData);
        elseif isa(subsetData, 'half')
            % Treat half as double for display purposes
            fullData = double(fullData);
            subsetData = double(subsetData);
        else
            fullData = double(fullData);
            subsetData = double(subsetData);
        end
    end
end
