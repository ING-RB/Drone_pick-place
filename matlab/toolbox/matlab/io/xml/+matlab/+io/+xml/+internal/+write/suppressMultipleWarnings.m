function warningCleanup = suppressMultipleWarnings()
%

% Copyright 2020 The MathWorks, Inc.

    % Before performing struct/table validation, save the state of this warning message
    % to stop it from being printed multiple times when writing a file.
    msgid = "MATLAB:io:xml:common:StartsWithXMLElementName";
    warningState = warning('query', msgid);

    % Restore the old warning state after validation has completed.
    % This must be a named variable in the caller's workspace!
    warningCleanup = onCleanup(@() warning(warningState));
end
