function setSecret(secretName,opts)

arguments(Input)
    secretName {mustBeTextScalar,mustBeNonzeroLengthText}
    opts.Overwrite (1,1) logical {mustBeNumericOrLogical} = false
end

try
    matlab.authnz.internal.utils.defineCapabilitiesForMATLABDesktop;
    % Error early if we cannot overwrite a secret and the secret already exists.
    if(isSecret(secretName) && ~opts.Overwrite)
        error(message("MATLAB:authnz:secretapis:KeyAlreadyExists",secretName));
    end
    acquireUserSecret(secretName, opts);
catch ME
    throw(appendNameToError(ME));
end
end

function acquireUserSecret(secretName, opts)
import matlab.internal.capability.Capability;

if Capability.isSupported(Capability.ModalDialogs)
    setSecrectFcn = @setSecretWithDialog;
else
    setSecrectFcn = @setSecretWithPrompt;
end

setSecrectFcn(secretName, opts);
end

function setSecretWithDialog(secretName, opts)
import matlab.authnz.internal.utils.SecretInputDialogPrompt.prompt;
% Need to set SecretInputDialogPrompt flag true to extract secret from token
opts.SecretInputDialogPrompt = true;
promptTitle = getString(message("MATLAB:authnz:secretapis:PromptTitle"));

maxLength = 15;
promptMsg = getString(message("MATLAB:authnz:secretapis:PromptMessage",...
    truncateName(secretName,maxLength)));

matlab.authnz.internal.builtins.public.setsecret(secretName, prompt(promptTitle, promptMsg), opts);
end

function setSecretWithPrompt(secretName, opts)
import matlab.authnz.internal.maskedinput
opts.SecretInputDialogPrompt = false;
value = convertCharsToStrings(maskedinput("Enter secret: "));
matlab.authnz.internal.builtins.public.setsecret(secretName, value, opts);
end

function name = truncateName(name,len)
arguments
    name(1,1) string
    len(1,1) double {mustBeInteger, mustBePositive}
end

if (strlength(name) > len)
    name = extractBefore(name, min(len, strlength(name)) + 1);
    name = strcat(name, "...");
end
end

function ME = appendNameToError(ME)
if strcmpi(ME.identifier, "MATLAB:services:MissingRequiredCapability")
    ME = MException(message("MATLAB:authnz:secretapis:VaultNotSupported", mfilename));
elseif strcmpi(ME.identifier, "MATLAB:authnz:secretapis:VaultNotFound")
    ME = MException(message("MATLAB:authnz:secretapis:VaultNotFound", mfilename));
end
end

%   Copyright 2022-2024 The MathWorks, Inc.
