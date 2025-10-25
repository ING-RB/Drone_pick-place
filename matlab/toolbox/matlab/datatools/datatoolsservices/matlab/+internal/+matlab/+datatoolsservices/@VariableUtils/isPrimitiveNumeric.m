% Returns true if the given val is one of the primitive numeric datatypes.
% g2374723: Use this in conjunction with object checks using ishandle to catch
% any false positives due to open figures.

% Copyright 2020-2022 The MathWorks, Inc.

function isTrue = isPrimitiveNumeric(val)
    isTrue = ismember(class(val), internal.matlab.variableeditor.NumericArrayDataModel.NumericTypes);
end