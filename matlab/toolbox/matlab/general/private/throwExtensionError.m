function throwExtensionError(errorID, filename)
    [~, ~, ext] = fileparts(filename);
    error(message(errorID, ext));
end

% Copyright 2024 The MathWorks, Inc.
