classdef FactoryGroup < handle
    %FactoryGroup Group of factory settings and factory subgroup objects.
    %   A FactoryGroup is an object within the factory settings hierarchical 
    %   tree. At the top of the tree is the root FactoryGroup of the toolbox. 
    %   Each FactoryGroup can contain a collection of other FactoryGroup and 
    %   FactorySetting objects.
    %
    %   To create a root FactoryGroup object, use the 
    %   matlab.settings.createToolboxGroup function. For example:
    %
    %   myToolboxSettings = matlab.settings.FactoryGroup.createToolboxGroup(...
    %      'mytoolbox','Hidden',false);
    %
    %   See also MATLAB.SETTINGS.FACTORYSETTING, 
    %   MATLAB.SETTINGS.FACTORYGROUP.CREATETOOLBOXGROUP.
    %
    
    %   Copyright 2018-2022 The MathWorks, Inc.

    
    properties (GetAccess = public, SetAccess = immutable)
        Name string
        ValidationFcn
        Hidden(1,1) logical
    end
    
    properties (Access = private)
        Parent matlab.settings.FactoryGroup
        Groups matlab.settings.FactoryGroup
        Settings matlab.settings.FactorySetting
        AdditionalFile(1,1) logical = false
        IsToolboxGroup(1,1) logical = false
    end
    
    methods (Access = {?matlab.settings.FactoryGroup})
        
        function obj = FactoryGroup(name, parent, varargin)
            % FactoryGroup class constructor.  Not directly accessible.
            
            matlab.settings.internal.isValidName(name, 'FactoryGroup');
            matlab.settings.internal.isValidParent(parent);
            
            persistent factoryGroupParser;
            
            if (isempty(factoryGroupParser))
                factoryGroupParser = inputParser;
                
                factoryGroupParser.addParameter('Hidden', true, ...
                    @(v)(matlab.settings.internal.isValidInputForLogical(...
                        v, 'Hidden')));
                
                factoryGroupParser.addParameter('AdditionalFile', false, ...
                    @(v)(matlab.settings.internal.isValidInputForLogical(...
                        v, 'AdditionalFile')));
                
                factoryGroupParser.addParameter('HasAdditionalSettings', false, ...
                    @(v)(matlab.settings.internal.isValidInputForLogical(...
                        v, 'HasAdditionalSettings')));
                
                factoryGroupParser.addParameter(...
                    'ValidationFcn', function_handle.empty, ...
                    @matlab.settings.internal.isValidFunctionHandle);
            end

            factoryGroupParser.parse(varargin{:});
            results  = factoryGroupParser.Results; 
            
            obj.Name = name;
            obj.Parent = parent;
            obj.Hidden = logical(results.Hidden);
            obj.ValidationFcn = results.ValidationFcn;
            obj.AdditionalFile = results.AdditionalFile;
            obj.IsToolboxGroup = results.HasAdditionalSettings;
        end
        
    end
        
    methods (Access = public)
        
        function grp = addGroup(obj, name, varargin)
            % addGroup Add new factory settings group to an existing factory settings group. 
            %   addGroup(PARENTGROUP,NAME) adds the factory group NAME to the 
            %   specified parent factory settings group PARENTGROUP and returns 
            %   the new group as a FACTORYGROUP object.
            %
            %   PARENTGROUP and NAME can be followed by parameter/value pairs 
            %   to specify additional properties of the group. For instance, 
            %   'Hidden',false adds a group that is visible in the factory 
            %   settings tree.
            %   
            %   Example:
            %      Create a toolbox root factory settings group: 
            %         myToolboxFactoryTree = ...
            %            matlab.settings.FactoryGroup.createToolboxGroup(...
            %               'mytoolbox','Hidden',false);
            %      Add a new factory settings group to the toolbox root:
            %         toolboxFontGroup = myToolboxFactoryTree.addGroup(...
            %            'font','Hidden',false);
            %
            %   See also MATLAB.SETTINGS.FACTORYGROUP.ADDSETTING, 
            %   MATLAB.SETTINGS.CREATETOOLBOXGROUP.
    
            obj.checkIfNameExists(name);
            
            grp = matlab.settings.FactoryGroup(name, obj, varargin{:});

            obj.Groups(end + 1) = grp;
        end      
        
        function setting = addSetting(obj, name, varargin)
            % addSetting Add new factory setting to an existing group.
            %   addSetting(PARENTGROUP,NAME) adds the factory setting NAME to 
            %   the specified parent factory settings group PARENTGROUP and 
            %   returns the new setting as a FACTORYSETTING object.
            %
            %   PARENTGROUP and NAME can be followed by parameter/value pairs 
            %   to specify additional properties of the setting. For instance, 
            %   'Hidden',false adds a setting that is visible in the factory 
            %   settings tree.
            %   
            %   Example:
            %      Create a toolbox root factory settings group:
            %         myToolboxFactoryTree = ...
            %            matlab.settings.FactoryGroup.createToolboxGroup(...
            %               'mytoolbox','Hidden',false);
            %      Add a new factory setting to the toolbox root.
            %         fontSizeSetting = myToolboxFactoryTree.addSetting(...
            %            'FontSize','FactoryValue',11,'Hidden',false);
            %
            %   See also MATLAB.SETTINGS.FACTORYGROUP.ADDGROUP, 
            %   MATLAB.SETTINGS.FACTORYGROUP.CREATETOOLBOXGROUP.
            
            obj.checkIfNameExists(name);
            
            setting = matlab.settings.FactorySetting(...
                name, obj, varargin{:});
            
            obj.Settings(end + 1) = setting;
        end
       
    end
    
    methods (Access = private)
        
        function checkIfNameExists(obj, name)
            % Check if there already exist a sub-group/setting with 'name'.
            
            for i = 1 : length(obj.Groups)
                if isequal(obj.Groups(i).Name, name)
                    error(message(...
                        'MATLAB:settings:config:FactoryGroupAlreadyExists', ... 
                        name));
                end
            end 
            
            for i = 1 : length(obj.Settings)
                if isequal(obj.Settings(i).Name, name)
                    error(message(...
                        'MATLAB:settings:config:FactorySettingAlreadyExists', ... 
                        name));
                end
            end 
        end
        
    end
    
    methods (Static)
        
        function toolboxGroup = createToolboxGroup(name, varargin)
            % createToolboxGroup Create FactoryGroup root object for toolbox.
            %   createToolboxGroup(NAME) creates the root factory group for 
            %   a toolbox and returns the new factory group as a FactoryGroup 
            %   object.
            %
            %   NAME can be followed by parameter/value pairs to specify 
            %   additional properties of the root factory group. For instance, 
            %   'Hidden',false create a visible root FactoryGroup object.
            %   
            %   Example:
            %      Create a toolbox root factory settings group.
            %         myToolboxFactoryTree = ...
            %            matlab.settings.FactoryGroup.createToolboxGroup(...
            %               'mytoolbox','Hidden',false);
            %
            %   See also MATLAB.SETTINGS.FACTORYGROUP.ADDGROUP, 
            %   MATLAB.SETTINGS.FACTORYGROUP.ADDSETTING.

            if (nargin == 0)
                error(message(...
                    'MATLAB:settings:config:FactoryGroupNameNotSpecified'));
            end
            
            toolboxGroup = matlab.settings.FactoryGroup(...
                name, matlab.settings.FactoryGroup.empty(), varargin{:});
            toolboxGroup.IsToolboxGroup = true;
        end
        
    end
end



