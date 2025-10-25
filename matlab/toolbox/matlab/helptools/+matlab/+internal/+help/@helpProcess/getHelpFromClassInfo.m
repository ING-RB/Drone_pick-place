function foundHelp = getHelpFromClassInfo(hp, classInfo, justH1)
    
    foundHelp = false;
    
    if hp.helpStr == ""
        hp.helpStr = classInfo.getHelp(justH1, hp.command, hp.topic);
        hp.needsHotlinking = true;
        foundHelp = true;
        hp.topic = classInfo.minimalPath;
    end 
end

%   Copyright 2007-2024 The MathWorks, Inc.
