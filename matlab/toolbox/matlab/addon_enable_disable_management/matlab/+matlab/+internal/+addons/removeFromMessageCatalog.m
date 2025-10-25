%

% Copyright 2019 The MathWorks Inc.

function removeFromMessageCatalog(rootFolder)

% Ignore warning if not found in path
w = warning('off','MATLAB:rmpath:DirNotFound');
clean = onCleanup(@()warning(w));


try
    matlab.internal.msgcat.removeAdditionalResourceLocation(rootFolder);
catch ME %#ok<NASGU>
    % Swallow exceptions and quietly proceed.  Most commonly an exception
    % here means there were no resources anyway
end