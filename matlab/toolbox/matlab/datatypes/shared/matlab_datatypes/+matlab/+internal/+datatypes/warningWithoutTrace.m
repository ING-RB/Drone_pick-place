function warningWithoutTrace(msg)
%WARNWITHOUTTRACE Throw a warning without displaying the back trace.

%   Copyright 2014-2020 The MathWorks, Inc.

% Store the warning state.
warnState = warning('off', 'backtrace');

% Issue a warning.
warning(msg);

% Restore the warning state.
warning(warnState);
