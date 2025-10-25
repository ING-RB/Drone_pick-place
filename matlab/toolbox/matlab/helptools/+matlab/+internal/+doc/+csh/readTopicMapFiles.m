function topicMap = readTopicMapFiles(files)
    if ~nargin || isempty(files)
        topicMap = strings(0,2);
    else
        topicMap = readTopicMapFile(files(1));
        if length(files) > 1
            enTopicMap = readTopicMapFile(files(2));
            % Only include the English topics that are not already
            % in the translated topic map.
            [~, dupes] = intersect(enTopicMap(:,1), topicMap(:,1));
            enTopicMap(dupes,:) = [];
            topicMap = [topicMap; enTopicMap];
        end
    end
end

function topicMap = readTopicMapFile(file)
    if isfile(file)
        fid = fopen(file);
        topicdata = textscan(fid,'%s %s');
        oc = onCleanup(@() fclose(fid));
        topicMap = [string(topicdata{1}) string(topicdata{2})];
    else
        topicMap = strings(0,2);
    end
end
