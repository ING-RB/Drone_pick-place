% mustBeDoubleVector Utility function to validate input is strictly a
% vector of double with nonnan and finite values.

%   Copyright 2020 The MathWorks, Inc.

function mustBeDoubleVector(value)
    validateattributes(value, {'double'}, {'vector', 'nonnan', 'finite'});
end
