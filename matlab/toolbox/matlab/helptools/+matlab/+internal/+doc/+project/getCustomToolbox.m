function customToolbox = getCustomToolbox(pathOrName) 
%MATLAB.INTERNAL.DOC.PROJECT.GETCUSTOMTOOLBOX Get a custom toolbox. 
%   MATLAB.INTERNAL.DOC.PROJECT.GETCUSTOMTOOLBOX(pathOrName) Gets the 
%   custom toolbox identified by Short Name, Display Name, Unique Id, Help
%   Location (relative path from docroot), or the Location on Disk.

    customToolbox = struct.empty;
    customToolboxes = matlab.internal.doc.project.getCustomToolboxes;    
    if isempty(customToolboxes)
        return;
    end

    toolbox = getToolbox(pathOrName, customToolboxes);
    if ~isempty(toolbox)
        customToolbox = toolbox;
        return;
    end
end

function toolbox = getToolbox(pathOrName, customToolboxes)
    toolbox = struct.empty;
    for c = 1:length(customToolboxes)
        customToolbox = customToolboxes(c);
        if strcmp(pathOrName, customToolbox.shortName) || ...
           strcmp(pathOrName, customToolbox.name) || ...
           strcmp(pathOrName, customToolbox.uniqueId)
               toolbox = customToolbox;
               return;
        end      

        locationOnDisk = matlab.internal.doc.project.validateFolder(fullfile(pathOrName));
        toolboxHelpLocations = customToolbox.toolboxHelpLocations;
        for k=1:numel(toolboxHelpLocations)
            toolboxHelpLocation = toolboxHelpLocations(k);
            if strcmp(pathOrName, toolboxHelpLocation.helpLocation) || ...
                strcmp(locationOnDisk, fullfile(toolboxHelpLocation.locationOnDisk))
                   toolbox = customToolbox;
                   return;
            end        
        end
    end    
end

% Copyright 2021 The MathWorks, Inc.