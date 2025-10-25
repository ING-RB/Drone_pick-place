function values = getValuesAsMissing(obj, ~)
%

%   Copyright 2024 The MathWorks, Inc.

    values = repmat(missing, numel(obj.valueTypes), 1);
end
