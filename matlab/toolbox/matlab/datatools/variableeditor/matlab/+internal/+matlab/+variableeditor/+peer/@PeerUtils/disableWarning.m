% Disable warnings

% Copyright 2014-2023 The MathWorks, Inc.

function orig_state = disableWarning()
    % return original state for resume later.
    orig_state = warning;

    % disable warning
    warning('off', 'all');
end
