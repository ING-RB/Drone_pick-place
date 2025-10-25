function obj = testFolders(obj, folders)
    %testFolders Runs runTests on files in folders

    %   Copyright 2021 The MathWorks, Inc.
%     folders = convertCharsToStrings(folders);
%     for folder = folders'
%         obj = obj.processFolder(folder);
%     end
    for i = 1:numel(folders)
        obj = obj.processFolder(folders{i});
    end
end
