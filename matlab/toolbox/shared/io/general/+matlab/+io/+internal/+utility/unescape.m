function strs = unescape(strs)
%UNESCAPE Replace escaped characters with their escape sequences

% Copyright 2015-2021, The MathWorks, Inc.

persistent uninterpreted interpreted
if isempty(uninterpreted)
    uninterpreted = ["\\";"\a";"\b";"\f";"\n";"\r";"\t";"\v"];
    interpreted = arrayfun(@sprintf,uninterpreted);
end

try
    strs = replace(strs,interpreted,uninterpreted);
catch 
    error(message("MATLAB:textio:textio:InvalidStringOrCellStringProperty","inputs"));
end

end