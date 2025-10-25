function custom_toolboxes = getCustomToolboxes
%MATLAB.INTERNAL.DOC.PROJECT.GETCUSTOMTOOLBOXES Get all custom toolboxes.
%   MATLAB.INTERNAL.DOC.PROJECT.GETCUSTOMTOOLBOXES Gets all custom 
%   toolboxes.

    persistent fileList;
    persistent customToolboxes;
    docFiles = matlab.internal.doc.project.getFiles('info.xml');
    demoFiles = matlab.internal.doc.project.getFiles('demos.xml');
    allFiles = [docFiles; demoFiles];
    if filesChanged(fileList, allFiles)
        customToolboxes = matlab.internal.doc.project.buildToolboxStruct(docFiles,demoFiles);
        fileList = extractFileList(customToolboxes);
        matlab.internal.doc.project.addCustomDocContentToConnector(customToolboxes);
    end
    custom_toolboxes = customToolboxes;
end

function files_changed = filesChanged(oldFileList, newFileList)
    files_changed = 0;
    if isempty(oldFileList)
        files_changed = 1;
        return;
    end
    
    if length(oldFileList) ~= length(newFileList)
        files_changed = 1;
        return;        
    end  
    
    inBoth = intersect(oldFileList, newFileList);
    if length(inBoth) ~= length(newFileList)
        files_changed = 1;
        return;        
    end
end

function file_list = extractFileList(customToolboxes)
    file_list = '';
    if isempty(customToolboxes)
        return;
    end

    % Extract absolutePath column from the toolboxHelpLocations struct.
    t = cell2mat({customToolboxes(:).toolboxHelpLocations}');
    file_list = [t.absolutePath]';
end

% Copyright 2021-2022 The MathWorks, Inc.