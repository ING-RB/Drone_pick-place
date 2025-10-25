function jimage = im2java(varargin)
% Internal function that performs the same action as im2java but without
% issuing the deprecation warnings.

%   Copyright 2022 The MathWorks, Inc.

    % Suppress and then restore the function deprecation warning
    [lastWarnMsg, lastWarnId] = lastwarn;
    im2javaState = warning('off', 'MATLAB:im2java:functionToBeRemoved');
    cleaner = onCleanup(@() restoreState(lastWarnMsg, lastWarnId, im2javaState));
    
    jimage = im2java(varargin{:});

    function restoreState(msg, id, state)
        % restore previous warning state
        warning(state);
        
        % restore previous warning thrown
        lastwarn(msg, id);
    end
end