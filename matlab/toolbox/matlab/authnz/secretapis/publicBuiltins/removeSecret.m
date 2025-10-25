function removeSecret(secretName)

arguments(Input)
    secretName {mustBeTextScalar,mustBeNonzeroLengthText}
end

try
    matlab.authnz.internal.utils.defineCapabilitiesForMATLABDesktop;
    matlab.authnz.internal.builtins.public.removesecret(secretName);
catch ME
    if strcmpi(ME.identifier, "MATLAB:services:MissingRequiredCapability")
        error(message("MATLAB:authnz:secretapis:VaultNotSupported", mfilename));
    end
    throw(ME);
end
end

%   Copyright 2022-2024 The MathWorks, Inc.
