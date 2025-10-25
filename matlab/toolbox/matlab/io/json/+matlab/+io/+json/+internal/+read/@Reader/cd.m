function cd(obj, idx)
%

%   Copyright 2024 The MathWorks, Inc.

% Keep a reference to the reader's state.
    parent = copy(obj);

    matlab.io.json.internal.LevelReader.cd(obj.reader, idx);
    setReaderData(obj);

    % Set the current level reader's parent.
    obj.parent = parent;
end
