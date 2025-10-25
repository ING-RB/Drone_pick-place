function cshStruct = requestNewWaveCsh(topic)
% requestNewWaveCsh get reference Data for requested topic
% cshStruct = requestNewWaveCsh(topic) gets CSH text for topic.

%   Copyright 2023-2025 The MathWorks, Inc.

    cshStruct = struct.empty;
    if topic ~= ""
        refItem = matlab.internal.doc.csh.getRefItem(topic);
        if isempty(refItem)
            helpData = help(topic);
            if helpData ~= ""
                cshStruct(1).header.title = topic;
                cshStruct(1).helptext = helpData;
            end
        else
            cshStruct = struct('popout', buildPopout(refItem));
        end
    end
end

function popout = buildPopout(refItem)
    headerData = struct('title', refItem.RefEntities(1).Name, ...
                    'docurl', string(getDocUrl(refItem)), ...
                    'subheader', refItem.Purpose);

    description = refItem.Description;
    syntax = [];
    if ~isempty(refItem.SyntaxGroups)
        for i = 1:length(refItem.SyntaxGroups)
            syntax = [syntax refItem.SyntaxGroups(i).Syntaxes];
        end
    end

    content = struct('type', {'separator', 'Description', 'syntax'}, 'data', {[], description, syntax});
    popout = struct('header', headerData, 'content', content);

    % Access Inputs from InputGroups
    if ~isempty(refItem.InputGroups)
        inputGroupProperties = matlab.internal.help.getInputGroupProperties(refItem.InputGroups);
        [regularInputs, nameValueInputs] = categorizeInputs(refItem.InputGroups, inputGroupProperties);
        popout.content(end+1) = createInputContent('inputs', regularInputs, refItem);
        popout.content(end+1) = createInputContent('NVArgs', nameValueInputs, refItem);
    end

    % Get Output Args
    if ~isempty(refItem.Outputs)
        outputArgs = getArgumentsStruct(refItem.Outputs, refItem);
        popout.content(end+1) = struct('type', 'Outputs', 'data', outputArgs);
    end

    if ~isempty(refItem.Examples)
        examples = getExamples(refItem);
        popout.content(end+1) = struct('type', {'Examples'}, 'data', {examples});
    end
end


function groupedData = createGroupedArgumentsData(groupedInputs, refItem)
    groupedData = struct('group', {}, 'arguments', {});
    for group = groupedInputs
        if ~isempty(group.Inputs)
            newGroup.group = group.Title;
            newGroup.arguments = getArgumentsStruct(group.Inputs, refItem);
            groupedData(end+1) = newGroup;
        end
    end
end

function argStruct = getArgumentsStruct(args, refItem)
    baseUrl = getDocUrl(refItem).getUrl;
    if ~isempty(baseUrl.Path)
        baseUrl.Path = baseUrl.Path(1:end-2);
    end

    argStruct = struct;
    for i = numel(args):-1:1
        argument = args(i);
        argUrl = matlab.net.URI(baseUrl);
        argUrl.Path = [argUrl.Path argument.Href];
        argStruct(i).name = argument.Name;
        argStruct(i).purpose = argument.Purpose;
        argStruct(i).argValues = argument.Values;
        argStruct(i).url = string(argUrl);
    end

    if isscalar(argStruct)
        argStruct = {argStruct};
    end
end

function [regularInputs, nameValueInputs] = categorizeInputs(inputGroups, inputGroupProperties)
    isNameValue = [inputGroupProperties.isNameValuePair];
    regularInputs = inputGroups(~isNameValue);
    nameValueInputs = inputGroups(isNameValue);
end

function docUrl = getDocUrl(refItem)
    docUrl = matlab.internal.doc.url.MwDocPage;
    docUrl.Product = refItem.HelpLocation;
    docUrl.RelativePath = refItem.Href;  
end

function examplesStruct = getExamples(refItem)
    baseUrl = getDocUrl(refItem).getUrl;
    if ~isempty(baseUrl.Path)
        baseUrl.Path(end) = [];
    end

    examplesStruct = struct;
    for i = numel(refItem.Examples):-1:1
        example = refItem.Examples(i);
        exampleUrl = matlab.net.URI(baseUrl);
        exampleUrl.Path = [exampleUrl.Path example.Url];
        examplesStruct(i).title = example.Title;
        examplesStruct(i).url = string(exampleUrl);
        examplesStruct(i).open_command = example.OpenCommand;
    end

    if isscalar(examplesStruct)
        examplesStruct = {examplesStruct};
    end
end

function contentItem = createInputContent(inputType, inputs, refItem)
    contentItem.type = inputType;
    contentItem.data = [];
    if ~isempty(inputs)
        contentItem.data = createGroupedArgumentsData(inputs, refItem);
    end
end