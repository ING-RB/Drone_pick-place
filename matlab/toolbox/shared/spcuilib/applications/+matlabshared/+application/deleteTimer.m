function deleteTimer(t)
%

%   Copyright 2020 The MathWorks, Inc.
try
    if strcmp(t.Running, 'on')
        stop(t);
    end
    delete(t);
catch ME %#ok<NASGU>
    % DO NOTHING
end

% [EOF]
