function prepareHelpForDisplay(hp)
    if hp.displayBanner || hp.isTypo || hp.isUnderqualified
        appendBanner(hp);
    end        
    if hp.helpStr ~= ""
        if hp.wantHyperlinks && hp.needsHotlinking
            % Make "see also", "overloaded methods", etc. hyperlinks.
            hp.hotlinkHelp;
        end

        referenceLink = hp.getReferenceLink();
        overloadsLink = hp.getOverloadsLink();
        foldersLink   = hp.getFoldersLink();
        
        if referenceLink ~= "" || overloadsLink ~= "" || foldersLink ~= ""
            hp.helpStr = append(hp.helpStr, newline, referenceLink, overloadsLink, foldersLink);
        end
        
        if ~hp.isDir
            demoTopic = hp.getDemoTopic;
            if demoTopic ~= ""
                demoText   = matlab.internal.help.createMatlabCommandWithTitle(hp.wantHyperlinks, getString(message('MATLAB:introspective:displayHelp:PublishedOutputInTheHelpBrowser')), 'showdemo', demoTopic);
                hp.helpStr = append(hp.helpStr, demoText);
            end
        end
    end
end

%   Copyright 2007-2024 The MathWorks, Inc.
