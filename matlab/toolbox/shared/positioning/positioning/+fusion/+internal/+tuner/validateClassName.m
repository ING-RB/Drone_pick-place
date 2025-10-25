function validateClassName(filtcls, errID)
%   This function is for internal use only. It may be removed in the future. 
%VALIDATECLASS(FILTCLS) Validate that FILTCLS is the class name of a filter
%   supported by the TUNE function. The ERRID input is the error message ID
%   to throw if FILTCLS is not a string or char vector.

%   Copyright 2020-2021 The MathWorks, Inc.    

        assert( (isscalar(filtcls) && isstring(filtcls)) || ...
            ischar(filtcls), message(errID)), 
        
        % Find base classes
        bases = fusion.internal.tuner.baseClassesFromName(filtcls);
        
        % The insEKF requires a handle input. A class name is insufficient
        assert(~any(bases == "positioning.internal.insEKFBase"), ...
            message('shared_positioning:tuner:insEKFNeedHandle'));

        canTune = any(bases == "fusion.internal.tuner.FilterTuner");
        assert(canTune, message('shared_positioning:tuner:Unsupported', ...
            filtcls));
end
