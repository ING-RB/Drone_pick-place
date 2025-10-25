function secretNames = listSecretNames()
%matlab.authnz.internal.utils.listSecretNames Lists all existing secret names in the vault.

%   Copyright 2023 The MathWorks, Inc.

arguments(Output)
    secretNames (:,1) string
end

try
    res = listSecrets;
    secretNames = res.SecretName;
catch listSecretKeysException
    throw(listSecretKeysException);
end

end
