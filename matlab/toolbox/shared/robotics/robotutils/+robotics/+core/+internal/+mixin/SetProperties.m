classdef SetProperties < handle
    %This class is for internal use only. It may be removed in the future.

    %SetProperties  Mixin class that provides a setProperties method
    %   This allows setting public properties with name-value pairs (as in
    %   System objects). The setProperties method also allows setting
    %   properties with value-only arguments, using the same syntax as
    %   matlab.System.setProperties. For this class, however, any
    %   value-only arguments are required arguments.
    %
    %   Example:
    %
    %       Class definition:
    %
    %       classdef toyClass < robotics.core.internal.mixin.SetProperties
    %           %#codegen
    %
    %           properties
    %               ValueOnlyProp = 0
    %               NameValueProp1 = 'foo'
    %               NameValueProp2 = 'bar'
    %           end
    %
    %           properties (Access = protected)
    %               ConstructorProperties = {'NameValueProp1', ...
    %                                        'NameValueProp2'};
    %           end
    %
    %           methods
    %
    %               function obj = toyClass(varargin)
    %                   %toyClass(valueOnlyProp, Name, Value, ...)
    %                   obj.setProperties(nargin, varargin{:}, 'ValueOnlyProp');
    %               end
    %
    %           end
    %       end
    %
    %
    %       Usage:
    %
    %       >> a = toyClass(5)
    %
    %       a = 
    %
    %         toyClass with properties:
    %
    %            ValueOnlyProp: 5
    %           NameValueProp1: 'foo'
    %           NameValueProp2: 'bar'
    %
    %       >> a = toyClass(5, 'NameValueProp2', 'asdf')
    %
    %       a = 
    %
    %         toyClass with properties:
    %
    %            ValueOnlyProp: 5
    %           NameValueProp1: 'foo'
    %           NameValueProp2: 'asdf'
    %
    
    %   Copyright 2016-2019 The MathWorks, Inc.
    
    %#codegen
    
    properties (Abstract, Access = protected)
        
        %ConstructorProperties Cell array of property names (as char vectors)
        %   The properties can be set via name-value pairs in the constructor.
        %   Each child class must implement this property
        ConstructorProperties
        
        %ConstructorPropertyDefaultValues Cell array of default property values.
        %   This property is required for codegen purpose, as accessing
        %   a class property for the first time locks the property
        %   size. All user-facing (constructor) property default values
        %   should be provided in this property, following the order in 
        %   ConstructorProperties. Each child class must implement this 
        %   property
        ConstructorPropertyDefaultValues
        
    end
    
    methods (Access = {?robotics.core.internal.mixin.SetProperties, ...
                       ?matlab.unittest.TestCase})
        
        function setProperties(obj, numargs, varargin)
            %setProperties Set object properties via name-value pairs
            %
            %   setProperties(obj,numargs,name1,value1,name2,value2,...)
            %   provides the name-value pair inputs to object constructor.
            %   Use this syntax if every input must specify both name and
            %   value.
            %
            %   setProperties(obj,numargs,arg1,...,argN,propvalname1,...propvalnameN)provides
            %   the value-only inputs, which you can follow with the
            %   name-value pair inputs to the object during object
            %   construction. Use this syntax if you want to allow users to
            %   specify one or more inputs by their values only.
            
            % Set value-only properties
            nameIndices = numargs+1:numel(varargin);
            valueIndices = 1:numel(nameIndices);
            for i = 1:numel(nameIndices)
                obj.(varargin{nameIndices(i)}) = varargin{valueIndices(i)};
            end
            
            % Get default values for name-value pairs
            defaultValues = cell(1, numel(obj.ConstructorProperties));
            for i = 1:numel(obj.ConstructorProperties)
                defaultValues{i} = obj.ConstructorPropertyDefaultValues{i};
            end
            
            % Set name-value pair properties
            parser = robotics.core.internal.NameValueParser(obj.ConstructorProperties, defaultValues);
            parser.parse(varargin{numel(nameIndices)+1:numargs});
            for i = coder.unroll(1:numel(obj.ConstructorProperties))
                obj.(obj.ConstructorProperties{i}) = parser.parameterValue(obj.ConstructorProperties{i});
            end
        end
        
    end
    
    methods(Static, Hidden)
        
        function props = matlabCodegenNontunableProperties(~)
            % Let the coder know about non-tunable parameters
            props = {'ConstructorProperties'};
        end
        
    end 
    
end
