% This function is undocumented.

%   Copyright 2023 The MathWorks, Inc.

function digest = computeResultDigest(resObj)
arguments
    resObj = matlab.coverage.Result
end

resObj = resObj(:);

% Compute the key based on the file name and the creation date (should be enough for now)
allInfo = strjoin([[resObj.Filename], string([resObj.CreationDate])], ",");
digest = matlab.internal.crypto.base64Encode(matlab.internal.crypto.BasicDigester("SHA224").computeDigest(allInfo));

