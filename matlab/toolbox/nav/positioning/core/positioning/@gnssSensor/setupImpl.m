function setupImpl(obj, pos, ~)
%SETUPIMPL Setup gnssSensor object

%   Copyright 2020-2022 The MathWorks, Inc.

%#codegen

setupImpl@nav.internal.gnss.GNSSSensorSimulator(obj);

% Store input for type casting.
obj.pInputPrototype = pos;
end
