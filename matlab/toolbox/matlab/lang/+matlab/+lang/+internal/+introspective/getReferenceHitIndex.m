function best = getReferenceHitIndex(topic, whichTopic, classInfo, toolbox)
    arguments
        topic      (1,1) string;
        whichTopic (1,1) string = "";
        classInfo               = []
        toolbox    (1,1) string = "";
    end

    refTopicBuilder = matlab.internal.doc.reference.ReferenceTopicBuilder(topic, false, whichTopic, classInfo, toolbox);
    refTopics = refTopicBuilder.buildRefTopics;

    best = matlab.lang.internal.introspective.getBestReferenceItem(refTopics, topic);
    best.isConstructor = ~isempty(refTopicBuilder.ClassInfo) && refTopicBuilder.ClassInfo.isConstructor;
end

%   Copyright 2008-2023 The MathWorks, Inc.
