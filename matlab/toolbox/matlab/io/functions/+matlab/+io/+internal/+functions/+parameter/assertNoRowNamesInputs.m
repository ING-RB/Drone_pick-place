function assertNoRowNamesInputs(supplied)
% Errors when passed NV pairs relating to RowNames

%   Copyright 2021 The MathWorks, Inc.

function validateRowNamesNVPair(name)
    if isfield(supplied, name) && supplied.(name)
        error(message("MATLAB:readtable:RowNamesNotSupported", name));
    end
end

unsupportedNVPairs = ["ReadRowNames", ...
                      "RowNamesColumn", ...
                      "RowNamesRange", ...
                      "RowNamesSelector"];
                  
for i = 1:length(unsupportedNVPairs)
   validateRowNamesNVPair(unsupportedNVPairs(i)); 
end
end