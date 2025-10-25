%

% Copyright 2019 The MathWorks Inc.

function addToMessageCatalog(rootFolder)

% Ignore warning if folder doesn't have resources - this only happens if
% the add-on root folder isn't added to the path
w = warning('off','MATLAB:internal:msgcat:msgcatInvalidResourcePath');
clean = onCleanup(@()warning(w));

try
    matlab.internal.msgcat.setAdditionalResourceLocation(rootFolder);
catch ME %#ok<NASGU>
    % Swallow exceptions and quietly proceed.  Most commonly an exception
    % here means there were no resources anyway
end