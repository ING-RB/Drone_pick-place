function refItem = getRefItem(topic)
    arguments
        topic (1,1) string
    end

    refItem = struct.empty;
    refTopics = matlab.internal.doc.reference.buildReferenceTopic(topic, false);

    for refTopic = refTopics
        refItems = refTopic.getReferenceData;
        if ~isempty(refItems)
            refItem = refItems(1);
            return
        end
    end
end
