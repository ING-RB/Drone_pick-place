classdef ParameterAttribute < matlab.unittest.internal.selectors.SelectionAttribute
    % ParameterAttribute - Attribute for TestSuite element parameters.
    
    % Copyright 2013-2022 The MathWorks, Inc.
    
    methods
        function attribute = ParameterAttribute(data)
            arguments
                data (1, :) cell
            end
            attribute@matlab.unittest.internal.selectors.SelectionAttribute(data);
        end

        function result = acceptsParameter(attribute, selector)
            paramSets = attribute.Data;
            result = true(1, numel(paramSets));
            for setIdx = 1:numel(paramSets)
                result(setIdx) = evaluateParameters(selector, paramSets{setIdx});
            end
        end
    end
end

function result = evaluateParameters(selector, params)
result = false;
for parameter = params
    if selector.PropertyConstraint.satisfiedBy(parameter.Property) && ...
            matchParameterNameBool(selector.NameConstraint,parameter) && ...
            selector.ValueConstraint.satisfiedBy(parameter.Value)
        result = true;
        break;
    end
end
end

function bool =  matchParameterNameBool(nameConstraint,parameter)
matchesLegacyName = nameConstraint.satisfiedBy(parameter.LegacyName);
matchesName = nameConstraint.satisfiedBy(parameter.Name);

if(~matchesName && matchesLegacyName)
    warning(message('MATLAB:unittest:Parameter:MatchingUsingLegacyNames',parameter.LegacyName, parameter.Property, parameter.Name));
end

bool = matchesName||matchesLegacyName;
end