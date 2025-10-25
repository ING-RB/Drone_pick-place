function doesHaveOverload = hasOverloads(topic, imports)
    doesHaveOverload = matlab.lang.internal.introspective.overloads.getOverloads(topic, imports, OnlyGetFirstOverload=true) ~= "";
end

%   Copyright 2015-2024 The MathWorks, Inc.
