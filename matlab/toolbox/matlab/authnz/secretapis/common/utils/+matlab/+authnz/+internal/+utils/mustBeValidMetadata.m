function mustBeValidMetadata(dict)
% MUSTBEVALIDMETADATA validates Secret Metadata supported dictionary types
%   Dictionary of string to a cell contaning basic MATLAB
%   datatypes is a Valid Metadata

if(~dict.isConfigured)
    throwAsCaller(MException(message("MATLAB:authnz:secretapis:MetadataDictUnconfigured")));
end

[keyType, valueType] = dict.types;

if ~isequal(keyType, 'string')
    throwAsCaller(MException(message("MATLAB:authnz:secretapis:InvalidMetadataDictKeys")));
end

if ~isequal(valueType, 'cell')
    throwAsCaller(MException(message("MATLAB:authnz:secretapis:InvalidMetadataDictValues")));
end
end


