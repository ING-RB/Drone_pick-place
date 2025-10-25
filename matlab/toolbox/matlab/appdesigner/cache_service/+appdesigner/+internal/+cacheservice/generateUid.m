function uid = generateUid(stringContent)
    %GENERATEUID

%   Copyright 2023-2024 The MathWorks, Inc.

    arguments
        stringContent char
    end

    digester = matlab.internal.crypto.BasicDigester("DeprecatedSHA1");
    sha = uint8(digester.computeDigest(uint8(stringContent)));
    uid = join(string(dec2hex(sha)), '');
end
