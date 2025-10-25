function helpStr = getHelpTextFromReferenceItem(refItem, docTopic, helpCommand, args)
    arguments
        refItem (1,1) matlab.internal.reference.api.ReferenceData;
        docTopic (1,1) string;
        helpCommand (1,1) string = "";
        args.justH1 (1,1) logical = false;
    end

    wantHyperlinks = helpCommand ~= "";

    hotName = matlab.internal.help.makeStrong(docTopic, wantHyperlinks, true);

    if contains(docTopic, lettersPattern)
        h1Name = hotName + " -";
    else
        h1Name = hotName;
    end

    helpStr = " " + h1Name + " " + refItem.Purpose;

    if args.justH1
        return;
    end

    helpStr = helpStr + newline;

    if refItem.Description ~= ""
        helpStr = helpStr + matlab.internal.help.indentAndWrap(refItem.Description, wantHyperlinks);
    end

    if refItem.DeprecationStatus ~= "Current"
        compatibilityMessage = matlab.internal.help.getCompatibilityMessage(docTopic);
        if compatibilityMessage == ""
            if refItem.DeprecationStatus < matlab.internal.reference.property.DeprecationStatus.Error
                compatibilityKey = "NotRecommended";
            else
                compatibilityKey = "Removed";
            end
            compatibilityMessage = getString(message("MATLAB:introspective:helpParts:" + compatibilityKey, docTopic));
        end
        if wantHyperlinks
            compatibilityMessage = replace(compatibilityMessage, "'" + docTopic + "'", hotName);
        end
        helpStr = helpStr + newline + matlab.internal.help.indentAndWrap(compatibilityMessage, wantHyperlinks);
    end

    refLocation = refItem.HelpLocation;

    if wantHyperlinks
        helpLocation = append(docroot, "/", refLocation);
    else
        helpLocation = "";
    end

    [isClass, isFormal] = isClassRefItem(refItem);
    hasPropertiesPage = false;
    if isClass && isempty(refItem.ClassPropertyGroups)
        classRefItem = getClassRefItem(docTopic, refItem.ProductName);
        hasPropertiesPage = ~isempty(classRefItem);
    end

    inputGroupProperties = matlab.internal.help.getInputGroupProperties(refItem.InputGroups);
    syntaxTypes = unique([refItem.SyntaxGroups.SyntaxType, inputGroupProperties.SyntaxType, refItem.Outputs.SyntaxType]);
    for syntaxType = syntaxTypes(:)'
        helpStr = helpStr + makeSyntaxSection(docTopic, wantHyperlinks, helpLocation, refItem, inputGroupProperties, syntaxType, isClass, hasPropertiesPage);
    end

    parameterString = makeArgumentsString(refItem.Parameters, helpLocation, indent);
    if parameterString ~= ""
        parameterHeader = indent + getHeaderForKey("Parameters");
        helpStr = helpStr + newline + parameterHeader + newline + parameterString + newline;
    end

    if isClass
        if ~any(string(syntaxTypes)=="CreateObject")
            % class property groups are included with the inputs of creation syntaxes
            % so if there aren't any, add them here.
            helpStr = helpStr + getClassPropertyGroupHelp(refItem, wantHyperlinks, hasPropertiesPage, indent);
        end

        [className, classMeta] = matlab.internal.help.getTopicFromReferenceItem(refItem);
        if ~isempty(classMeta)
            methods = filterInaccessibleMethods(classMeta);
        else
            methods = missing;
        end
        helpStr = helpStr + createHelpForMethodList(className, methods, isFormal, wantHyperlinks, helpCommand);
    end

    pageLocation = fileparts(refLocation + "/" + refItem.Href);

    if ~isempty(refItem.Examples)
        exampleHeader = getHeaderForKey("Examples");
        openCommands = [refItem.Examples.OpenCommand];
        noCommands = openCommands == "";
        if any(noCommands)
            exampleLinks = [refItem.Examples.Url];
            exampleLinks(~noCommands) = [];
            for i = 1:numel(exampleLinks)
                exampleLink = exampleLinks(i);
                exampleLink = urlPrefix(pageLocation, exampleLink);
                exampleLink = docroot + "/" + exampleLink;
                exampleLink = matlab.internal.help.makeDualCommand('web', exampleLink);
                exampleLinks(i) = exampleLink;
            end
            openCommands(noCommands) = exampleLinks;
        end
        if wantHyperlinks
            exampleTitles = [refItem.Examples.Title];
            examples = '<a href="matlab:' + openCommands + '">' + exampleTitles + "</a>";
        else
            examples = openCommands;
        end
        exampleBody = indent + [exampleHeader, indent(0.5) + examples];
        helpStr = helpStr + newline + join(exampleBody, newline) + newline;
    end

    if isPropertyRefItem(refItem)
        if ~isempty(refItem.ClassPropertyGroups) && ~isempty(refItem.ClassPropertyGroups(1).ClassProperties)
            property = refItem.ClassPropertyGroups(1).ClassProperties(1);
            if ~isempty(property.Values)
                helpStr = helpStr + makeValuesList(property) + newline;
            end
        end
    end

    if ~isempty(refItem.SeeAlso)
        seeAlso = getHeaderForKey("SeeAlsoSingleSource") + " ";
        seeAlsoNames = [refItem.SeeAlso.Name];
        if wantHyperlinks
            for i = 1:numel(seeAlsoNames)
                seeAlsoName = refItem.SeeAlso(i).Name;
                seeAlsoUrl = urlPrefix(pageLocation, refItem.SeeAlso(i).Url);
                [seeAlsoTarget, seeAlsoName] = resolveSeeAlso(seeAlsoName, seeAlsoUrl, refLocation);
                if seeAlsoTarget == ""
                    [seeAlsoTarget, seeAlsoName] = getTopicForUrl(seeAlsoName, seeAlsoUrl, refLocation);
                end
                if strlength(seeAlsoName) == 1
                    seeAlsoName = " " + seeAlsoName + " ";
                end
                if seeAlsoTarget ~= ""
                    seeAlsoNames(i) = matlab.internal.help.createMatlabLink(helpCommand, seeAlsoTarget, seeAlsoName);
                else
                    seeAlsoUrl = docroot + "/" + seeAlsoUrl;
                    seeAlsoNames(i) = matlab.internal.help.createMatlabLink('web', seeAlsoUrl, seeAlsoName);
                end
            end
        end
        seeAlsoNames(1) = indent(0.5) + seeAlso + seeAlsoNames(1);
        seeAlso = joinWithSpacesOrWrap(seeAlsoNames, ",", wantHyperlinks=wantHyperlinks, indentWrapped=true) + newline;
        helpStr = helpStr + newline + seeAlso;
    end

    if ~isPropertyRefItem(refItem)
        introducedIn = refItem.IntroducedIn;
        if introducedIn ~= ""
            if introducedIn.startsWith("pre")
                introducedIn = introducedIn.extractAfter("pre");
                introducedKey = "IntroducedBefore";
            else
                introducedKey = "IntroducedIn";
            end
            introducedMsg = getString(message("MATLAB:introspective:helpParts:" + introducedKey, refItem.ProductName, introducedIn));
            helpStr = helpStr + newline + indent + introducedMsg;
        end
    end

    helpStr = char(helpStr);
