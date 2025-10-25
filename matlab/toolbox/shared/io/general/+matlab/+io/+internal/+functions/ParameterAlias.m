classdef ParameterAlias
%A parameter NV pair alias

% Copyright 2020 MathWorks, Inc.
        
    properties
        CanonicalName(1,1) string = "";
        AlternateNames(1,:) string  = "";
    end
    
    methods
        function obj = ParameterAlias(CanonicalName,AlternateNames)
            [CanonicalName,AlternateNames] = convertCharsToStrings(CanonicalName,AlternateNames);
            obj.CanonicalName = CanonicalName;
            obj.AlternateNames = AlternateNames;
        end
        
        function name = getCanonicalName(aliases,name)
            % If a parameter has an alias, replace it with the correct name
            % If two interfaces define the same alias value, only the first one
            % will be used.
            % Aliases are case insensitive, but not partial matched.
            for kk = 1:numel(aliases)
                if any(strcmpi(name,aliases(kk).AlternateNames))
                    name = aliases(kk).CanonicalName;
                    return
                end
            end
        end
    end
end

