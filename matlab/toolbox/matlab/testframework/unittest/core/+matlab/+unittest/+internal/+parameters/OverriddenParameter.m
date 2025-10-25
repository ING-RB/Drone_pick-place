classdef (Hidden) OverriddenParameter
    %

    % Copyright 2016-2018 The MathWorks, Inc.
    
    properties(SetAccess=immutable)
        Value;
        Name;
    end
    properties(Dependent, SetAccess = private)
        Property;
    end
    
    methods
        function obj = OverriddenParameter(name, value)
            obj.Name = name;
            if ~iscell(value)
                obj.Value = num2cell(value);
            else
                obj.Value = value;
            end
        end
        
        function name = get.Property(param)
            name = param.Name;
        end
        
        function params = convert(overriddenParam, paramConstructor)            
            params = arrayfun(@(o)create(o,paramConstructor), ...
                    overriddenParam, 'UniformOutput', false);
            params = [params{:}];            
        end
    end
end

function params = create(overriddenParam,paramConstructor)
    import matlab.unittest.internal.parameters.getParameterNames;
    names = getParameterNames(overriddenParam.Value);
    params = cellfun(@(x, y)paramConstructor(overriddenParam.Name, x, y), ...
        names, overriddenParam.Value, 'UniformOutput', false);
    params = [params{:}];
end