end

function url = urlPrefix(stem, url)
    while startsWith(url, "../") && stem ~= ""
        url = extractAfter(url, "../");
        stem = regexprep(stem, "/?[^/]*$", "");
    end
    if stem ~= ""
        url = stem + "/" + url;
    end
end

function [seeAlsoTarget, topic] = resolveSeeAlso(topic, url, parentLocation)
    refTopic = matlab.internal.doc.reference.ReferenceTopic(topic);
    refTopic.EntityPrecision = matlab.internal.reference.api.EntityPrecision.Exact_Match;
    [best, others] = matlab.lang.internal.introspective.getBestReferenceItem(refTopic, topic);
    refData = [best.item, others.item];
    if matlab.lang.internal.introspective.isClass(topic)
        classTypes = matlab.internal.doc.reference.getClassEntityTypes;
        classItems = arrayfun(@(rd)any(ismember([rd.RefEntities.RefEntityType], classTypes)), refData);
        refData = [refData(classItems), refData(~classItems)];
    end
    refUrls = [refData.HelpLocation] + "/" + [refData.Href];
    urlMatch = find(refUrls == url, 1);
    if isempty(urlMatch)
        seeAlsoTarget = "";
    else
        seeAlsoRefItem = refData(urlMatch);
        if urlMatch == 1
            seeAlsoTarget = topic;
        else
            qualifiedName = matlab.internal.help.getQualifiedNameFromReferenceItem(seeAlsoRefItem);
            if qualifiedName ~= topic
                seeAlsoTarget = qualifiedName;
            else
                seeAlsoTarget = seeAlsoRefItem.HelpFolder + "/" + topic;
            end
        end
        topic = qualifyTopicWithProduct(topic, seeAlsoRefItem, parentLocation);
    end
