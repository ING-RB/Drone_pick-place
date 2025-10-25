function getHelpText(hp)
    if hp.topic ~= ""
        hp.getTopicHelpText;
    elseif hp.callerContext.IsAtCommandLine && desktop('-inuse')
        hp.getNoInputHelp;
    end
end

% Copyright 2007-2024 The MathWorks, Inc.
