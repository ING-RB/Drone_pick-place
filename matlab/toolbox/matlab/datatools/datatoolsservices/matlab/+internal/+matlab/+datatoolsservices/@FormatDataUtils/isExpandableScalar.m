% Returns whether this is an expandable scalar or not

% Copyright 2015-2023 The MathWorks, Inc.

function result = isExpandableScalar(className)
    result = any(strcmp(className, internal.matlab.datatoolsservices.FormatDataUtils.EXPANDABLE_MATRIX_CLASSES));
end
