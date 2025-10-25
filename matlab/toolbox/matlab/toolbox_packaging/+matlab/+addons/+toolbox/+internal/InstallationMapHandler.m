classdef InstallationMapHandler
    %INSTALLATIONMAPHANDLER Utility functions for reading and writing
    %'getInstallationLocation' function files
    
    methods(Static)
        
        function map = getExistingMap(location)
            %apparently we have to do this to get mlx contents
            fileContents = evalc(['type(''' location ''')']);
            fmtree = mtree(fileContents);
            charNodes = fmtree.mtfind('Kind','CHARVECTOR');
            ids = charNodes.first.strings;
            values = charNodes.first.Next.strings;
            
            interleaves = [ids ,values];
            idx = reshape(1:numel(interleaves),[],2)';
            map = interleaves(:,idx(1:end));
            
            %get rid of the extra quotes
            map = cellfun(@(x) x(2:end-1), map, 'un', 0);
        end
        
        
        function [relativePathToMapFile] = generateInstallationMap(toolboxRoot, pathToFunction, showDocumentation, varargin)
            
            numberOfParams = numel(varargin);
            
            %varargin can contain one or two arrays
            %if it has java types, conver to cell
            swIDs = cell(varargin{1});
            
            %additionalSWLocations may have been passed in, if not we should generate some text
            if(numberOfParams == 2)
                swPaths = cell(varargin{2});
            else
                createAdditionalSoftwareLocation = @(x) ['<replace with installed location of "' x '" on your computer>'];
                swPaths = cellfun(createAdditionalSoftwareLocation, swIDs, 'UniformOutput', 0 );
            end
            
            if(~exist(toolboxRoot,'dir'))
                error(['The folder "' toolboxRoot '" does not exist'])
            end
            
            %if path to function is non empty, use that
            %otherwise, generate name based on toolbox root
            [packagePath, packageName, packageBaseName, functionName, functionBaseName, installationMapFilePath ] = ...
                matlab.addons.toolbox.internal.InstallationMapHandler.getInstallMapLocation(toolboxRoot, pathToFunction);
            
            if ~exist(packagePath, 'dir')
                % Folder does not exist so create it.
                mkdir(packagePath);
            end
            
            tempMapFileLocation = tempname;
            
            %get the contents of the file
            installMapFileContents = matlab.addons.toolbox.internal.InstallationMapHandler.getInstallMapContents(...
                showDocumentation, packageBaseName, functionBaseName, swIDs, swPaths);
            
            fid = fopen(tempMapFileLocation, 'wt', 'n', 'UTF-8'); %and use 't' with text files so eol are properly translated
            
            fprintf(fid, installMapFileContents);
            
            %convert to key-value Map
            fclose(fid);
            %edit(installationMapFilePath);
            
            opcPackage = com.mathworks.publishparser.PublishParser.convertMToRichScript(java.io.File(tempMapFileLocation));
            com.mathworks.services.mlx.MlxFileUtils.write(java.io.File(installationMapFilePath), opcPackage);
            
            %delete temp file
            delete(tempMapFileLocation);
            
            relativePathToMapFile = fullfile(packageName, functionName);
        end
        
          
        function [packagePath, packageName, packageBaseName, functionName, functionBaseName, installationMapFilePath ] = getInstallMapLocation(toolboxRoot, pathToFunction)       
            [~,name,~] = fileparts(toolboxRoot); %need to remove a '+' prefix if one already exists
            
            if isempty(pathToFunction)
                packageBaseName = matlab.lang.makeValidName(name,'prefix','tbx_');
                packageName = [ '+' packageBaseName];
                
                functionBaseName = 'getInstallationLocation';
                functionName = [functionBaseName '.mlx'];
            else
                [packageName, functionBaseName, ext] = fileparts(pathToFunction);
                packageBaseName = packageName(2:end); %removes the expected "+"
                functionName = [functionBaseName ext];
            end
                packagePath = fullfile(toolboxRoot, packageName);
                installationMapFilePath = fullfile(packagePath, functionName);
            
        end
        
        function installMapFileContents = getInstallMapContents(showDocumentation, packageBaseName, functionBaseName, swIDs, swPaths)
            header = '';
            
            %Don't show documentation unless specified true. End user does
            %not beed these directions.
            if showDocumentation
                header = matlab.addons.toolbox.internal.InstallationMapHandler.getInstallMapHeader(packageBaseName, functionBaseName);
            end
            
            numberOfAdditionalSWEntries = numel(swIDs);
            
            %all the lines of software ID and location
            installationMapLines = arrayfun(@(x) ...
                matlab.addons.toolbox.internal.InstallationMapHandler.createAdditionalSoftwareRow( x,swIDs,swPaths), ...
                1:numberOfAdditionalSWEntries, 'UniformOutput', 0 );
            
            installationMapLinesFormatted =  strjoin([installationMapLines{:}], ';\n');
            
            installMapFileContents = [...
                header ...
                'function installedLocation = ' functionBaseName '(requiredSoftwareID)\n' ...
                '    installationLocations = { ...\n' ...
                '\n' ...
                '      %%     Software ID             Installation Location\n' ...
                '      %% --------------------    -----------------------------\n' ...
                '\n' ...
                '      %% ''ExampleSoftware'',         ''C:/Documents/ExampleSoftware'',\n' ...
                installationMapLinesFormatted '\n'...
                '    };' ...
                '\n' ...
                '    %% convert to key-value Map\n' ...
                '    installationMap = containers.Map(installationLocations(:,1), installationLocations(:,2));\n' ...
                '    installedLocation = installationMap(requiredSoftwareID);\n' ...
                'end' ...
                ];
            
            
            
        end
        
        function installMapHeader = getInstallMapHeader(packageBaseName, functionBaseName)
            qualifiedFunctionName = [packageBaseName '.' functionBaseName];
            
            installMapHeader =  [ ...
                '%%%% Additional Software Installation Locations\n' ...
                '%% \n' ...
                '%% If your toolbox code refers to installed locations of Additional Software, make it portable to other computers.\n' ...
                '%% \n' ...
                '%% # In the ' functionBaseName ' function below, for each *Software ID*, change the *Installation Location* to point to the correct location on your computer.\n' ...
                '%% # In your toolbox code, replace references to the installation location with calls to ' qualifiedFunctionName ' with the associated Software ID. For example, |installedLocationOfExampleSoftware = ' qualifiedFunctionName '(''ExampleSoftware'');|\n' ...
                '%% \n' ...
                '%% When a user installs your toolbox, MATLAB downloads and installs the Additional Software. Then it replaces the *Installation Locations* in this function with the correct locations on the user''s computer.\n' ...
                ];
        end
        
        
        function row = createAdditionalSoftwareRow(index, swIDs, swLocations)
            spacing = {repmat(' ',1,24-numel(swIDs{index}))};
            tabsForColumns = '\t';
            
            swID = swIDs(index);
            swID = matlab.addons.toolbox.internal.InstallationMapHandler.cleanStringForPrint(swID);
            
            swLocation = swLocations(index);
            %need this to be writable
            
            if isempty(swLocation{1})
                swLocation = strcat('<replace with installed location of "', swID, '" on your computer>');
            else
                swLocation = matlab.addons.toolbox.internal.InstallationMapHandler.cleanStringForPrint(swLocation{1});
            end
            
            row = strcat(tabsForColumns,'''',swID,''',', spacing ,'''',swLocation,'''');
        end
        
        %user entered data will need to be cleaned for printing to a file
        function cleanedString = cleanStringForPrint(stringToClean)
                cleanedString = regexprep( stringToClean, '%', '%%' );
                cleanedString = regexprep( cleanedString, '''', '''''' );
                cleanedString = regexprep( cleanedString, '\\', '\\\\' );
        end
        
    end
end

