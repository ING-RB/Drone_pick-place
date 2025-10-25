% mustBeA Utility function to validate input is strictly of the
% given class. Do not allow class conversion.

%   Copyright 2020 The MathWorks, Inc.

function mustBeA(input, className)
    validateattributes(input, {className}, {});
end
