function allBaseFolders = getBaseFolderFromFilename(filenames)
% 

% Copyright 2023 The MathWorks, Inc.

filenames = string(filenames);
allBaseFolders = fileparts(filenames);
done = false(size(allBaseFolders));
while any(~done, "all")
    [baseFolders, folderOrFiles, extensions] = fileparts(allBaseFolders(~done));
    nowDone = ~startsWith(folderOrFiles, ["+","@"]);
    baseFolders(nowDone) = fullfile(baseFolders(nowDone), folderOrFiles(nowDone) + extensions(nowDone));
    allBaseFolders(~done) = baseFolders;
    done(~done) = nowDone;
end
end
