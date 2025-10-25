% mustBeIncreasing Utility function to validate input is strictly
% increasing double

%   Copyright 2020 The MathWorks, Inc.

function mustBeIncreasing(value)
    validateattributes(value, {'double'},{'increasing'});
end
