function success = index(helploc)
    success = false;
    customToolbox = matlab.internal.doc.project.getCustomToolbox(helploc);
    if isempty(customToolbox)
        return;
    end

    extension = '';
    if ispc
        extension = '.exe';
    end

    customToolboxInfoFileID = fopen(fullfile(helploc, 'custom_toolbox.json'), 'w');
    tbxHelpLocation = {};
    for loc = 1:length(customToolbox.toolboxHelpLocations)
        toolboxHelpLocation = customToolbox.toolboxHelpLocations(loc);
        toolboxHelpLocStruct = struct("ContentType", toolboxHelpLocation.contentType,...
            "LocationOnDisk", toolboxHelpLocation.locationOnDisk,...
            "AbsolutePath", toolboxHelpLocation.absolutePath,...
            "HelpLocation", toolboxHelpLocation.helpLocation);
        tbxHelpLocation = [tbxHelpLocation, toolboxHelpLocStruct];
    end
    exportData = struct("Name", customToolbox.name,...
        "ShortName", customToolbox.shortName,...
        "ID", customToolbox.uniqueId,...
        "ToolboxHelpLocations", {tbxHelpLocation});

    json_content = jsonencode(exportData);
    fprintf(customToolboxInfoFileID, '%s', json_content);
    fclose(customToolboxInfoFileID);

    mwdocsearch = string(fullfile(matlabroot,'bin',computer('arch'),'mwdocsearch')) + extension;
    args = " customdocindex -d """ + helploc + """"; 
    system("""" + mwdocsearch + """" + args);
    success = true;
end
