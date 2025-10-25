function fds = loadobj(S)
%loadobj   load-from-struct for FileDatastore2

%   Copyright 2022 The MathWorks, Inc.

    import matlab.io.datastore.internal.FileDatastore2

    if isfield(S, "EarliestSupportedVersion")
        % Error if we are sure that a version incompatibility is about to occur.
        if S.EarliestSupportedVersion > FileDatastore2.ClassVersion
            error(message("MATLAB:io:datastore:common:validation:UnsupportedClassVersion"));
        end
    end

    % Reconstruct the object.
    fds = FileDatastore2({}, ReadFcn=S.ReadFcn);
    fds.FileSet = S.FileSet;
end
