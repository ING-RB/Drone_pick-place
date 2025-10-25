classdef SchemaUtils < handle
    % SCHEMAUTILS This class holds utility funtions to validate and update
    % schema of appDesigner.json
    
    % Copyright 2020 The MathWorks, Inc.
    properties(Access = private)
        Schema   % object representation of the current schema
    end
    
    methods(Access = public)
        function obj = SchemaUtils()
            % SchemaUtils: this funtion constructs an SchemaUtils of this class
            % at instantiation time loda the latest schema
            obj.loadSchema();
        end
        
        function [isValid, metadata] = validateMetadata(obj, metadata)
            % validateMetadata: this function validates Metadata and
            % updates it if necessary
            import appdesigner.internal.usercomponent.metadata.Constants;
            isValid = false;
            
            % structural check at top level of nesting
            if ~isstruct(metadata) || ...
                    ~iscell(metadata.components)
                return;
            end
            
            % MATLABRelease update         
            metadata.MATLABRelease = obj.getMATLABRelease();
                  
            % schema update          
            metadata.schema = obj.getSchemaVersion();
     
            % schema version check
            metadata.components = obj.validateComponents(metadata.components);
            
            isValid = true;
        end
        
        function schemaVersion = getSchemaVersion(obj)
            % getSchemaVersion: this funtion returns the latest schema
            % version
            schemaVersion = obj.Schema.properties.schema.default;
        end
        
        function MATLABRelease = getMATLABRelease(obj)
            % getMATLABRelease: this funtion returns the MATLABRelease
            % being used to update or delete the components
            MATLABRelease = appdesigner.internal.serialization.util.ReleaseUtil.getCurrentRelease();
        end
    end
    
    methods(Access = private)
        function loadSchema(obj)
            % loadSchema: this function returns path to the
            % appDesignerSchema.json file
            import appdesigner.internal.usercomponent.metadata.Constants;
            dirPath = strjoin(Constants.UserComponentPackagePath, filesep);
            schemaPath = fullfile(matlabroot, dirPath, Constants.SchemaFileName);
            obj.Schema = jsondecode(fileread(schemaPath));
        end
        
        
        function components = validateComponents(obj, components)
            % validateComponents: this funtion iterates over the components
            % array to check if the component confoms to the schema, it
            % also adds the missing keys to component to make the component
            % conformant to the schema.
            
            % iterate over components, validate and fix when necessary
            for componentIndex = 1:length(components)
                component = components{componentIndex};
                
                % get the key difference for a given component
                keyDiff = setdiff(obj.Schema.properties.components.items.required, fieldnames(component));
                
                % add the missing keys to the component
                if ~isempty(keyDiff)
                    properties = obj.Schema.properties.components.items.properties;
                    for keyIndex = 1: length(keyDiff)
                        key = keyDiff{keyIndex};
                        component.(key) = properties.(key).default;
                    end
                    components{componentIndex} = component;
                end
            end
        end
    end
end

