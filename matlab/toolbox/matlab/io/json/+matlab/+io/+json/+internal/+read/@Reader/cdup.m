function cdup(obj)
%

%   Copyright 2024 The MathWorks, Inc.

    matlab.io.json.internal.LevelReader.cdup(obj.reader);
    setReaderData(obj);
    obj.parent = obj.parent.parent;
end
