function validateProjection(filename, value)
% Validate 'Projection'

% Copyright 2022 The MathWorks, Inc.

list = {'orthographic', 'perspective'};
validateattributes(value, {'char', 'string'}, {'nonempty','scalartext'}, filename, 'Projection');

validatestring(value, list, filename, 'Projection');

