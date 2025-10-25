function suite = addPathAndCurrentFolderFixturesIfNeeded(suite)
% Add fixtures if test content isn't on the path already.

% Copyright 2018-2021 The MathWorks, Inc.

markers = [suite.ClassBoundaryMarker];
[~, idxA, idxC] = unique(markers);
baseFoldersForUniqueClasses = {suite(idxA).BaseFolder};
baseFolders = baseFoldersForUniqueClasses(idxC);

[uniqueBaseFolders, ~, uniqueIdx] = unique(baseFolders);
pathFolders = string(path).split(pathsep);
onPath = ismember(uniqueBaseFolders, pathFolders);

for idx = find(~onPath(:).')
    mask = uniqueIdx == idx;
    suite(mask) = suite(mask).addInternalPathAndCurrentFolderFixtures(uniqueBaseFolders{idx});
end
end

