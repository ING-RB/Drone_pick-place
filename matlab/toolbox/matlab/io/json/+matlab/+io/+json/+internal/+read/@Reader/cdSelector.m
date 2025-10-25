function status = cdSelector(obj, dictionarySelector)
%

%   Copyright 2024 The MathWorks, Inc.

    status = matlab.io.json.internal.LevelReader.cdSelector(obj.reader, dictionarySelector);
    obj.setReaderData();
end
