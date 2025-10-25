function docroots = getDocRoots(customToolboxes)
    docroots = '';
    if isempty(customToolboxes)
        return;
    end

    % Extract locationOnDisk column from the toolboxHelpLocations struct.
    toolboxHelpLocations = struct.empty;
    toolboxHelpLocations = cat(1,toolboxHelpLocations,customToolboxes.toolboxHelpLocations);
    docroots = [toolboxHelpLocations.locationOnDisk];
end

% Copyright 2021 The MathWorks, Inc.
