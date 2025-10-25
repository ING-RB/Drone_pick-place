function output = normalizeToCellstrColumnVector(input)
%normalizeToCellstrColumnVector converts text inputs (string arrays, 
%   character vectors, or cell arrays of character vectors) into a 
%   column cell vector containing character arrays.

%   Copyright 2019 The MathWorks, Inc.
 
    output = convertStringsToChars(input);
    
    % Let non-stringy inputs pass through.
    if ~ischar(output) && ~iscellstr(output)
        return;
    end
    
    % Normalize char vectors to cellstr.
    output = cellstr(output);
    output = reshape(output, [], 1);
end
