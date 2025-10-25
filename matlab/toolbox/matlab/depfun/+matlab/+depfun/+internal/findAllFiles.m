function fullList = findAllFiles(fileAndFolderList)

fullList = {};

if ischar(fileAndFolderList)
    fileAndFolderList = {fileAndFolderList};
end
dd = cellfun(@dir, fileAndFolderList, 'UniformOutput', false);

for i = 1:length(dd)
    for j = 1:length(dd{i})
        if ~(strcmp(dd{i}(j).name, '.') || strcmp(dd{i}(j).name, '..'))
        fullpath = fullfile(dd{i}(j).folder, dd{i}(j).name);
        if dd{i}(j).isdir
            fileList = matlab.depfun.internal.findAllFiles(fullpath);
        else
            fileList = {fullpath};
        end
        fullList = horzcat(fullList, fileList);
        end
    end
end

end