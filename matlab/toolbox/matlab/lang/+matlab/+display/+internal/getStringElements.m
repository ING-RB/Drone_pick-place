function stringRep = getStringElements(stringRep)
% Get string representation of input string array. Any
% empty (i.e. "") or missing elements are replaced with
% string(missing).

% Copyright 2020 The MathWorks, Inc.
    arguments
        stringRep string
    end
    
    % Replace missing and zero length elements with string(missing)
    missingElementIndices = ismissing(stringRep) | strlength(stringRep) == 0;
    stringRep(missingElementIndices) = "<missing>";
end