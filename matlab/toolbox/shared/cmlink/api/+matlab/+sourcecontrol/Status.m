classdef Status
%STATUS Enumeration of source control statuses for files
%

% Copyright 2015-2019 The MathWorks, Inc.

    enumeration
        % The file on disk is not present in the source control system
        NotUnderSourceControl
        % The file on disk matches the file in the source control system
        Unmodified
        % Cannot determine source control status
        Unknown
        % The file contains conflicts that you must resolve
        Conflicted
        % The file on disk is modified
        Modified
        % Added to source control
        Added
        % This file has been deleted
        Deleted
        % File cannot be found on disk but is listed by source control
        Missing
        % Ignored by source control
        Ignored
        % This file is stored in another repository location
        External
    end

end
