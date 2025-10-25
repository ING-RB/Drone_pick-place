function help_json = help2json(topic, commandOption)
    helpStruct = struct;

    helpForTopicStruct = matlab.internal.help.helpwin.help4topicStruct(topic, commandOption);
    actions = matlab.internal.help.helpwin.helpActions(helpForTopicStruct.topic, helpForTopicStruct.helpstr, helpForTopicStruct.docTopic, helpForTopicStruct.found, commandOption);

    footers = struct;
    helpstr = '';
    if (~isempty(actions.fcnName))
        if (actions.found)
            [footers,helpstr] = matlab.internal.help.helpwin.helpFooters(helpForTopicStruct.helpstr, actions.fcnName);
        else
            helpstr = matlab.internal.help.helpwin.getNoHelpFoundContent(helpForTopicStruct.topic);
        end
    end

    body = struct;
    body.title = actions.nameForTitle;
    body.helptext = helpstr;
    helpStruct.body = body;
    helpStruct.helpActions = actions;
    helpStruct.footers = num2cell(footers);

    help_json = jsonencode(helpStruct);
end

%   Copyright 2020-2024 The MathWorks, Inc.
