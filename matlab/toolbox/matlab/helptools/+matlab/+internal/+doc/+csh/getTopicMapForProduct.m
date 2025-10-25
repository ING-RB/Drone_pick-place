function topicMap = getTopicMapForProduct(shortname)
    persistent mapsCache;
    if isempty(mapsCache)
        mapsCache = matlab.internal.doc.services.HelpSystemCache;
        mapsCache.Data = struct;
    end
    
    nameField = matlab.lang.makeValidName(shortname);
    allMaps = mapsCache.Data;
    if isfield(allMaps,nameField)
        topicMap = allMaps.(nameField);
    else
        topicMap = loadTopicMap(shortname);
        allMaps.(nameField) = topicMap;
        mapsCache.Data = allMaps;
    end
end

function topicMap = loadTopicMap(shortname)
    docCatalogFiles = matlab.internal.doc.csh.findDocCatalogFiles("cshapi_topicmap", shortname, ".loc");
    topicMap = matlab.internal.doc.csh.readTopicMapFiles(docCatalogFiles);
end