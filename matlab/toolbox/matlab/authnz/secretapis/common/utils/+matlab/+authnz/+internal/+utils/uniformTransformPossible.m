function transformPossible = uniformTransformPossible(secretMetadata)
%   Copyright 2024 The MathWorks, Inc.

% This file checks whether the given secretMetadata can be uniformly
% transformed to a common datatype.
    if ~isConfigured(secretMetadata)
        throwAsCaller(MException(message("MATLAB:authnz:secretapis:InvalidMetadataDictKeys")));
    end
    metadataValues = (secretMetadata.values)';
    firstType = class(metadataValues{1});
    transformPossible = all(cellfun(@(v) strcmp(class(v), firstType), metadataValues));
end

