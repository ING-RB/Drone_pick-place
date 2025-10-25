
function hasTopic = hasTopicForID(ID, shortName, mapFile)
    topic = string.empty;
    hasTopic = false;
    try
    	if isempty(shortName) && ~isempty(mapFile)
        	topic = matlab.internal.doc.csh.mapTopic(mapFile, ID);
    	elseif ~isempty(shortName) && isempty(mapFile)
        	topic = matlab.internal.doc.csh.mapTopic(shortName, ID);
    	end

    	hasTopic = ~isempty(topic) && topic ~= "";
    catch

    end
    
end

