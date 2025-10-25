% Gets the scaling factor from the data string

% Copyright 2017-2023 The MathWorks, Inc.

function scalingFactor = getScalingFactorFromDataString(dataString)
    scalingFactor = regexp(dataString,'\s*[0-9]+\.[0-9e+-]*?\s\*', 'match');
end