end

function [seeAlsoTarget, topic] = getTopicForUrl(topic, url, parentLocation)
    seeAlsoTarget = "";
    if contains(url, "/")
        product = extractBefore(url, "/");
        refUrl = extractAfter(url, "/");
    else
        product = "";
        refUrl = url;
    end
    request = matlab.internal.reference.api.ReferenceRequest(refUrl);
    request.Products = product;
    pageRetriever = matlab.internal.reference.api.PageNameDataRetriever(request);
    refItems = pageRetriever.getReferenceData;
    if ~isempty(refItems)
        seeAlsoRefItem = refItems(1);
        seeAlsoTarget = matlab.internal.help.getQualifiedNameFromReferenceItem(seeAlsoRefItem);
        if isClassRefItem(seeAlsoRefItem)
            className = shortenName(seeAlsoTarget);
            topic = qualifyTopicWithProduct(className, seeAlsoRefItem, parentLocation);
        else
            seeAlsoTarget = resolveSeeAlso(seeAlsoTarget, url, parentLocation);
        end
    end
end

function topic = qualifyTopicWithProduct(topic, seeAlsoRefItem, parentLocation)
    if ~ismember(seeAlsoRefItem.HelpLocation, [parentLocation, "matlab"])
        topic = topic + " (" + seeAlsoRefItem.ProductName + ")";
    end
end

function syntaxAndArguments = makeSyntaxSection(docTopic, wantHyperlinks, helpLocation, refItem, inputGroupProperties, syntaxType, isClass, hasPropertiesPage)
    if isClass && syntaxType == "NA"
        syntaxHeader = "CreateObject";
    else
        syntaxHeader = syntaxType;
    end
    if syntaxHeader ~= "NA"
        syntaxAndArguments = newline + indent + getHeaderForKey(string(syntaxHeader));
        prefix = indent(1.5);
    else
        syntaxAndArguments = "";
        prefix = indent;
    end
    if wantHyperlinks
        syntaxName = docTopic;
        shortName = shortenName(docTopic);
        if ~ismissing(shortName)
            syntaxName = "(" + syntaxName + "|" + shortName + ")";
        end
    end
    syntaxGroups = filterByType(refItem.SyntaxGroups, syntaxType);
    for i = 1:numel(syntaxGroups)
        syntaxGroup = syntaxGroups(i);
        syntaxes = syntaxGroup.Syntaxes;
        if wantHyperlinks
            syntaxes = regexprep(syntaxes, "\<" + syntaxName  + "\>", "<strong>$0</strong>");
        end
        syntaxes = indent(0.5) + syntaxes;
        title = syntaxGroup.Title;
        if title == "" && i == 1
            title = getHeaderForKey("Syntax");
        end
        if title ~= ""
            syntaxes = [title, syntaxes]; %#ok<AGROW>
        end
        syntaxAndArguments = syntaxAndArguments + newline + join(prefix + syntaxes + newline, "");
    end

    [inputGroupProperties, groupIndices] = filterByType(inputGroupProperties, syntaxType);
    inputGroups = refItem.InputGroups(groupIndices);
    nameValueIndices = [inputGroupProperties.isNameValuePair];
    nvInputs = inputGroups(nameValueIndices);
    inputs   = inputGroups(~nameValueIndices);
    syntaxAndArguments = syntaxAndArguments + makeInputGroupsString("Inputs", inputs, helpLocation, prefix);
    syntaxAndArguments = syntaxAndArguments + makeInputGroupsString("NameValueInputs", nvInputs, helpLocation, prefix);

    if syntaxType == "CreateObject"
        syntaxAndArguments = syntaxAndArguments + getClassPropertyGroupHelp(refItem, wantHyperlinks, hasPropertiesPage, prefix);
    end

    outputs = filterByType(refItem.Outputs, syntaxType);
    outputString = makeArgumentsString(outputs, helpLocation, prefix);
    if outputString ~= ""
        outputHeader = prefix + getHeaderForKey("Outputs");
        syntaxAndArguments = syntaxAndArguments + newline + outputHeader + newline + outputString + newline;
    end
