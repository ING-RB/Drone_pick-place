function status = isSecret(secretName)

arguments(Input)
    secretName {mustBeTextScalar, mustBeNonzeroLengthText}
end

try
    status = matlab.authnz.internal.builtins.public.issecret(secretName);
catch ME
    throw(ME);
end
end

%   Copyright 2023-2024 The MathWorks, Inc.

