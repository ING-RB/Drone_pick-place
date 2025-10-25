classdef FilePathDocPageParser < matlab.internal.doc.url.DocPageParser
    methods
        function obj = FilePathDocPageParser(filePath)
            obj.Input = filePath;
            spkgRoot = string(matlab.internal.doc.services.getSupportPackageDocRoot);
            folders = [string(docroot), spkgRoot];
            numMwFolders = length(folders);

            customToolboxRoots = matlab.internal.doc.project.getCustomToolboxDocRoots;
            folders = [folders, customToolboxRoots];
            fileLocation = matlab.internal.web.FileLocation(filePath);
            
            for i = 1:length(folders)
                folder = folders(i);
                folderLocation = matlab.internal.web.FileLocation(folder);
                relUri = fileLocation.getRelativeUriFrom(folderLocation);
                if ~isempty(relUri)
                    obj.Location = matlab.internal.doc.services.DocLocation.INSTALLED;
                    obj.RelUri = relUri;
                    obj.IsDocPage = true;
                    % If we're under a custom toolbox folder, add an altDocroot 
                    % item to the struct for use later.
                    if i > numMwFolders
                        % Under a custom toolbox 'alternate' doc root
                        obj.AlternateDocRoot = folderLocation;
                    end                    
                    return;
                end                
            end
        end
    end
end
