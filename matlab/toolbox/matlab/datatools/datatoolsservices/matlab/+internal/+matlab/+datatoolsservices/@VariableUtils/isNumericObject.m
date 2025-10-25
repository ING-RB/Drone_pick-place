% Returs true of the given val is a numeric object.

% Copyright 2020-2022 The MathWorks, Inc.

function isTrue = isNumericObject(val)
    isTrue = isnumeric(val) && isobject(val);
end
