function validateViewPlane(filename, value)
% Validate 'ViewPlane'

% Copyright 2022 The MathWorks, Inc.

list = {'XY', 'YX', 'XZ', 'ZX', 'YZ', 'ZY', 'auto'};
validateattributes(value, {'char', 'string'}, {'nonempty','scalartext'}, filename, 'ViewPlane');

validatestring(value, list, filename, 'ViewPlane');

