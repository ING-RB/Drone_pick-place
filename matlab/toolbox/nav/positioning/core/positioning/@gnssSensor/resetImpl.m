function resetImpl(obj)
%RESETIMPL Reset states of gnssSensor object

%   Copyright 2020-2022 The MathWorks, Inc.

%#codegen

resetImpl@nav.internal.gnss.GNSSSensorSimulator(obj);

% Reset initial position estimate to the reference location.
obj.pInitPosECEF = fusion.internal.frames.lla2ecef(obj.ReferenceLocation);
% Reset initial velocity estimate to zero.
obj.pInitVelECEF = [0, 0, 0];
end
