classdef AppUtil
% Internal class for minor utility functions used by the matlab.apputil
% package.

% Copyright 2012 - 2019 The MathWorks, Inc.
    
    properties (Constant)
        % The current extension for MATLAB App install files
        FileExtension = '.mlappinstall';
        ProjectFileExtension = '.prj';
    end
    
    methods (Static)
        function appid = makeAppID(dirname)
        % Convert an app location into an APPID.
            appid = [dirname 'APP'];
        end
        
        function valid = validateProjectFile(projectFile)
            javaProjectFile = java.io.File(projectFile);
            result = com.mathworks.project.impl.model.ProjectManager.getTarget(javaProjectFile);
            valid = ~isempty(result);            
        end
        
        function fullFileName = locateFile(filename, extension)
            % Append the file extension if not specified.
            [~, ~, ext] = fileparts(filename);
            
            if ~strcmpi(ext, extension)
                filename = [filename extension];
            end
            
            [stat, info] = fileattrib(filename);
            
            fullFileName = [];
            
            if stat
                fullFileName = info.Name;
            end
        end
        
        function indices = findAppIDs(installedIDs, id, strict)
            validateattributes(installedIDs, {'cell'}, {'nonempty'});
            validateattributes(id, {'char'}, {'nonempty'});
            if strict
                indices = strcmp(id, installedIDs);
            else
                indices = strncmpi(id, installedIDs, length(id));
            end
        end
        
        function wrapperfilename = genwrapperfilename(appinstallfolder)
            % Get App install root folder name given the path to the code
            % folder
            [~, appdir, ~] = fileparts(appinstallfolder);
            wrapperfilename = genvarname(appdir);
        end
        
        function appinfo = getAllAppsInDefaultLocation()
            appinfo = matlab.internal.apputil.getAllAppInfo( ...
                char(com.mathworks.appmanagement.MlappinstallUtil.getAppInstallationFolder.getAbsolutePath)); 
        end
        
        % Special genpath function to get around the limitations expressed
        % in g1670067 regarding genpath's inability to generate path
        % entries for subfolders of a private folder
        function p = genpath(d)

            % String Adoption
            if nargin > 0
                d = convertStringsToChars(d);
            end

            if nargin==0
              p = matlab.internal.apputil.AppUtil.genpath(fullfile(matlabroot,'toolbox'));
              if length(p) > 1, p(end) = []; end % Remove trailing pathsep
              return
            end

            % initialise variables
            classsep = '@';  % qualifier for overloaded class directories
            packagesep = '+';  % qualifier for overloaded package directories
            p = '';           % path to be returned

            % Generate path based on given root directory
            files = dir(d);
            if isempty(files)
              return
            end

            % Add d to the path unless it is a private folder or a
            % resources folder
            [~, folderName, ~] = fileparts(d);
            if ~(strcmp(folderName,'private') || strcmp(folderName,'resources'))
                p = [p d pathsep];
            end

            % set logical vector for subdirectory entries in d
            isdir = logical(cat(1,files.isdir));
            %
            % Recursively descend through directories which are neither
            % private nor "class" directories.
            %
            dirs = files(isdir); % select only directory entries from the current listing

            for i=1:length(dirs)
               dirname = dirs(i).name;
               if    ~strcmp( dirname,'.')          && ...
                     ~strcmp( dirname,'..')         && ...
                     ~strncmp( dirname,classsep,1)  && ...
                     ~strncmp( dirname,packagesep,1)
                 
                 
                  p = [p matlab.internal.apputil.AppUtil.genpath(fullfile(d,dirname))]; %#ok<AGROW>
                 
               end
            end

            
        end
    end
    
end

