function dirInfo = hashedDirInfo(topic, isCaseSensitive)
    if nargin < 2
        isCaseSensitive = false;
    end

    dirInfo = matlab.lang.internal.introspective.cache.lookup(@doWhat, topic, isCaseSensitive);
end

function result = doWhat(dirPath, isCaseSensitive)
    if isCaseSensitive
        result = what('-casesensitive', dirPath);
    else
        result = what('-caseinsensitive', dirPath);
    end
end

%   Copyright 2007-2023 The MathWorks, Inc.
