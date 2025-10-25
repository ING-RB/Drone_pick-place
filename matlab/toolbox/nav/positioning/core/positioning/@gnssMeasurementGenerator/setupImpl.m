function setupImpl(obj)
%SETUPIMPL Setup gnssMeasurementGenerator object

%   Copyright 2022 The MathWorks, Inc.

%#codegen

% Store input for type casting. Use reference location since the step
% method takes no inputs.
obj.pInputPrototype = class(obj.ReferenceLocation);

setupImpl@nav.internal.gnss.GNSSSensorSimulator(obj);
end
