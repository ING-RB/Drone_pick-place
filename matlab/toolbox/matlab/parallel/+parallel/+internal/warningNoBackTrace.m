function warningNoBackTrace(varargin)
% warningNoBackTrace - Issue the supplied message as a warning with no backtrace.
%   NB: lastwarn() will be populated with the supplied warning.

%   Copyright 2013-2021 The MathWorks, Inc.

warningState = warning('off', 'backtrace');
restoreWarningState = onCleanup(@() warning(warningState));
warning(varargin{:});
end
