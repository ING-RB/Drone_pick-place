function docColumn = documentationColumn(caChecks)
%documentationColumn gets a column of documentation commands used by the Code Compatibility Report.

%   Copyright 2017-2021 The MathWorks, Inc.

    persistent docColumnCache
    if isequal(docColumnCache, [])
        % Initialize cache only once.
        docColumnCache = getDocumentationHelpCommands(caChecks);
    end
    docColumn = docColumnCache;
end

function docColumn = getDocumentationHelpCommands(caChecks)
% Find the unique combinations of HelpFolder and HelpMap.
% In doc api, HelpFolder = product, HelpMap = group.
[uniqueProductGroup, ~, indexUniqueProductGroup] = unique(caChecks(:, {'HelpFolder','HelpMap'}), "rows");
isDocumented = zeros(height(caChecks), 1);

for i = 1:size(uniqueProductGroup, 1)
    docProduct = string(uniqueProductGroup.HelpFolder(i));
    docGroup = string(uniqueProductGroup.HelpMap(i));
    docTopicMap = matlab.internal.doc.csh.DocPageTopicMap(docProduct, docGroup);

    % With indexProductGroup, use logical indexing to see only the rows
    % associated with the current product and group.
    indexProductGroup = indexUniqueProductGroup == i;

    % Get an array of doc topic IDs (doc anchor IDs) for this group.
    docTopicIds = caChecks.DocAnchorId(indexProductGroup);

    % With the doc topic IDs grouped in an array, determine if they exist.
    % DocPageTopicMap will soon have a topicExists method, which is faster.
    if ismethod(docTopicMap, "topicExists")
        % For performance, only check if topic ID exist.
        docTopicIdsFound = docTopicMap.topicExists(string(docTopicIds));
    else
        pages = docTopicMap.mapTopic(string(docTopicIds));
        docTopicIdsFound = [pages.IsValid];
    end

    % Using product-group index, update whether it exists. 
    isDocumented(indexProductGroup) = docTopicIdsFound;
end

% Construct the helpview command. If it doesn't exist, then remove it.
helpViewCommands = "helpview(""" + caChecks.HelpFolder + "/" + caChecks.HelpMap + """,""" + caChecks.DocAnchorId + """)";
helpViewCommands(~isDocumented) = "";

docColumn = helpViewCommands;
end
