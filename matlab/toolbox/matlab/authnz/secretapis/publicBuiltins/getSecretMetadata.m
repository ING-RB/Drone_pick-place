function secretMetadata = getSecretMetadata(secretName)

arguments(Input)
    secretName {mustBeTextScalar,mustBeNonzeroLengthText}
end

arguments(Output)
    secretMetadata (1,1) dictionary
end

try
    [metadataKeys, metadataValues] = matlab.authnz.internal.builtins.public.getSecretMetadata(secretName);
    if(nargout == 1)
        secretMetadata = dictionary(string(metadataKeys), metadataValues);
    else
        fprintf('\n');
        display(dictionary(string(metadataKeys), metadataValues));
    end
catch ME
    throw(ME);
end
end

%   Copyright 2023-2024 The MathWorks, Inc.
