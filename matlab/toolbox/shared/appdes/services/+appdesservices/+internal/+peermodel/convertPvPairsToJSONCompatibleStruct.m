function jsonCompatibleStruct = convertPvPairsToJSONCompatibleStruct(pvPairs, ignoredTypes)
% Helper Method to convert a pvPair cell array to a struct with ensuring 
% each value be compatible for JSON.
%
% Inputs:
%
%   pvPairs             : cell array of {name, value, name, value} pairs 
%
% Outputs:
%
%   jsonCompatibleStruct     : struct with each value be good for JSON

% Copyright 2017-2024 The MathWorks, Inc.

    % Error Checking
    narginchk(1, 2);
    validateattributes(pvPairs, ...
        {'cell'}, ...
        {});

    assert( rem(length(pvPairs),2) == 0,...
        'Unbalanced pv pair array');

    if nargin < 2
        ignoredTypes = {};
    end

    % Go through all the properties and convert every value
    jsonCompatibleStruct = struct();

    for idx = 1:2:length(pvPairs)
        propertyName = pvPairs{idx};
        propertyValue = pvPairs{idx+1};

        % Convert the value to be ready for JSON encoder, for example, convert
        % Inf/-Inf to 'Inf'/'-Inf'; unsupported object/handle to [];
        % function handle to string
        jsonCompatibleStruct.(propertyName) = viewmodel.internal.convertMatlabToJSONCompatible(propertyValue, ignoredTypes);
    end
end
