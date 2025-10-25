function warningNoBacktrace(varargin)
%This function is for internal use only. It may be removed in the future.

%warningNoBacktrace - Issue warnings without backtrace
%   warningNoBacktrace(M) issues a warning as specified by the MATLAB
%   message M, but temporarily turns off the backtrace.
%
%   warningNoBacktrace(VARARGIN) passes all arguments in VARARGIN verbatim
%   into the warning function.

%   Copyright 2014-2023 The MathWorks, Inc.

    oldWarnState = warning('query', 'backtrace');
    cleanup = onCleanup(@() warning(oldWarnState));
    warning('off', 'backtrace');
    warning(varargin{:});
end
