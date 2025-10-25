function loadObjectImpl(obj, s, wasLocked)
%LOADOBJECTIMPL Load gnssSensor object

%   Copyright 2020-2022 The MathWorks, Inc.

% Load public properties.
loadObjectImpl@nav.internal.gnss.GNSSSensorSimulator(obj, s, wasLocked);
    
% Load private properties.
if wasLocked
    obj.pInitPosECEF = s.pInitPosECEF;
    obj.pInitVelECEF = s.pInitVelECEF;
end
end