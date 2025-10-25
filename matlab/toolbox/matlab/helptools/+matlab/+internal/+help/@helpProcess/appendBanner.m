function appendBanner(hp)
    bannerTopic = hp.objectSystemName;
    if bannerTopic == ""
        bannerTopic = hp.topic;
    end
    if hp.helpOnInstance && isPrimitiveType(bannerTopic)
        % Not an object; use the InstanceIsA message instead
        hp.helpStr = '';
    end
    if hp.helpStr == ""
        % since there is no help, just say what the input resolved to
        if hp.helpOnInstance
            hp.helpStr = matlab.internal.help.getInstanceIsa(hp.inputTopic, bannerTopic);
            hp.needsHotlinking = false;
            hp.fullTopic = '';
            hp.docLinks.referenceItem = [];
            hp.docLinks.referencePage = '';
            hp.isMCOSClassOrConstructor = false;
        else
            hp.topic = hp.inputTopic;
            hp.objectSystemName = hp.inputTopic;
        end
    else
        bannerTopic = makeStrong(hp, bannerTopic);
        bannerTopic = qualifyNameWithEntityType(hp, bannerTopic);
        if hp.isTypo
            inputTopic = makeStrong(hp, hp.inputTopic);
            if hp.isAlias
                bannerID = 'MATLAB:help:HelpForAliasBanner';
            else
                bannerID = 'MATLAB:help:HelpForTypoBanner';
            end
            helpForTopic = getString(message(bannerID, inputTopic, bannerTopic));
        else
            helpForTopic = getString(message('MATLAB:help:HelpForBanner', bannerTopic));
        end
        hp.helpStr = sprintf('%s%s', helpForTopic, hp.helpStr);
    end
end

function topic = makeStrong(hp, topic)
    if hp.commandIsHelp
        topic = hp.makeStrong(topic);
    end
end

function name = qualifyNameWithEntityType(hp, name)
    [needsBanner, entityType] = matlab.internal.help.entityTypeNeedsBanner(hp.docLinks.referenceItem);
    if needsBanner
        name = getString(message("MATLAB:introspective:helpParts:HelpEntity" + string(entityType), name));
    end
end

function b = isPrimitiveType(topic)
    % This is the list of types in MATLAB that can be created with syntax.
    primitiveTypes = ["double", "single", "uint8", "uint16", "uint32", "uint64", "int8", "int16", "int32", "int64", "char", "struct", "cell", "logical", "function_handle", "string", "handle"];
    b = ismember(topic, primitiveTypes);
end

%   Copyright 2018-2024 The MathWorks, Inc.
