function mustBeValidMetadataInternal(dict)
%   Copyright 2024 The MathWorks, Inc.

% MUSTBEVALIDMETADATAINTERNAL validates Secret Metadata supported dictionary types
%   Dictionary of string to any basic MATLAB
%   datatypes is a Valid Metadata

if(~dict.isConfigured)
    throwAsCaller(MException(message("MATLAB:authnz:secretapis:MetadataDictUnconfigured")));
end

[keyType, ~] = dict.types;

if ~isequal(keyType, 'string')
    throwAsCaller(MException(message("MATLAB:authnz:secretapis:InvalidMetadataDictKeys")));
end

end



