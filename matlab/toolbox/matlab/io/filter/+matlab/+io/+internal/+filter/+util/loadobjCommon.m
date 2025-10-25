function loadobjCommon(S)
%loadobjCommon   Common loadobj code for all the AbstractRowFilter
%   subclasses.

%   Copyright 2021 The MathWorks, Inc.

    if isfield(S, "EarliestSupportedVersion")
        % Error if we are sure that a version incompatibility is about to occur.
        if S.EarliestSupportedVersion > matlab.io.internal.AbstractRowFilter.ClassVersion
            error(message("MATLAB:io:filter:filter:UnsupportedClassVersion"));
        end
    end
end