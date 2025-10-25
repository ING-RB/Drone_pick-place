function result = isdir(dirpath)

result = ~isempty(dirpath) && isfolder(dirpath);

%   Copyright 1984-2024 The MathWorks, Inc.
