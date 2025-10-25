classdef Model < handle
    % Model: This class holds all the datastructrs reqired by the
    % MetadataApp and is the single source of truth for the entire
    % application

    % Copyright 2020-2023 The MathWorks, Inc.

	properties(Access = private)
        Directory                  % root-directory of the user-component,
        RegisteredComponentList    % list of registered component populated from the appDesigner.json
        Categories                 % all the categories present in appDesigner.json
        ComponentName              % name of the component provided to the constructor
        ComponentClassName         % fully qualified className for the component provided to the constructor
        ComponentMetadata          % struct hodling metadata the component provided to the constructor
        ComponentIndex             % component index in component array in appDesigner.json
        Metadata                   % Object representation of appDesigner.json
        PackagePrefix              % package prefix for the component provided to the constructor
        DirectoryWithPackages      % directory path which includes package-prefix
        SchemaUtils                % reference to schemaUtils class
        IsValid                    % boolean indicating validity of the appDesigner.json
    end
    
    methods(Access = public)
  
        function obj = Model(filePath)
            % Mode: This funtion parses the directory string and the
            % contents of the directory and builds all the datastructures
            % for the MetadataApp
            
            % instantiate SchemaUtil 
            obj.SchemaUtils = appdesigner.internal.usercomponent.metadata.SchemaUtils();
            
            % parse directory string
            obj.parseFilePath(filePath);                    
            
            % update all the data-structures based on the Directory
            % property
            obj.updateModel();
        end
        
        % Getter methods for Model class
        
        function directory = getDirectory(obj)
            directory = obj.Directory;
        end
        
        function componentMetadata = getComponentMetadata(obj)
            componentMetadata = obj.ComponentMetadata;
        end
        
        function categories = getCategories(obj)
            categories = obj.Categories;
        end
        
        function isValid = getModelValidity(obj)
            isValid = obj.IsValid;
        end
        
        % public APIs for Model class
        
        function updateComponent(obj, componentMetadata)
            % updateComponentMetadata: this funtion updates and serializes
            % metadata for a selected component.
            metadata = obj.Metadata;
            componentIndex = obj.ComponentIndex(componentMetadata.className);
            
            % merge currently available metadata with author-provided
            % metadata
            oldMetadata = metadata.components{componentIndex};
            metadata.components{componentIndex} = obj.mergeMetadata(oldMetadata, componentMetadata);
            
            % store updated metadata
            obj.Metadata = metadata;
            
            % serialize metadata
            obj.serializeMetadata();
        end
        
        function registerComponent(obj, componentMetadata)
            % registerComponent: this funtion registers and serializes
            % a new component's metadata
            import appdesigner.internal.usercomponent.metadata.Constants
            
            metadata = obj.Metadata;
            if isempty(fieldnames(metadata))
                metadata.components = {};
                metadata.schema = obj.SchemaUtils.getSchemaVersion();
                metadata.MATLABRelease = obj.SchemaUtils.getMATLABRelease();
            end
            
            % add new component's metadata to the existing metadata
            metadata.components{end+1} = componentMetadata;
            
            % store updated metadata
            obj.Metadata = metadata;
            
            % serialize metadata
            obj.serializeMetadata();
        end
        
        function deRegisterComponent(obj)
            % deRegisterComponent: this funtion de-registers a selected
            % component's metadata and serializes the remaining metadata
            
            metadata = obj.Metadata;
            % if provided component is not present in the appDesigner.json
            % then do nothing and return
            if ~isKey(obj.ComponentIndex, obj.ComponentClassName)
                return;
            end
            
            componentIndex = obj.ComponentIndex(obj.ComponentClassName);
            components = metadata.components;
            
            % remove selected component's metadata
            if length(components) == 1
                components = {};
            else
                components = transpose({metadata.components{1:end ~= componentIndex}});
            end
            metadata.components = components;
            
            % store updated metadata
            obj.Metadata = metadata;
            
            % serialize metadata
            obj.serializeMetadata();
        end
    end
    
    methods(Access = private)
        function parseFilePath(obj, filePath)
            % parseDirectoryPath: This funtion parses the directory string
            % to get the root of the package, if the directory string
            % contains MATLAB packages or a class folder
            [fullDirectoryPath, fileName, ~] = fileparts(filePath);
            packagePrefix = '';
            import appdesigner.internal.usercomponent.metadata.Constants
            
            directory = fullDirectoryPath;
            componentClassName = fileName;
            % extract root of the package or class folder
            if contains(directory, Constants.PackagePrefix)
                directory = strip(strtok(fullDirectoryPath, Constants.PackagePrefix), 'right', filesep);
                directoryPathPart = strsplit(fullDirectoryPath, Constants.PackagePrefix);
                directoryPathPart = strtok({directoryPathPart{2:end}}, filesep);
                packagePrefix = strjoin(directoryPathPart, Constants.PackageSeperator);
                componentClassName = [packagePrefix, Constants.PackageSeperator, fileName];
            elseif contains(directory, Constants.ClassFolderPrefix)
                directory = strip(strtok(fullDirectoryPath, Constants.ClassFolderPrefix), 'right', filesep);
            end
            
            % store root of the Package
            obj.Directory = directory;
            
            obj.ComponentName = fileName;
            obj.ComponentClassName = componentClassName;
            
            % store complete path to the directory
            obj.DirectoryWithPackages = fullDirectoryPath;
            
            % store the packagePrefix for the component classes
            obj.PackagePrefix = packagePrefix;
        end
        
        function updateModel(obj)
            % updateModel: this function parses the content of the
            % directory, contents of the appDesigner.json file and
            % cross-references them to genrate complete metadata for the
            % selected directory          
            
            % parse the appDesigner.json file if it exist
            [obj.IsValid, obj.Categories, obj.RegisteredComponentList, obj.Metadata] = obj.parseMetadataFile(obj.Directory);           
            
            % store indices of components as they appear under components key
            % in appDesigner.json for easy access
            obj.generateComponentIndex();
            
            % read metadata of the component if present in the
            % appDesigner.json
            obj.setComponentMetadata();
        end
        
        function generateComponentIndex(obj)
            % generateComponentIndex: this funtion extracts indices of components
            % as they appear under components key in appDesigner.json for easy access
            componentIndex = containers.Map();
            
            metadata = obj.Metadata;
            if isempty(fieldnames(metadata))
                return;
            end
            
            components = metadata.components;
            
            for index = 1:length(components)
                component = components{index};
                componentIndex(component.className) = index;
            end
            
            obj.ComponentIndex = componentIndex;
        end
        
        function serializeMetadata(obj)
            % serializeMetadata: this funtion serializes 'Metadata' property
            % of this class into appDesigner.json file
            import appdesigner.internal.usercomponent.metadata.Constants
            metadata = obj.Metadata;           
            
            % work-around so component key is always gets serializes as
            % an array by jsonencode API
            if isstruct(metadata.components)
                metadata.components =  {num2cell(metadata.components)};
            end
            
            % create resources directory if the directory doesn;t exist
            try
                if ~exist(fullfile(obj.Directory, Constants.MetadataDir), 'dir')
                    mkdir(fullfile(obj.Directory, Constants.MetadataDir))
                end
            catch me
                rethrow(me);
            end
            
            % write obj.Metadata to appDesigner.json file           
            metadataFilePath = fullfile(obj.Directory, Constants.MetadataDir, Constants.MetadataFile);
            fid = fopen(metadataFilePath, 'w');
            fprintf(fid, '%s', jsonencode(obj.Metadata, 'PrettyPrint', true));
            fclose(fid);
            
            % handle cache updation so that AppDesigner recives latest
            % version of the appDesigner.json file
            obj.updateCache();
                      
            
            % update model (ComponentIndex, ComponentMap) post serialization
            obj.updateModel();
        end
        
        function [isValid, categories, registeredComponents, metadata] = parseMetadataFile(obj, directory)
            % parseMetadataFile: this funtion parses the appDesigner.json
            % file and extracts metadata for registered components and all
            % the existing categories
            import appdesigner.internal.usercomponent.metadata.Constants
            categories = {};
            registeredComponents = {};
            isValid = true;
            metadata = struct;
            
            % read appDesigner.json if it exists
            metadataFilePath = fullfile(directory,Constants.MetadataDir, Constants.MetadataFile);
            me = [];
            if exist(metadataFilePath, 'file')
                try
                    metadata = obj.fixMetadataStructure(jsondecode(fileread(metadataFilePath)));
                    [isValid, metadata] = obj.SchemaUtils.validateMetadata(metadata);
                    if isValid
                        registeredComponents = metadata.components;
                    end
                catch me
                    isValid = false;
                end
            end
            
            % do not process metadata further if metadata validation fails
            if ~isempty(me)
                return;
            end
            
            % extract unique categories form the components present in the
            % appDesigner.json file
            categories = cellfun(@(component) component.category, registeredComponents, 'UniformOutput', false);
            categories = unique(string(categories),'rows');
        end
        
        function componentName = getRegisteredComponentName(obj, component)
            % this funtion extracts the componentName from component's
            % fully qualified className
            classNameParts = strsplit(component.className,'.');
            componentName = classNameParts{end};
        end
        
        function setComponentMetadata(obj)
            % generateCOmponentMap: this funtion cross-references
            % registered component and the contents of the selected
            % directory to genreate a map data-structure where complete
            % meatdata for a component is accessiable by the component-name
            import appdesigner.internal.usercomponent.metadata.Constants
          
            componentMetadata = struct(Constants.Status, Constants.NotRegistered, ...
                                       Constants.ClassName, obj.ComponentClassName,...
                                       Constants.ComponentName, obj.ComponentName);
            
            % parse contents of the appDesigner.json
            for registeredComponentIndex = 1:size(obj.RegisteredComponentList,1)
                registeredComponentMetadata = obj.RegisteredComponentList{registeredComponentIndex};
                if strcmp(registeredComponentMetadata.className, obj.ComponentClassName)
                    componentMetadata.status = Constants.Registered;
                    componentMetadata = obj.mergeMetadata(componentMetadata, registeredComponentMetadata);
                end
            end
            
            obj.ComponentMetadata = componentMetadata;
        end
        
        function fixedMetadata = fixMetadataStructure(obj, metadata)
            % fixMetadataStructure: this funtion fixes metadata structure
            % for uniform access to metadata throughout the code, in that
            % it converts value of components key to a cell-array if the
            % deserialized value for components key is a struct
            fixedMetadata = metadata;
            for categoryIndex = 1:length(fixedMetadata)
                components = fixedMetadata.components;
                if isstruct(components) || isnumeric(components)
                    fixedMetadata.components = num2cell(components);
                end
            end
        end
        
        function mergedMetadata = mergeMetadata(obj, oldMetadata, newMetadata)
            % mergeMetadata: this funtion merges the new-metadata with the
            % exisiting metadta so that an update operation does not remove
            % metadata that was not provided by the component-author in the
            % update
            
            mergedMetadata = oldMetadata;
            fields = fieldnames(newMetadata);
            for filedIndex = 1:length(fields)
                mergedMetadata.(fields{filedIndex}) = newMetadata.(fields{filedIndex});
            end
        end
        
        function updateCache(obj)
            % updateCache: this function keeps the cache up-to-date such
            % that App Designer detects every change made to the metadata
            % file
            import appdesigner.internal.usercomponent.metadata.Constants            

            % remove the metadata from cache
            matlab.internal.regfwk.unregisterResources(obj.Directory);

            % add latest metadata to cache
            if contains(path, obj.Directory)
                matlab.internal.regfwk.enableResources(obj.Directory);
            end
        end
    end
end
