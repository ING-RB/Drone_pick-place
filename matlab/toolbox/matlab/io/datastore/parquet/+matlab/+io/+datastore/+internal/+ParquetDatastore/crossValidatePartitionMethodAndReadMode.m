function crossValidatePartitionMethodAndReadMode(readMode,partitionMethod)
%CROSSVALIDATEPARTITIONMETHODANDREADMODE Summary of this function goes here
%   Detailed explanation goes here

%   Copyright 2023 The MathWorks, Inc.

    if (readMode == "file" && ...
        ismember (partitionMethod, {'rowgroup', 'bytes'}))
        error(message('MATLAB:parquetdatastore:properties:invalidPartitionMethodForFileReadSize'));
    end
end
