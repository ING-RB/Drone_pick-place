function getHelpFromLookfor(hp)
    % use the same rule that typos does and skip short topics
    if strlength(hp.topic) > 2 && hp.commandIsHelp
        if hp.wantHyperlinks
            linkOpt = '-hot';
            bannerTopic = hp.makeStrong(hp.topic);
        else
            linkOpt = '-cold';
            bannerTopic = hp.topic;
        end
        lookforProcess = matlab.internal.help.Lookfor([string(hp.topic), linkOpt, "-informal"]);
        lookforProcess.doReferenceLookup;
        maxListLength = 20;
        if lookforProcess.numRefItems < maxListLength
            lookforProcess.informal = false;
            lookforProcess.doReferenceLookup;
        end
        switch lookforProcess.numRefItems
        case 0
            % nothing found
        case 1
            hp.topic = matlab.internal.help.getTopicFromReferenceItem(lookforProcess.refItems);
            hp.helpStr = matlab.internal.help.getHelpTextFromReferenceItem(lookforProcess.refItems, hp.topic, hp.command);
            hp.objectSystemName = hp.topic;
            hp.needsHotlinking = false;
            hp.isTypo = true;
        otherwise
            lookforProcess.numRefItems = maxListLength;
            banner = getString(message('MATLAB:help:LookforBanner', bannerTopic));
            lookforProcess.collect = true;
            lookforProcess.processRefItems;
            searchMessage = getString(message('MATLAB:helpUtils:displayHelp:SearchMessageWithTopic', hp.topic));
            searchCommand = matlab.internal.help.createMatlabCommandWithTitle(hp.wantHyperlinks, searchMessage, "docsearch", hp.topic);
            hp.helpStr = char(append(banner, lookforProcess.getCollection, newline, newline, searchCommand));
            hp.needsHotlinking = false;
        end
    end
end

%   Copyright 2023-2024 The MathWorks, Inc.
