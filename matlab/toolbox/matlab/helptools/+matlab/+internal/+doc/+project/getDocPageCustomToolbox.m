function docPageCustomToolbox = getDocPageCustomToolbox(pathOrName, contentType) 
%MATLAB.INTERNAL.DOC.PROJECT.GETDOCPAGECUSTOMTOOLBOX Get data needed to
%build a DocPage for a custom toolbox. This structure data parallels the
%doc page product data used to build DocPages for products.
%   MATLAB.INTERNAL.DOC.PROJECT.GETDOCPAGECUSTOMTOOLBOX Gets the custom 
%   toolbox data identified by Short Name, Display Name, Unique Id, Help 
%   Location (relative path from docroot), or the Location on Disk.

    if nargin == 1
        contentType = '';
    end

    docPageCustomToolbox = struct.empty;
    toolbox = matlab.internal.doc.project.getCustomToolbox(pathOrName);

    if isempty(toolbox)
        return;
    end
        
    if isempty(contentType)
        % If pathOrName contains a help location we can figured out what 
        % the content type is. 
        contentType = getContentTypeFromHelpLocation(pathOrName, toolbox);
    end

    docPageCustomToolbox = getDocPageToolbox(toolbox, contentType);
end

function contentType = getContentTypeFromHelpLocation(pathOrName, customToolbox)
    contentType = ''; 
    locationOnDisk = matlab.internal.doc.project.validateFolder(fullfile(pathOrName));
    toolboxHelpLocations = customToolbox.toolboxHelpLocations;
    for k=1:numel(toolboxHelpLocations)
        toolboxHelpLocation = toolboxHelpLocations(k);        
        if strcmp(pathOrName, toolboxHelpLocation.helpLocation) || ...
            strcmp(locationOnDisk, fullfile(toolboxHelpLocation.locationOnDisk))
                contentType = toolboxHelpLocation.contentType;
               return;
        end        
    end
end

function toolbox = getDocPageToolbox(customToolbox, contentType)
    if ~isempty(contentType)
        toolbox = getDocPageToolboxForContentType(customToolbox, contentType);
        return;
    end

    % Default to doc if we don't know what the content type is.
    toolbox = getDocPageToolboxForContentType(customToolbox, 'doc');
    if ~isempty(toolbox)
        return;
    end

    toolbox = getDocPageToolboxForContentType(customToolbox, 'examples');
end

function toolbox = getDocPageToolboxForContentType(customToolbox, contentType)
    toolbox = struct.empty;
    helpLocation = getToolboxHelpLocaton(customToolbox, contentType);
    if ~isempty(helpLocation)
        toolbox = getDocPageToolboxForHelpLocation(customToolbox, helpLocation);
    end
    if ~isempty(toolbox)
        % Add other content type
        otherContentType = getOtherContentType(contentType);
        otherToolboxHelpLocation = getToolboxHelpLocaton(customToolbox, otherContentType);
        if ~isempty(otherToolboxHelpLocation)
            helpLocationData = getHelpLocationData(otherToolboxHelpLocation);
            toolbox.OtherToolboxHelpLocation = helpLocationData; 
        end
    end
end

function toolbox = getDocPageToolboxForHelpLocation(customToolbox, toolboxHelpLocation)
    baseData = getBaseData(customToolbox);
    helpLocationData = getHelpLocationData(toolboxHelpLocation);

    % Merge the two structs.
    baseDataTable = struct2table(baseData,'AsArray',true);
    helpLocationDataTable = struct2table(helpLocationData,'AsArray',true);

    % Concatonate tables
    toolboxTable = [baseDataTable, helpLocationDataTable];

    % Convert table to structure
    toolbox = table2struct(toolboxTable);    
end

function baseData = getBaseData(customToolbox)
    baseData = struct;
    baseData.DisplayName = customToolbox.name;
    baseData.ShortName = customToolbox.shortName;
    baseData.UniqueId = customToolbox.uniqueId;    
    baseData.BaseCode = '';
end

function helpLocationData = getHelpLocationData(toolboxHelpLocation)
    helpLocationData = struct;
    helpLocationData.HelpLocation = toolboxHelpLocation.helpLocation;
    helpLocationData.LocationOnDisk = toolboxHelpLocation.locationOnDisk;
    helpLocationData.ContentType = toolboxHelpLocation.contentType;
    helpLocationData.LandingPage = toolboxHelpLocation.landingPage;
end

function toolboxHelpLocation = getToolboxHelpLocaton(customToolbox, contentType)
    toolboxHelpLocation = struct.empty;
    toolboxHelpLocations = customToolbox.toolboxHelpLocations;
    for k=1:numel(toolboxHelpLocations)
        helpLocation = toolboxHelpLocations(k);
        if strcmp(helpLocation.contentType, contentType)
            toolboxHelpLocation = helpLocation;
            return;
        end
    end
end

function otherContentType = getOtherContentType(contentType)
    switch contentType
       case 'doc'
           otherContentType = 'examples';
       case 'examples'
           otherContentType = 'doc';
    end     
end

% Copyright 2021 The MathWorks, Inc.