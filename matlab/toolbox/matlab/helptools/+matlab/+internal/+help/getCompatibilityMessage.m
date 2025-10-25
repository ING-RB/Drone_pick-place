function compatibilityMessage = getCompatibilityMessage(topic)
    codeCheck = checkcode('-text', topic, '.m', '-struct', '-id', '-config=factory',  '-CFG:0*', '-CFG:1OLDAPI', '-CFG:1COMPAT');

    if isempty(codeCheck)
        compatibilityMessage = "";
    else
        compatibilityMessage = codeCheck.message;
    end
end

%   Copyright 2021-2022 The MathWorks, Inc.
