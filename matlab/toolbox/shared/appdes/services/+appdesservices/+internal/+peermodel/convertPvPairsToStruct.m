function metadata = convertPvPairsToStruct(pvPairs)
% Helper Method to convert a pvPair cell array into a struct
%
% Inputs:
%
%   pvPairs     : cell array of {name, value, name, value} pairs
%
% Outputs:
%
%   struct     : a struct object

% Copyright 2013 The MathWorks, Inc.

% Error Checking
narginchk(1, 1);
validateattributes(pvPairs, ...
    {'cell'}, ...
    {});

assert( rem(length(pvPairs),2) == 0,...
    'Unbalanced pv pair array');

metadata = struct;

% loop over pvPairs and make a struct out of each pv pair
for idx = 1:2:length(pvPairs)  
    propertyName = pvPairs{idx};
    propertyValue = pvPairs{idx+1};
    metadata.(propertyName) = propertyValue;
end

end
