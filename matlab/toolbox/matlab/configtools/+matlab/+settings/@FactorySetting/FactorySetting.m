classdef FactorySetting < handle
    %FactorySetting Factory settings object.
    %   A FactorySetting object represents an individual setting within the
    %   factory settings hierarchical tree.
    %
    %   Create a root FactoryGroup object, use the 
    %   matlab.settings.createToolboxGroup function. For example:
    %
    %   myToolboxSettings = matlab.settings.FactoryGroup.createToolboxGroup(...
    %      'mytoolbox','Hidden',false);
    %
    %   Then, create FactorySetting objects within the FactoryGroup root object 
    %   using the addSetting function. For example:
    %
    %   myFactorySetting = addSetting(...
    %      myToolboxSettings,'MySetting','Hidden',false,'FactoryValue',10);
    %
    %   See also MATLAB.SETTINGS.FACTORYGROUP, 
    %   MATLAB.SETTINGS.FACTORYGROUP.CREATETOOLBOXGROUP.
    
    %   Copyright 2018-2019 The MathWorks, Inc.
    
    properties (GetAccess = public, SetAccess = immutable)
        Name string
        FactoryValue 
        FactoryValueFcn 
        ValidationFcn 
        Hidden(1,1) logical
        ReadOnly(1,1) logical
    end
    
    properties (Access = private)
        Parent matlab.settings.FactoryGroup
        ValueValidator
    end
    
    methods (Access = {?matlab.settings.FactoryGroup})
        
        function obj = FactorySetting(name, parent, varargin)
            % FactorySetting class constructor.  Not directly accessible.
            
            matlab.settings.internal.isValidName(name, 'FactorySetting');
            matlab.settings.internal.isValidParent(parent);
            
            persistent factorySettingParser;
            
            if (isempty(factorySettingParser))
                factorySettingParser = inputParser;
                
                % Factory value, or, alternatively, a factory value 
                % function.  Those can be both missing, or one of them
                % present, but not both simultaneously.
                factorySettingParser.addParameter(...
                    'FactoryValue', matlab.settings.FactorySetting.empty);
                factorySettingParser.addParameter(...
                    'FactoryValueFcn', function_handle.empty, ...
                    @matlab.settings.internal.isValidFunctionHandle); 
                
                % Optional Property-Value pairs 
                factorySettingParser.addParameter(...
                    'ValidationFcn', function_handle.empty, ...
                    @matlab.settings.internal.isValidFunctionHandle);
                factorySettingParser.addParameter('Hidden', true, ...
                    @(v)(matlab.settings.internal.isValidInputForLogical(...
                        v, 'Hidden')));
                factorySettingParser.addParameter('ReadOnly', false, ...
                    @(v)(matlab.settings.internal.isValidInputForLogical(...
                        v, 'ReadOnly')));
            end
            
            factorySettingParser.parse(varargin{:})
            results  = factorySettingParser.Results;
            
            % Check that FactoryValue and FactoryValueFcn are not specified
            % simultaneously.
            if (~isempty(results.FactoryValue) && ...
                ~isempty(results.FactoryValueFcn))
                error(message(...
                    'MATLAB:settings:config:FactoryValueSpecifiedTwice', ... 
                    name));
            end
     
            obj.Name = name;
            obj.Parent = parent;
            obj.FactoryValue = results.FactoryValue;
            obj.FactoryValueFcn = results.FactoryValueFcn;  
            obj.Hidden = logical(results.Hidden);
            obj.ReadOnly = logical(results.ReadOnly);
            obj.ValidationFcn = results.ValidationFcn;
        end
        
    end

end

