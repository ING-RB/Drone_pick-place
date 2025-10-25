function toolbox_struct = buildToolboxStruct(docFiles,demoFiles)
    toolboxStruct = struct([]);
    docFileStructArray = getSourceFileStructArray(docFiles);
    demoFileStructArray = getSourceFileStructArray(demoFiles);

    % Iterate over the demo files.
    for c = 1:length(demoFileStructArray)
        demoFileStruct = demoFileStructArray(c);
        demoFile = demoFileStruct.path;

        % Find a doc file for the demo file toolbox.
        [docFileStruct, docFileStructArray] = findDocFileForDemoFile(demoFile, docFileStructArray);
        if ~isempty(docFileStruct)
            % Create a toolbox struct with doc and examples.
            toolboxHelpLocations = getDocAndExampleToolboxHelpLocations(docFileStruct,demoFileStruct);
            if validateHelpLocations(toolboxHelpLocations)
                docFileStruct.toolboxHelpLocations = toolboxHelpLocations;
                docFileStruct.urlpath = join(getRelativePath(docFileStruct.shortName),"/");
                toolboxStruct = cat(1,toolboxStruct,docFileStruct);
            end
        else
            % Create a toolbox struct with examples only.
            toolboxHelpLocation = getToolboxHelpLocation(demoFileStruct,'examples');
            if validateHelpLocation(toolboxHelpLocation)
                demoFileStruct.toolboxHelpLocations = toolboxHelpLocation;
                demoFileStruct.urlpath = join(getRelativePath(demoFileStruct.shortName),"/");
                toolboxStruct = cat(1,toolboxStruct,demoFileStruct);
            end
        end
    end

    % Iterate over the remaining doc files.
    for c = 1:length(docFileStructArray)
        docFileStruct = docFileStructArray(c);
        % Create a toolbox struct with doc only.
        toolboxHelpLocation = getToolboxHelpLocation(docFileStruct, 'doc');
        if validateHelpLocation(toolboxHelpLocation)
            docFileStruct.toolboxHelpLocations = toolboxHelpLocation;
            docFileStruct.urlpath = join(getRelativePath(docFileStruct.shortName),"/");
            toolboxStruct = cat(1,toolboxStruct,docFileStruct);
        end
    end

    % Extract only the fields we want to return.
    fieldsToKeep = ["name","shortName", "uniqueId", "toolboxHelpLocations", "urlpath"];
    fieldsToRemove = setdiff(fieldnames(toolboxStruct), fieldsToKeep);
    toolbox_struct = rmfield(toolboxStruct,fieldsToRemove);
end

% Get initial information from the source files that we'll use later in
% processing.
function fileStructArray = getSourceFileStructArray(files)
    fileStructArray = struct([]);
    % Remove an empty stings from the files string array.
    files(arrayfun(@(files) strcmp(files, ""),files))=[];
    for c = 1:length(files) 
        file = files{c};
        fileStruct = getSourceFileStruct(file);
        if ~isempty(fileStruct)
            fileStructArray = cat(1,fileStructArray,fileStruct);
        end
    end 
end

