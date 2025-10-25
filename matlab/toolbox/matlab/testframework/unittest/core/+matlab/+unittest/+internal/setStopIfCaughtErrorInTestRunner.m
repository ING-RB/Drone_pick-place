function cleaner = setStopIfCaughtErrorInTestRunner(desiredValue)
%

% Copyright 2021-2023 The MathWorks, Inc.

import matlab.lang.internal.isStopIfErrorCaughtInFileEnabled;
import matlab.lang.internal.enableStopIfErrorCaughtInFile;
import matlab.lang.internal.disableStopIfErrorCaughtInFile;

cleaner = onCleanup.empty;

if isdeployed || parallel.internal.pool.isPoolThreadWorker
    % Debugging only necessary in interactive contexts.
    return;
end

file = string(which("matlab.unittest.TestRunner"));
currentValue = isStopIfErrorCaughtInFileEnabled(file);

if desiredValue && ~currentValue
    cleaner = onCleanup(@()disableStopIfErrorCaughtInFile(file));
    enableStopIfErrorCaughtInFile(file);
elseif ~desiredValue && currentValue
    cleaner = onCleanup(@()enableStopIfErrorCaughtInFile(file));
    disableStopIfErrorCaughtInFile(file);
end
end
