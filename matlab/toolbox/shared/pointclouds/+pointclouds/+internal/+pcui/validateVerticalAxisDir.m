function varargout = validateVerticalAxisDir(filename, value)
% Validate 'VerticalAxisDir'

% Copyright 2018-2019 The MathWorks, Inc.

if isstring(value)
    value = convertStringsToChars(value);
end
list = {'Up', 'Down'};
validateattributes(value, {'char'}, {'nonempty','scalartext'}, filename, 'VerticalAxisDir');

str = validatestring(value, list, filename, 'VerticalAxisDir');

if nargout == 1
    varargout{1} = str;
end
    