end

function helpStr = getClassPropertyGroupHelp(refItem, wantHyperlinks, hasPropertiesPage, prefix)
    if hasPropertiesPage && wantHyperlinks
        fullName   = matlab.internal.help.getQualifiedNameFromReferenceItem(refItem);
        header     = prefix + getString(message("MATLAB:introspective:helpParts:ClassProperties"));
        properties = getString(message("MATLAB:introspective:helpParts:ClassDetails", shortenName(fullName)));

        propertiesCommand = "matlab:matlab.internal.help.displayPropertyList('" + fullName + "', '" + refItem.ProductName + "');";
        propertiesLink    = '<a href="' + propertiesCommand + '">' + properties + "</a>";

        helpStr = newline + header + newline + prefix + indent(0.5) + propertiesLink + newline;
    else
        helpStr = matlab.internal.help.getClassPropertyGroupHelp(refItem, wantHyperlinks, prefix);
    end
end

function [list, groupIndices] = filterByType(list, syntaxType)
    groupIndices = [list.SyntaxType] == syntaxType;
    list(~groupIndices) = [];
end

function helpStr = createHelpForMethodList(className, methods, isFormal, wantHyperlinks, helpCommand)
    helpStr = "";

    import matlab.internal.reference.property.RefEntityType;
    refRequest = matlab.internal.reference.api.ReferenceRequest(className, [RefEntityType.Method, RefEntityType.Function]);
    dataRetriever = matlab.internal.reference.api.ClassEntityDataRetriever(refRequest);
    methodItems = dataRetriever.getReferenceData;

    methodItemNames = strings(size(methodItems));
    for i = 1:numel(methodItems)
        methodItemNames(i) = getUnqualifiedNameFromReferenceItem(methodItems(i));
    end

    if ismissing(methods)
        methods = struct('Name', num2cell(setdiff(methodItemNames, regexp(className, '\w+$', 'match', 'once'))), 'Static', false);
    end

    methodNames = string({methods.Name});
    [methodNames, methodIndices, itemIndices] = intersect(methodNames, methodItemNames, "stable");
    methodItems = methodItems(itemIndices);

    if isempty(methodItems)
        return;
    end

    methods = methods(methodIndices);
    isStatic = [methods.Static];

    methodNames(isStatic) = className + "." + methodNames(isStatic);
    linkNames = methodNames;
    linkNames(~isStatic) = className + "/" + linkNames(~isStatic);

    if isFormal
        classFunctions = ~isStatic;
    else
        classFunctions = true(size(methods));
    end

    if any(classFunctions)
        paddedMethodList = createPaddedMethodList("ClassFunctions", methodNames, linkNames, methodItems, classFunctions, wantHyperlinks, helpCommand);
        helpStr = paddedMethodList + newline;
    end

    if isFormal && any(isStatic)
        paddedMethodList = createPaddedMethodList("StaticMethods", methodNames, linkNames, methodItems, isStatic, wantHyperlinks, helpCommand);
        helpStr = helpStr + paddedMethodList + newline;
    end
