function datastoresOut = validateAndFlattenDatastoreList(datastoresIn, metaDSType)
%VALIDATEANDFLATTENDATASTORELIST Validate and flatten the input list of datastores.
%   This function validates each of the input datastore and then flattens
%   the list. This list can then serve as the underlying datastores list
%   for metadatastores like CombinedDatastore or SequentialDatastore.
%
%   Copyright 2022 The MathWorks, Inc.

arguments
    datastoresIn cell {mustBeNonempty}
    metaDSType {mustBeTextScalar, mustBeNonzeroLengthText}
end

import matlab.io.datastore.internal.validators.isDatastore;
if ~all(cellfun(@isDatastore, datastoresIn))
    msg = message('MATLAB:datastoreio:combineddatastore:nonDatastoreInputs', getShortHandDSType(metaDSType));
    throwAsCaller(MException(msg));
end

datastoresOut = flattenDSList(datastoresIn, metaDSType);

end

function shortHandDSType = getShortHandDSType(metaDSType)
shortHandDSType = char(metaDSType);
idx = find(shortHandDSType == '.', 1, 'last');
if ~isempty(idx)
    shortHandDSType = shortHandDSType(idx+1:end);
end
end

function datastoresOut = flattenDSList(datastoresIn, metaDSType)
datastoresOut = {};

outputIdx = 1;

for ii = 1:numel(datastoresIn)
    if ismember(metaDSType, {'matlab.io.datastore.CombinedDatastore', 'matlab.io.datastore.SequentialDatastore'}) ...
            && isa(datastoresIn{ii}, metaDSType)
        numJoined = numel(datastoresIn{ii}.UnderlyingDatastores);
        datastoresOut(outputIdx :(outputIdx+numJoined-1)) = datastoresIn{ii}.UnderlyingDatastores;
        outputIdx = outputIdx + numJoined;
    else
        datastoresOut(end+1) = datastoresIn(ii); %#ok<AGROW>
        outputIdx = outputIdx + 1;
    end
end
end