function [shortname,group] = findMapKey(mapKey)
    shortname = "";
    group = "";

    shortnames = matlab.internal.doc.csh.getShortNames;
    for i = 1:length(shortnames)
        topicMap = matlab.internal.doc.csh.getTopicMapForProduct(shortnames(i));
        if ~isempty(topicMap)
            mapKeyIdx = find(topicMap(:,1) == mapKey);
            if ~isempty(mapKeyIdx)
                shortname = shortnames(i);
                group = string(topicMap(mapKeyIdx(1),2));
                group = regexprep(group, "^.*/([^\\/]+)\.map", "$1");
                return;
            end
        end
    end
end

