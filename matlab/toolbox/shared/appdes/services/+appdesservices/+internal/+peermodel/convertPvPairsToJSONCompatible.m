function jsonCompatiblePVPairs = convertPvPairsToJSONCompatible(pvPairs, ignoredTypes)
% Helper Method to convert a pvPair cell array to ensure each value be 
% compatible for JSON.
%
% Inputs:
%
%   pvPairs             : cell array of {name, value, name, value} pairs 
%
% Outputs:
%
%   jsonCompatiblePVPairs     : cell array with each value be good for JSON

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
    jsonCompatiblePVPairs = pvPairs;

    for idx = 1:2:length(jsonCompatiblePVPairs)
        propertyValue = jsonCompatiblePVPairs{idx+1};

        % Convert the value to be ready for JSON encoder, for example, convert
        % Inf/-Inf to 'Inf'/'-Inf'; unsupported object/handle to [];
        % function handle to string
        value = viewmodel.internal.convertMatlabToJSONCompatible(propertyValue, ignoredTypes);   

        jsonCompatiblePVPairs{idx+1} = value;
    end

end
