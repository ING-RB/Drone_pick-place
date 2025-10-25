function varargout = validateVerticalAxis(filename, value)
% Validate 'VerticalAxis'

% Copyright 2018-2019 The MathWorks, Inc.

if isstring(value)
    value = convertStringsToChars(value);
end
list = {'X', 'Y', 'Z'};
validateattributes(value, {'char'}, {'nonempty','scalartext'}, filename, 'VerticalAxis');

str = validatestring(value, list, filename, 'VerticalAxis');

if nargout == 1
    varargout{1} = str;
end
