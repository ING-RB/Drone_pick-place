function completeValues = fillMissing(obj, values)
%

%   Copyright 2024 The MathWorks, Inc.

% Get FillValue from varopts
    fillValue = obj.varOpts.FillValue;

    completeValues = repmat(fillValue, size(obj.missing));

    completeValues(~missing) = values;
end
