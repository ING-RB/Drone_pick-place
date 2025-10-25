
function out = getNameTag(name)
% Replace characters that are not alphanumeric or underscores
% with underscores

% Copyright 2016 The MathWorks, Inc.

validateattributes(name, {'char'}, {});
out = regexprep(name, '\W', '_');
end