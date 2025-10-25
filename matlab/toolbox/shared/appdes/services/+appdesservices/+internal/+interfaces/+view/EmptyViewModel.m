classdef EmptyViewModel < handle
    %EMPTYVIEWMODEL A place holder object for ViewModel
    %   Provide APIs to avoid calling into empty ViewModel object in some scenarios
    % 
    
    % Copyright 2023 - 2024 MathWorks, Inc.

    properties(Constant)
        % Singleton instance of the class
        Instance = appdesservices.internal.interfaces.view.EmptyViewModel;
    end
    
    properties
        Id = "";
    end

    methods (Access = private)
        function obj = EmptyViewModel()
            
        end
    end

    methods
        
        function tf = isempty(obj)
            % When consumers check if this is an empty object, return true
            % like no ViewModel has been created.
            tf = true;
        end

        function l = addlistener(obj, eventName, callbackFcn)
            l = [];
        end

        function id = getId(obj)
            id = obj.Id;
        end

        function childNode = addChild(obj, type, varargin)
            childNode = obj.Instance;
        end

        function childNode = addChildWithJSONValues(obj, type, properties, varargin)
            childNode = obj.Instance;
        end

        function setProperties(obj, properties, varargin)
            % no-op
            %error("should not call into here");
        end

        function setPropertiesWithJSONValue(obj, properties, varargin)
            % no-op
        end

        function tr = hasProperty(obj, propertyName)
            tf = false;
        end

        function value = getProperty(obj, propertyName)
           value = [];
        end
        
        function propertyStruct = getProperties(obj)
           propertyStruct = struct.empty();
        end
        
        function dispatchEvent(obj, eventName, data, varargin)        
            % no-op
        end
        
        function children = getChildren(obj)
            children = [];
        end
        
        function componentIndex = getChildIndex(obj, varargin)
            componentIndex = -1;
        end

        function destroy(obj)
            % no-op
        end

        function attach(obj, ~)
            % no-op
        end
    end
end