end

function paddedMethodList = createPaddedMethodList(headerKey, methodNames, linkNames, methodItems, methodIndices, wantHyperlinks, helpCommand)
    methodPurposes = [methodItems(methodIndices).Purpose];
    methodNames = methodNames(methodIndices);

    header = newline + indent + getString(message("MATLAB:introspective:helpParts:" + headerKey)) + newline;
    paddedMethods = pad(methodNames);
    if wantHyperlinks
        links = arrayfun(@(target, text)string(matlab.internal.help.createMatlabLink(helpCommand, target, text)), linkNames(methodIndices), methodNames);
        paddedMethods = links + extractAfter(paddedMethods, strlength(methodNames));
    end
    paddedMethods = indent(1.5) + paddedMethods + " - " + methodPurposes;
    paddedMethodList = header + join(paddedMethods, newline);
end

function entityName = getUnqualifiedNameFromReferenceItem(refItem)
    entityName = refItem.RefEntities(1).Name;
    entityName = shortenName(entityName);
end

function inputGroupsString = makeInputGroupsString(key, inputGroups, helpLocation, prefix)
    if isempty(inputGroups)
        inputGroupsString = "";
    else
        inputGroups = mergeConsecutiveUntitledGroups(inputGroups);
        inputGroupsString = strings(size(inputGroups));
        for i = 1:numel(inputGroups)
            inputGroup = inputGroups(i);
            if inputGroup.Title ~= ""
                groupPrefix = prefix + indent(0.5);
                inputGroupString = groupPrefix + inputGroup.Title + newline;
            else
                groupPrefix = prefix;
                inputGroupString = "";
            end
            inputGroupString = inputGroupString + makeArgumentsString(inputGroup.Inputs, helpLocation, groupPrefix);
            inputGroupsString(i) = inputGroupString;
        end
        header = prefix + getHeaderForKey(key);
        inputGroupsString = join(inputGroupsString, [newline, newline]);
        inputGroupsString = newline + header + newline + inputGroupsString + newline;
    end
end

function inputGroups = mergeConsecutiveUntitledGroups(inputGroups)
    noTitle = [inputGroups.Title] == "";
    consecutiveNoTitle = find([false, noTitle] & [noTitle, false]);
    for i = fliplr(consecutiveNoTitle)
        inputGroups(i-1).Inputs = [inputGroups(i-1).Inputs, inputGroups(i).Inputs];
        inputGroups(i) = [];
    end
end

function argumentsString = makeArgumentsString(args, helpLocation, prefix)
    if isempty(args)
        argumentsString = "";
    else
        argumentStrings = strings(size(args));
        for i = 1:numel(args)
            argumentStrings(i) = makeValueString(args(i), helpLocation, prefix);
        end
        argumentsString = join(argumentStrings, newline);
    end
end

function header = getHeaderForKey(key)
    header = getString(message("MATLAB:introspective:helpParts:" + key));
end

function b = isPropertyRefItem(refItem)
    import matlab.internal.reference.property.RefEntityType;
    b = any([refItem.RefEntities.RefEntityType] == RefEntityType.Property);
end

function [isClass, isFormal] = isClassRefItem(refItem)
    itemTypes = [refItem.RefEntities.RefEntityType];
    isClass = any(ismember(itemTypes, matlab.internal.doc.reference.getClassEntityTypes));
    if isClass
        isFormal = any(itemTypes == "Class");
    else
        isFormal = false;
    end
end

%   Copyright 2013-2025 The MathWorks, Inc.
