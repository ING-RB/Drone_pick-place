function customToolboxDocRoots = getCustomToolboxDocRoots()
%MATLAB.INTERNAL.DOC.PROJECT.GETCUSTOMTOOLBOXDOCROOTS Get all custom 
%toolbox docroots.
%   MATLAB.INTERNAL.DOC.PROJECT.GETCUSTOMTOOLBOXDOCROOTS Gets all custom 
%   toolbox docroots.

    customToolboxDocRoots = [];
    customToolboxes = matlab.internal.doc.project.getCustomToolboxes;
    if ~isempty(customToolboxes)
        customToolboxDocRoots = extractLocationOnDisk(customToolboxes);
    end    
end

function docroots = extractLocationOnDisk(customToolboxes)
    docroots = matlab.internal.doc.project.getDocRoots(customToolboxes);
end

% Copyright 2021 The MathWorks, Inc.
