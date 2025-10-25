function transformedDict = transformDictUniformly(metadataKeys,metadataValues)
%   Copyright 2024 The MathWorks, Inc.

% This file transforms the given metadata values into a common datatype and
% then return a dictionary(string -> CommonDatatype).
    if ~iscell(metadataKeys)
        throwAsCaller(MException(message("MATLAB:authnz:secretapis:InvalidMetadataDictKeys")));
    end
    if ~iscell(metadataValues)
        throwAsCaller(MException(message("MATLAB:authnz:secretapis:InvalidMetadataDictValues")));
    end
    currDict = dictionary(string(metadataKeys), metadataValues);
    allSameType = matlab.authnz.internal.utils.uniformTransformPossible(currDict);
    if(allSameType)
        transformedDict = dictionary();
        for i= 1:length(metadataKeys)
            transformedDict(string(metadataKeys(i))) = metadataValues{i};
        end
        return;
    else
        throwAsCaller(MException(message("MATLAB:authnz:secretapis:NoCommonDatatype")));
    end
end

