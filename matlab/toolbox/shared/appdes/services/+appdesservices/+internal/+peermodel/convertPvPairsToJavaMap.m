function javaMap = convertPvPairsToJavaMap(pvPairs)
% Helper Method to convert a pvPair cell array into a javascript hash map.
%
% Inputs:
%
%   pvPairs     : cell array of {name, value, name, value} pairs to put
%                 into a hashMap
%
% Outputs:
%
%   javaMap     : a Java java.util.Map object where the keys are the names
%                 from pvPairs and the values are the values from pvPairs

% Copyright 2012-2016 The MathWorks, Inc.

% Error Checking
narginchk(1, 1);
validateattributes(pvPairs, ...
    {'cell'}, ...
    {});

assert( rem(length(pvPairs),2) == 0,...
    'Unbalanced pv pair array');

% Go through all the properties and convert to a Hash Map
javaMap = java.util.HashMap;

for idx = 1:2:length(pvPairs)
    % Explicitly convert all char names to Strings. This is needed for
    % single character property names like 'x', which are converted to Java
    % 'char' unless the conversion is explicit.
    
    name = java.lang.String(pvPairs{idx});
    propertyValue = pvPairs{idx+1};

    value = convertValue(propertyValue);
   
    javaMap.put(name, value);
end

end

function value = convertValue(propertyValue)

    try
        if(isnumeric(propertyValue) && ~any(any(isinf(propertyValue))) && ~any(any(isnan(propertyValue))) ...
                && ~isempty(propertyValue))
            % g1239822
            % Do not convert matlab double arrays to java double arrays.
            % GBT munit tests rely on the value being unchanged.
            
            % it will be converted automatically when put in the hash map
            % Convert to MATLAB double for conversion to JAVA
            %
            % This is being cast to a double because JAVA does not support
            % types like uint8 etc.
            %
            % Ideally this casting would not be present in
            % convertPvPairsToJavaMap, this should be here only for data
            % reshaping, not casting. g1553543 captures work to remove this
            % special handling of numeric values for both issues.
            value = double(propertyValue);
        else
            value = appdesservices.internal.peermodel.convertMatlabValueToJavaValue(propertyValue);
        end
    catch me
        % value can't be converted by the method, so keep the value as is,
        % it will be converted automatically when put in the hash map
        value = propertyValue;
    end
end