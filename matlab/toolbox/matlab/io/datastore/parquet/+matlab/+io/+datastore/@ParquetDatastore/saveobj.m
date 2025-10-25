function S = saveobj(obj)
%saveobj   Save-to-struct for ParquetDatastore.

%   Copyright 2022 The MathWorks, Inc.

% Store save-load metadata.
    S = struct("EarliestSupportedVersion", 1);
    S.ClassVersion = obj.ClassVersion;
    S.PartitionMethodDerivedFromAuto = obj.PartitionMethodDerivedFromAuto;
    % State properties
    S.UnderlyingDatastore = obj.UnderlyingDatastore;
end
