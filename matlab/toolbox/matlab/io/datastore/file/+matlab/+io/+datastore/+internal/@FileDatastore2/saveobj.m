function S = saveobj(fds)
%saveobj   Save-to-struct for FileDatastore2.

%   Copyright 2022 The MathWorks, Inc.

    % Store save-load metadata.
    S = struct("EarliestSupportedVersion", 1);
    S.ClassVersion = fds.ClassVersion;

    % Public properties
    S.FileSet = fds.FileSet;
    S.ReadFcn = fds.ReadFcn;
end
