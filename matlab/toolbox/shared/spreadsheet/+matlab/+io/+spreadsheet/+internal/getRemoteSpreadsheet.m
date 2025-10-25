function [filename, remote2Local] = getRemoteSpreadsheet(filename, remote2Local)
%GETREMOTESPREADSHEET   Get a local copy of spreadsheet in a remote location
%   FILENAME = GETREMOTESPREADSHEET(VARARGIN) is the path to the local copy
%   of the spreadsheet in the remote location.

%   Copyright 2019-2024 The MathWorks, Inc.

    import matlab.io.internal.common.validators.isGoogleSheet;
    isThisAGoogleSheet = isGoogleSheet(filename);
    if (nargin < 2 || isempty(remote2Local) || ...
            ~strcmp(remote2Local.RemoteFileName,filename)) && ~isThisAGoogleSheet
        [filename, remote2Local] = getLocalCopy(filename);
    elseif nargin == 2 && ~isThisAGoogleSheet
        % no validation needed here, same file as stored on datastore
        filename = remote2Local.LocalFileName;
    elseif nargin < 2 && isThisAGoogleSheet
        remote2Local = [];
    end
end

function [filename, remote2Local] = getLocalCopy(filename)
    % download a local copy
    remote2Local = matlab.io.internal.vfs.stream.RemoteToLocal(filename);
    filename = remote2Local.LocalFileName;
end
