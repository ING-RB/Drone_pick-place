classdef docLinks
    properties
        referencePage = '';
        productName   = '';
        referenceItem = [];

        caseMatch     (1,1) logical = true;
        isParent      (1,1) logical = false;
        isConstructor (1,1) logical = false;
        isSet         (1,1) logical = false;
        index         (1,1) double  = 0;
    end

    methods
        function dl = docLinks(path, name, classInfo)
            if nargin == 0
                return;
            end

            dl.isSet = true;
            dl.productName = getProductLongName(name);

            toolboxFolder = matlab.lang.internal.introspective.getToolboxFolder(path, name);

            if path ~= "" && toolboxFolder == "" && ~underSPRoot(path)
                % path was specified but not under <matlabroot>/toolbox
                % this is a 3P function, don't look in the doc
                return;
            end

            referenceHitIndex = matlab.lang.internal.introspective.getReferenceHitIndex(name, path, classInfo, toolboxFolder);

            if (dl.productName ~= "" || referenceHitIndex.isWrongBook) && referenceHitIndex.isUnderqualified
                return;
            end

            dl.index         = referenceHitIndex.index;
            dl.referenceItem = referenceHitIndex.item;
            dl.caseMatch     = referenceHitIndex.isCaseMatch;
            dl.isParent      = referenceHitIndex.isParent;
            dl.isConstructor = referenceHitIndex.isConstructor;

            if ~referenceHitIndex.isWrongBook
                if dl.isFirstHit
                    if referenceNameIsIncorrect(referenceHitIndex)
                        dl.referencePage = name;
                    else
                        dl.referencePage = matlab.internal.help.getTopicFromReferenceItem(dl.referenceItem);
                    end
                elseif dl.index
                    dl.referencePage = getProductQualifiedName(dl.referenceItem);
                end
            end
        end

        function b = isFirstHit(dl)
            b = dl.productName == "" && dl.index == 1;
        end
    end
end

function b = referenceNameIsIncorrect(referenceHitIndex)
    b = referenceHitIndex.isParent || referenceHitIndex.isProductQualified || referenceHitIndex.isUnderqualified;
end

function referencePage = getProductQualifiedName(referenceItem)
    referencePage = char(append(referenceItem.HelpFolder, '/', matlab.internal.help.getTopicFromReferenceItem(referenceItem)));
end

function b = underSPRoot(path)
    sproot = matlabshared.supportpkg.getSupportPackageRoot;
    b = sproot ~= "" && startsWith(path, sproot);
end

function longName = getProductLongName(topic)
    longName = char(matlab.internal.doc.reference.getDocProductName(lower(topic), false));
end

%   Copyright 2008-2024 The MathWorks, Inc.
