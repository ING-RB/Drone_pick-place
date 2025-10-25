function dataOut = validateDataPropertyValue( channelName, data)
dataOut = validateDataPropertyValue@matlab.graphics.mixin.DataProperties(channelName, data);
try
    mustBeNumericOrLogical(dataOut);
catch e
    throwAsCaller(e)
end
end