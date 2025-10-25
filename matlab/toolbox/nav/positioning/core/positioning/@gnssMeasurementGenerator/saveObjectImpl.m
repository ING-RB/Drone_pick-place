function s = saveObjectImpl(obj)
%SAVEOBJECTIMPL Save gnssMeasurementGenerator object

%   Copyright 2022 The MathWorks, Inc.

% Save public properties.
s = saveObjectImpl@nav.internal.gnss.GNSSSensorSimulator(obj);

s.pHostID = obj.pHostID;
end
