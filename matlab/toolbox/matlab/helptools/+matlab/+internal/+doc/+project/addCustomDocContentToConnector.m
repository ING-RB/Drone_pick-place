function addCustomDocContentToConnector(customToolboxes)
    if isempty(customToolboxes)
        % nothing to map
        return;
    end    
    if connector.isRunning
        addStaticContentOnPath(customToolboxes);
    end
end

function addStaticContentOnPath(customToolboxes)
    for c = 1:numel(customToolboxes)
        toolbox = customToolboxes(c);
        toolboxHelpLocations = toolbox.toolboxHelpLocations;
        for i = 1:numel(toolboxHelpLocations)
            toolboxHelpLocation = toolboxHelpLocations(i);
            % Map the absolute path to the folder location on disk
            % to the helpLocation (the relative path under docroot).
            path = toolboxHelpLocation.locationOnDisk;
            route = strcat('help/',toolboxHelpLocation.helpLocation);
            % TODO: Can I pass in the locale settings like we do in java?
            % TODO: Adding localized content isn't supported in the MATLAB API.
            connector.addStaticContentOnPath(route, path);
        end
    end
end

% Copyright 2021 The MathWorks, Inc.