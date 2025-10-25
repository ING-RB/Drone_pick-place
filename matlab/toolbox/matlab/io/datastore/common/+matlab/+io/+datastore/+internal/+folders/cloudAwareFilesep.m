function sep = cloudAwareFilesep(filename)
%cloudAwareFilesep   returns either a forward slash ("/") or backslash ("\")
%   after checking both the platform and the remote/local location
%   of the input filename.

%   Copyright 2019 The MathWorks, Inc.

    % Get the platform-specific filesep.
    sep = string(filesep);

    % Convert filename to a cellstr before usage in isIRI.
    filename = cellstr(filename);

    % Modify the result if an IRI is used.
    if matlab.io.internal.vfs.validators.isIRI(filename)
        sep = "/";
    end
end
