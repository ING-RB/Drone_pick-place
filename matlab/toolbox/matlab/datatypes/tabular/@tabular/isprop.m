function valid = isprop(t, prop)
%

%   Copyright 2020-2024 The MathWorks, Inc.

p = getProperties(t);
valid = isprop(p, prop) || isprop(p.CustomProperties, prop);
