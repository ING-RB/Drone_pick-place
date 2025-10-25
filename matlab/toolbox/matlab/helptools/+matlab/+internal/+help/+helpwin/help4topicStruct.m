function help_for_topic_struct = help4topicStruct(topic, commandOption)
    [topic, helpstr, docTopic, found] = matlab.internal.help.helpwin.help4topic(topic, commandOption);

    help_for_topic_struct = struct;
    help_for_topic_struct.topic = topic;
    help_for_topic_struct.helpstr = helpstr;
    help_for_topic_struct.docTopic = docTopic;
    help_for_topic_struct.found = found;
end

%   Copyright 2020-2024 The MathWorks, Inc.
