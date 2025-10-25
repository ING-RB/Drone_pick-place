function cellstrings = validateAndEscapeCellStrings(cellstrings, propertyname )
% VALIDATEESCAPEDCELLSTRINGS validate and transform input cell string 

% Copyright 2015-2021, The MathWorks, Inc.

if ischar(cellstrings)
    cellstrings = {cellstrings};
end

persistent uninterpreted interpreted
if isempty(uninterpreted)
    uninterpreted = ["\\";"\a";"\b";"\f";"\n";"\r";"\t";"\v"];
    interpreted = arrayfun(@sprintf,uninterpreted);
end

try
    cellstrings = replace(cellstrings, uninterpreted, interpreted);
catch
    error(message('MATLAB:textio:textio:InvalidStringOrCellStringProperty',propertyname));
end

end
