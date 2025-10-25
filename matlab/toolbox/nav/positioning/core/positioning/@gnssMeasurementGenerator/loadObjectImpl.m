function loadObjectImpl(obj, s, wasLocked)
%LOADOBJECTIMPL Load gnssMeasurementGenerator object

%   Copyright 2022 The MathWorks, Inc.

% Load public properties.
loadObjectImpl@nav.internal.gnss.GNSSSensorSimulator(obj, s, wasLocked);

obj.pHostID = s.pHostID;
end
