function secretValue = getSecret(secretName)

arguments(Input)
    secretName {mustBeTextScalar,mustBeNonzeroLengthText}
end

try
    name = matlab.authnz.internal.builtins.public.getsecret(secretName);
catch ME
    throw(ME);
end

if(nargout == 1)
    secretValue = string(name);
else
    secretLength = size(name);
    fprintf('\n');
    disp(repmat('*', secretLength));
    fprintf('\n');
end
end

%   Copyright 2022-2024 The MathWorks, Inc.

