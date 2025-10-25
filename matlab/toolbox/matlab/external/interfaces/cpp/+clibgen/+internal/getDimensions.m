function dimensions = getDimensions(arg)
% get dimensions of input from its shape

%   Copyright 2018-2022 The MathWorks, Inc.
shape=arg.Shape;
dimensions = struct([]);
if ischar(shape)
    if ~strcmp(shape, 'nullTerminated')
        dimensions(1).type = "parameter";
        dimensions(1).value = string(shape);
    end
elseif isnumeric(shape)
    for y = 1:length(shape)
        dimensions(y).type = "value";
        dimensions(y).value = shape(y);
    end
elseif isnumeric(shape) && ...
        (arg.Storage == "array" || arg.Storage == "pointer") && ...
        startsWith(arg.MATLABType(1), "clib.array.")
    dimensions(1).type = "value";
    dimensions(1).value = shape(1);
elseif isstring(shape) && (numel(shape) ~= 1 || ~strcmp(shape, "nullTerminated"))
    for y = 1:length(shape)
        dimensions(y).type = "parameter";
        dimensions(y).value = shape(y);
    end
elseif iscell(shape)
    if numel(shape) ~= 1 || isnumeric(shape{1}) ...
        || ((isstring(shape{1}) || ischar(shape{1})) ...
            && ~strcmp(shape{1}, "nullTerminated"))
        for y = 1:length(shape)
            if isnumeric(shape{y})
                dimensions(y).type = "value";
                dimensions(y).value = shape{y};
            else
                dimensions(y).type = "parameter";
                if ischar(shape{y})
                    dimensions(y).value = string(shape{y});
                else
                    dimensions(y).value = shape{y};
                end
            end
        end
    end
end
end