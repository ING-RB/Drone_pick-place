function setSecretMetadata(secretName, secretMetadata, opts)

arguments(Input)
    secretName {mustBeTextScalar,mustBeNonzeroLengthText};
    secretMetadata (1,1) dictionary {matlab.authnz.internal.utils.mustBeValidMetadata};
    opts.WriteMode (1,1) string {mustBeMember(opts.WriteMode,["add","merge","replace"])} = "add"
end

try
    matlab.authnz.internal.utils.defineCapabilitiesForMATLABDesktop;
    if(~isSecret(secretName))
        error(message("MATLAB:authnz:secretapis:SecretValueNotFound",secretName));
    end
    metadataKeys = (secretMetadata.keys)';
    metadataValues = (secretMetadata.values)';
    matlab.authnz.internal.builtins.public.setSecretMetadata(secretName,metadataKeys,metadataValues,opts.WriteMode);
catch setSecretMetadataException
    if strcmpi(setSecretMetadataException.identifier, "MATLAB:services:MissingRequiredCapability")
        error(message("MATLAB:authnz:secretapis:VaultNotSupported", mfilename));
	elseif strcmpi(setSecretMetadataException.identifier, "MATLAB:authnz:secretapis:VaultNotFound")
        error(message("MATLAB:authnz:secretapis:VaultNotFound", mfilename));
    end
    throw(setSecretMetadataException);
end
end

%   Copyright 2023 The MathWorks, Inc.
