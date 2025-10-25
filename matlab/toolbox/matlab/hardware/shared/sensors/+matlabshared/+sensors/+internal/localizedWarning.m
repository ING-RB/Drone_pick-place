function localizedWarning(id, varargin)
% Function for disabling stack for warnings

%   Copyright 2020 The MathWorks, Inc.
    varargin = cellfun(@(x)strrep(x, '\', '\\'), varargin, 'UniformOutput', false);
    sWarningBacktrace = warning('off', 'backtrace');
    warning(id,getString(message(id, varargin{:})));
    warning(sWarningBacktrace.state, 'backtrace');
end