function fileStruct = getSourceFileStruct(file)
    fileStruct = struct.empty;
    xmlFileStruct = readXmlFile(file);    
    if isempty(xmlFileStruct)
        return ;
    end

    [filepath,name,~] = fileparts(file);  
    fileStruct = struct;
    fileStruct.filepath = filepath;
    fileStruct.path = file; 

    switch name
        case 'info'
            updateDocSourceFileStruct;
        case 'demos'
            updateExamplesSourceFileStruct;
    end

    function updateDocSourceFileStruct
        validSourceFile = validateDocSourceFile;
        if ~validSourceFile
            fileStruct = struct.empty;
            return;
        end
        % Only use potentially localized characters when building the 
        % display name.
        fileStruct.name = getDocToolboxName(xmlFileStruct, true);
        fileStruct.shortName = getShortname(getDocToolboxName(xmlFileStruct, false));       
        fileStruct.uniqueId = getUniqueId(fileStruct.shortName);
        % The doc help location is defined in the info.xml file.
        xmlFileStruct.help_location = fixSlashes(xmlFileStruct.help_location);
        % Validate the locationOnDisk, canonicalizing the path.
        % If the return value is is not a valid folder, return an empty 
        % struct. The toolbox will not be included with the doc.
        [locationOnDisk, isValidFolder] = getLocationOnDisk(fullfile(fileStruct.filepath, xmlFileStruct.help_location), fileStruct.name);
        if isValidFolder
            fileStruct.locationOnDisk = locationOnDisk;
        else
            fileStruct = struct.empty;
            return;
        end
        % Get the doc landing page from the 'helptoc.xml' file.
        % If the return value is not a valid file, return an empty struct. 
        % The toolbox will not be included with the doc.
        [landingPage, isValidFile] = getDocLandingPage(locationOnDisk, fileStruct.name);
        if isValidFile
            fileStruct.landingPage = landingPage;
        else
            fileStruct = struct.empty;
        end
    end

    function validSourceFile = validateDocSourceFile
        % name and help_location are required to support doc.
        validName = validateName;
        validHelpLocation = validateHelpLocation;
        validSourceFile = validName && validHelpLocation;
    end

    function updateExamplesSourceFileStruct
        validSourceFile = validateName;
        if ~validSourceFile
            fileStruct = struct.empty;
            return;
        end
        fileStruct.name = xmlFileStruct.name;
        fileStruct.shortName = getShortname(fileStruct.name);   
        fileStruct.uniqueId = getUniqueId(fileStruct.shortName);
        % Validate the locationOnDisk, canonicalizing the path.
        % If the return value is is not a valid folder, return an empty 
        % struct. The toolbox will not be included with the doc.
        [locationOnDisk, isValidFolder] = getLocationOnDisk(fullfile(fileStruct.filepath), fileStruct.name);
        if isValidFolder
            fileStruct.locationOnDisk = locationOnDisk;
        else
            fileStruct = struct.empty;
            return;
        end
        % The examples landing page is always demos.xml.
        fileStruct.landingPage = "demos.xml";
    end    

    function validName = validateName
        % name is required to support doc and examples.
        validName = isfield(xmlFileStruct, 'name');
        if ~validName && isDebugProjectDoc
            % Escape any backslash characters in the folder path.
            file = strrep(file, '\', '\\');
            warning('MATLAB:projectDoc:displayProjectDoc:nameFieldNotFound', ...
                getString(message('MATLAB:projectDoc:displayProjectDoc:nameFieldNotFound', ...
                file)));
        end
    end

    function validHelpLocation = validateHelpLocation
        % help_location is required to support doc.
        validHelpLocation = isfield(xmlFileStruct, 'help_location');        
        if ~validHelpLocation && isDebugProjectDoc
            % Escape any backslash characters in the folder path.
            file = strrep(file, '\', '\\');
            warning('MATLAB:projectDoc:displayProjectDoc:helpLocationFieldNotFound', ...
                getString(message('MATLAB:projectDoc:displayProjectDoc:helpLocationFieldNotFound', ...
                file)));
        end
    end
end

function xmlFileStruct = readXmlFile(file)
    xmlFileStruct = struct.empty;
    try
        xmlFileStruct = readstruct(file);
    catch
        if isDebugProjectDoc
            % Escape any backslash characters in the folder path.
            file = strrep(file, '\', '\\');
            warning('MATLAB:projectDoc:displayProjectDoc:invalidXmlFile', ...
                getString(message('MATLAB:projectDoc:displayProjectDoc:invalidXmlFile', ...
                file)));
        end
    end    
end

function newStr = fixSlashes(str)
    % Replace forward slashes and back slashes with filesep.
    newStr = regexprep(str,'[/\\]',filesep);
end

function [locationOnDisk, isValidFolder] = getLocationOnDisk(folder, toolbox_name)
    [locationOnDisk, isValidFolder] = matlab.internal.doc.project.validateFolder(folder);
    if ~isValidFolder && isDebugProjectDoc
        % Escape any backslash characters in the folder path.
        folder = strrep(folder, '\', '\\');
        warning('MATLAB:projectDoc:displayProjectDoc:helpLocationNotFound', ...
            getString(message('MATLAB:projectDoc:displayProjectDoc:helpLocationNotFound', ...
            folder, toolbox_name)));
    end
end

function [landingPage, isValidFile] = getDocLandingPage(locationOnDisk, toolbox_name)
    isValidFile = false;
    landingPage = string.empty;
    helpTocXmlFile = fullfile(locationOnDisk, 'helptoc.xml');
    if isfile(helpTocXmlFile)
        helpTocXmlFileStruct = readstruct(helpTocXmlFile);
        landingPage = helpTocXmlFileStruct.tocitem.targetAttribute; 
        isValidFile = true;        
    else
        if isDebugProjectDoc
            % Escape any backslash characters in the file path.
            helpTocXmlFile = strrep(helpTocXmlFile, '\', '\\');
            warning('MATLAB:projectDoc:displayProjectDoc:helptocXmlFileNoFound', ...
                getString(message('MATLAB:projectDoc:displayProjectDoc:helptocXmlFileNoFound', ...
                helpTocXmlFile, toolbox_name)));
        end
    end
end

function [docFileStruct, docFilesStruct] = findDocFileForDemoFile(demoFile, docFilesStruct)
    docFileStruct = struct.empty;
    if isempty(docFilesStruct)
        return;
    end

    % Start at the folder containing the demos.xml file. Match the folder
    % against the folder for the info.xml files. Iterate backwards up the
    % tree until we find a match or iterate up to the root folder.
    % TODO: Can I short-circut this somehow, checking for relative paths
    % between the folders?
    [currentFolder,~,~] = fileparts(demoFile);
    lastCurrentFolder = '';
    while (~strcmp(currentFolder, lastCurrentFolder))
        lastCurrentFolder = currentFolder;
        match = strcmp({docFilesStruct.filepath},currentFolder);
        match = match';
        docFileStruct = docFilesStruct(match);
        if ~isempty(docFileStruct)
            % We found a match. Remove the matched item from the 
            % docFilesStruct struct array. Unmatched doc files will be used
            % later to create doc only toolboxes.
            noMatch = ~strcmp({docFilesStruct.filepath},currentFolder);
            noMatch = noMatch';
            docFilesStruct = docFilesStruct(noMatch);
            break;
        end
        [currentFolder,~,~] = fileparts(currentFolder);        
    end
end

function toolboxHelpLocations = getDocAndExampleToolboxHelpLocations(docFileStruct,demoFileStruct)
    toolboxHelpLocations = struct([]);
    docHelpLocation = getToolboxHelpLocation(docFileStruct,'doc');
    toolboxHelpLocations = cat(1,toolboxHelpLocations,docHelpLocation);
    % The shortName can be different for doc and examples. When the toolbox
    % has both, we use the doc shortName. It's used to build the
    % relativePath and helpLocation. Just overlay it here.
    demoFileStruct.shortName = docFileStruct.shortName;
    exampleHelpLocation = getToolboxHelpLocation(demoFileStruct,'examples');
    toolboxHelpLocations = cat(1,toolboxHelpLocations,exampleHelpLocation);
end

function toolboxHelpLocation = getToolboxHelpLocation(fileStruct,contentType)
    toolboxHelpLocation = struct;
    toolboxHelpLocation.contentType = contentType;
    toolboxHelpLocation.absolutePath = string(fileStruct.path);
    toolboxHelpLocation.locationOnDisk = fileStruct.locationOnDisk;
    relativePath = getRelativePath(fileStruct.shortName, contentType);       
    toolboxHelpLocation.helpLocation = join(relativePath(1:3),"/");  
    toolboxHelpLocation.landingPage = fileStruct.landingPage;
end

function toolboxName = getDocToolboxName(fileStruct, localized)
    if (isfield(fileStruct, 'type'))
        if strcmp(fileStruct.type,'toolbox')
            toolboxName = strcat(fileStruct.name, " ", getTypeToolbox(localized));
        elseif strcmp(fileStruct.type,'blockset')
            toolboxName = strcat(fileStruct.name, " ", getTypeBlockset(localized));
        else
            toolboxName = fileStruct.name;
        end 
    else
        toolboxName = fileStruct.name;
    end
end

function typeToolbox = getTypeToolbox(localized)
    if localized
        typeToolbox = getString(message('MATLAB:projectDoc:displayProjectDoc:toolbox'));
    else
        typeToolbox = "Toolbox";
    end
end

function typeBlockset = getTypeBlockset(localized)
    if localized
        typeBlockset = getString(message('MATLAB:projectDoc:displayProjectDoc:blockset'));
    else
        typeBlockset = "Blockset";
    end
end

function shortname = getShortname(toolboxName)
    shortname = lower(regexprep(toolboxName,'\W','_'));
end

function uniqueId = getUniqueId(shortname)
    uniqueId = strcat('3ptoolbox', '::', shortname);
end

function relativePath = getRelativePath(shortName, contentType)
    arguments
        shortName (1,1) string
        contentType string = string.empty
    end
    relativePath = ['3ptoolbox' string(strrep(shortName,'_',''))];
    if ~isempty(contentType)
        relativePath = [relativePath contentType];
    end
end

function validHelpLocations = validateHelpLocations(toolboxHelpLocations)
    for k=1:numel(toolboxHelpLocations)
        toolboxHelpLocation = toolboxHelpLocations(k);
        validHelpLocation = validateHelpLocation(toolboxHelpLocation);
        if ~validHelpLocation
            validHelpLocations = 0;
            return;
        end
    end
    validHelpLocations = 1;
end

function validHelpLocation = validateHelpLocation(toolboxHelpLocation)
    % The connector only supports alphanumeric 'routes'.
    helpLocation = toolboxHelpLocation.helpLocation;
    sanitizedString = replace(helpLocation, "/", "");
    if regexp(sanitizedString, '^[A-Za-z0-9]+$')
        validHelpLocation = 1;
    else 
        validHelpLocation = 0;
    end    
end

function debugProjectDoc = isDebugProjectDoc
    debugProjectDoc = matlab.internal.doc.project.isDebugProjectDoc;
end

% Copyright 2021-2022 The MathWorks, Inc.
