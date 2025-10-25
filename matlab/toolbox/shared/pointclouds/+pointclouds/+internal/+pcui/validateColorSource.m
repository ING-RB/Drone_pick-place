function validateColorSource(filename, value)
% Validate 'ColorSource'

% Copyright 2022 The MathWorks, Inc.

list = {'X', 'Y', 'Z', 'Intensity','Color', 'Row', 'Column', 'auto'};
validateattributes(value, {'char', 'string'}, {'nonempty','scalartext'}, filename, 'ColorSource');

validatestring(value, list, filename, 'ColorSource');
