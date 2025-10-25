function s = saveObjectImpl(obj)
%SAVEOBJECTIMPL Save gnssSensor object

%   Copyright 2020-2022 The MathWorks, Inc.

% Save public properties.
s = saveObjectImpl@nav.internal.gnss.GNSSSensorSimulator(obj);
    
% Save private properties.
if isLocked(obj)
    s.pInitPosECEF = obj.pInitPosECEF;
    s.pInitVelECEF = obj.pInitVelECEF;
end
end
