function out = convertStringsInCell(in)
%CONVERTSTRINGSINCELL Convert strings in cell arrays into character vectors
%   OUT = CONVERTSTRINGSINCELL(IN) returns a cell array that contains the
%   same information as the input with all strings converted to character
%   arrays. This function supports nested cell arrays and structures.

%   Author: Dinesh Iyer
%   Copyright 2017 The MathWorks Inc.

if iscellstr(in) || isstring(in)
    out = convertStringsToChars(in);
    return;
end

out = cell(size(in));

% We need to process each element of the cell array individually as the
% cell can be non-homogeous. 
for cnt = 1:numel(in)
    if iscell(in{cnt})
        % If the element is a cellstr, then no further processing needs to
        % be done. 
        if iscellstr(in{cnt})
            out{cnt} = in{cnt};
        else
            % If the element is a non-homegeous cell array, then process
            % each element within it recursively.
            out{cnt} = matlab.io.internal.imagesci.convertStringsInCell(in{cnt});
        end
    elseif isstruct(in{cnt})
        % If the element is a struct, then process each field of each
        % element of the struct individually.
        out{cnt} = matlab.io.internal.imagesci.convertStringsInStruct(in{cnt});
    else
        % Can be a primitive type or an object for which we will defer to
        % the recommended routine.
        out{cnt} = convertStringsToChars(in{cnt});
    end
end