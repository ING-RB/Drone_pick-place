function convertedMap = convertJavaMapToStruct(javaMap)
% Helper Method to convert a java Map into a struct
%
% Inputs:
%
%   javaMap         : a Java java.util.Map object
%
%
% Outputs:
%
%   convertedMap    : A struct that was created by converting all keys in
%                     the Java Map to fieldnames and all entries in the
%                     Java Map to the field values.

% Copyright 2012-2015 The MathWorks, Inc.

% Create a MATLAB-friendly struct out of the Java Map by going
% through every element in the map and putting it into a
% struct
convertedMap = struct;

keyNamesJavaArray = javaMap.keySet.toArray();

for idx = 1:javaMap.size()
    
    
    % Use key name to get value out
    %
    % Note: When looking up a value in a Java Map, must always use a Java String
    % not a MATLAB char.
    %
    % Multi character chars cast to java.lang.String, but single character
    % chars cast to Java char primitives. Using primitives to look up
    % entries in Java maps will not find any matches.
    stringPropertyName = java.lang.String(keyNamesJavaArray(idx));
    javaPropertyValue = javaMap.get(stringPropertyName);
    
    if isempty(javaPropertyValue)
        javaPropertyValue = javaMap.get(keyNamesJavaArray(idx));
    end
    
    % Get the new propertyValue for the javaMap
    propertyValue = appdesservices.internal.peermodel.convertJavaValueToMatlabValue(javaPropertyValue);
    
    % Stuff into struct
    propertyName = char(stringPropertyName);
    convertedMap.(propertyName) = propertyValue;
end

end