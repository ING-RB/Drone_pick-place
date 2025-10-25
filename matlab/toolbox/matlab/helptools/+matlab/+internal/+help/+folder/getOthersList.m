function list = getOthersList(topic)
    dirInfos = matlab.lang.internal.introspective.hashedDirInfo(topic, true);
    list = matlab.internal.help.folder.shortenList(dirInfos, topic);
end

% Copyright 2018-2024 The MathWorks, Inc.
