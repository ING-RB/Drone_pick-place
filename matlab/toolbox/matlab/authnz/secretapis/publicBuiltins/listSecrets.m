function t = listSecrets()

arguments (Output)
    t { mustBeA(t,"table") }
end

try
    matlab.authnz.internal.utils.defineCapabilitiesForMATLABDesktop;
    [names, metadata] = matlab.authnz.internal.builtins.public.listsecrets;
catch ME
    if strcmpi(ME.identifier, "MATLAB:services:MissingRequiredCapability")
        error(message("MATLAB:authnz:secretapis:VaultNotSupported", mfilename));
    end
    throw(ME);
end

T = createMetadataTable(metadata, names);

if(nargout == 0)
    % No argument out.
    printListToScreen(T);
else
    t = T;
end
end

function printListToScreen(T)
fprintf('\n');
if height(T) > 0
    disp(T);
else
    fprintf('\t');
    disp(getString(message("MATLAB:authnz:secretapis:NoSecretsToList")));
    fprintf('\n');
end
end

function T = createMetadataTable(metadata, names)
len = numel(metadata);

SecretName = string(names');
SecretMetadata = cell(len,1);

for i = 1:len
    SecretMetadata{i,1} = dictionary(string(metadata(i).MetadataKeys), metadata(i).MetadataValues);
end

T = table(SecretName, SecretMetadata);
end

%   Copyright 2022-2024 The MathWorks, Inc.
