function referenceLink = getReferenceLink(hp)
    referenceLink = '';
    if ~strcmp(hp.command, 'doc') && ~hp.docLinks.isSet
        hp.getDocLinks;
    end
    if hp.commandIsHelp
        referencePage = hp.docLinks.referencePage;
        referenceFunction = 'doc';
        if referencePage == ""
            if ~isempty(hp.docLinks.referenceItem)
                referencePage = hp.getTopic;
            elseif hp.isMCOSClassOrConstructor && hp.objectSystemName ~= ""
                referencePage = erase(hp.objectSystemName, '/' + wildcardPattern + lineBoundary);
                if matlab.lang.internal.introspective.getReferenceHitIndex(referencePage)
                    referenceFunction = 'helpwin';
                end
            end
        end
        if referencePage ~= ""
            referenceLink = getString(message('MATLAB:helpUtils:displayHelp:ReferencePageFor', hp.getTopic));
            referenceLink = matlab.internal.help.createMatlabCommandWithTitle(hp.wantHyperlinks, referenceLink, referenceFunction, referencePage);
            if ~hp.wantHyperlinks
                referenceLink = append(referenceLink, newline);
            end
        end

        if hp.docLinks.productName ~= ""
            productLink = getString(message('MATLAB:helpUtils:displayHelp:DocumentationFor', hp.docLinks.productName));
            productShortName = matlab.internal.doc.reference.getDocProductName(hp.docLinks.productName);
            productLink = matlab.internal.help.createMatlabCommandWithTitle(hp.wantHyperlinks, productLink, 'doc', productShortName);

            referenceLink = append(referenceLink, productLink);
            if ~hp.wantHyperlinks
                referenceLink = append(referenceLink, newline);
            end
        end
    end
end

%   Copyright 2020-2024 The MathWorks, Inc.
