function [folderName, isValidFolder] = validateFolder(folder)
    folderName = folder;
    isValidFolder = false;
    if isfolder(folder)
        [~,attr] = fileattrib(folder);
        if ~isempty(attr) && isfield(attr,'Name')
            folderName = string(attr.Name);
            isValidFolder = true;
            return;
        end
    end
end

% Copyright 2021-2022 The MathWorks, Inc.
