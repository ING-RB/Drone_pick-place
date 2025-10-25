function status = cdNodeName(obj, dictionaryNodeName)
%

%   Copyright 2024 The MathWorks, Inc.

    status = matlab.io.json.internal.LevelReader.cdNodeName(obj.reader, dictionaryNodeName);
    obj.setReaderData();
end
