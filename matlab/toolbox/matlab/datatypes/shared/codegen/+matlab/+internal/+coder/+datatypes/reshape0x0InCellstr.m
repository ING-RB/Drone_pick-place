function out = reshape0x0InCellstr(c)
% RESHAPE0X0INCELLSTR Reshapes 0x0 elements of a cellstr to 1x0.

%   Copyright 2020 The MathWorks, Inc.

% In certain cases, when calling some extrinsic function (for example,
% strtrim) on a const cellstr input, we might end up generating '' as output.
% Since codegen represents '' as 1x0 chars, this function can be used to convert
% the 0x0 char obtained from MATLAB to 1x0 chars. 
% Such conversion should not be required in generated code and hence this
% function should only be called extrinsically.

out = c;
for i = 1:numel(c)
    if sum(size(c{i})) == 0
        out{i} = reshape(c{i},1,[]);
    end
end
