% Gets the scaling factor

% Copyright 2017-2023 The MathWorks, Inc.

function scalingFactorString = getScalingFactor(fullData)
    f = internal.matlab.datatoolsservices.FormatDataUtils.getCurrentNumericFormat();
    if (isinteger(fullData) && isreal(fullData)) || islogical(fullData) || ~any(strcmp({'long','short'}, f))
        scalingFactorString = strings(0);
    else
        [~, scalingFactor] = internal.matlab.variableeditor.peer.PeerDataUtils.getDisplayDataAsString(fullData, fullData(1:1,1:1), true);
        if scalingFactor == 1
            scalingFactorString = strings(0);
        else
            scalingFactorString = string(scalingFactor);
        end
    end
end
