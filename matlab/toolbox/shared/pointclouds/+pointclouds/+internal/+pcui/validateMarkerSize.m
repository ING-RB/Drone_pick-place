function validateMarkerSize(filename, value)
% Validate 'MarkerSize'

% Copyright 2018 The MathWorks, Inc.

validateattributes(value, {'numeric'}, {'nonempty', 'nonnan', ...
    'finite', 'nonsparse', 'real', 'scalar', '>', 0}, filename, 'MarkerSize');
