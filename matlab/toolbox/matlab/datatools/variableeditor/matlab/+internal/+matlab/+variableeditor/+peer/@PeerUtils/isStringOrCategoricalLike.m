% Returns true if the class is a string or categorical-like type

% Copyright 2014-2023 The MathWorks, Inc.

function flag = isStringOrCategoricalLike(cClass)
    if (strcmp(cClass, 'string') || strcmp(cClass, 'categorical') || strcmp(cClass, 'nominal') || strcmp(cClass, 'ordinal'))
        flag = true;
    else
        flag = false;
    end
end
