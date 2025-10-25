function jsonCompatibleStruct = convertStructToJSONCompatible(structData, ignoredTypes)
% Helper Method to convert a pvPair cell array to a struct with ensuring 
% each value be compatible for JSON.
%
% Inputs:
%
%   structData             : struct 
%
% Outputs:
%
%   jsonCompatibleStruct     : struct with each value be good for JSON

% Copyright 2019-2024 The MathWorks, Inc.

    % Error Checking
    narginchk(1, 2);
    validateattributes(structData, ...
        {'struct'}, ...
        {});

    if nargin < 2
        ignoredTypes = {};
    end

    % Go through all the properties and convert every value
    jsonCompatibleStruct = struct();

    propertyNames = fieldnames(structData);    
    for idx = 1:length(propertyNames)
        propertyName = propertyNames{idx};
        propertyValue = structData.(propertyName);

        % Convert the value to be ready for JSON encoder, for example, convert
        % Inf/-Inf to 'Inf'/'-Inf'; unsupported object/handle to [];
        % function handle to string
        jsonCompatibleStruct.(propertyName) = viewmodel.internal.convertMatlabToJSONCompatible(propertyValue, ignoredTypes);
    end
end
