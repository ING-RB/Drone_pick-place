function out = convertStringsInStruct(in)
%CONVERTSTRINGSINSTRUCT Convert strings in struct fields into character
%vectors
%   OUT = CONVERTSTRINGSINSTRUCT(IN) returns a structure that contains the
%   same information as the input with all strings converted to character
%   arrays. This function supports nested structures and and cell arrays.

%   Author: Dinesh Iyer
%   Copyright 2017 The MathWorks Inc.

out = in;

fn = fieldnames(out);

% For an array of structures, iterate over each element
for cnt = 1:numel(out)
    % Iterate over each field of each element.
    for cntF = 1:numel(fn)
        if iscell(out(cnt).(fn{cntF}))
            if iscellstr(out(cnt).(fn{cntF})) || isstring(out(cnt).(fn{cntF}))
                out(cnt).(fn{cntF}) = convertStringsToChars(out(cnt).(fn{cntF}));
            else
                % If the field value is a non-homegeous cell array, then
                % process each value within it recursively. 
                out(cnt).(fn{cntF}) = matlab.io.internal.imagesci.convertStringsInCell(out(cnt).(fn{cntF}));
            end
        elseif isstruct(out(cnt).(fn{cntF}))
            % If the field value is a struct, then process each value
            % individually. 
            out(cnt).(fn{cntF}) = matlab.io.internal.imagesci.convertStringsInStruct(out(cnt).(fn{cntF}));
        else
            % Can be a primitive type or an object for which we will defer to
            % the recommended routine.
            out(cnt).(fn{cntF}) = convertStringsToChars(out(cnt).(fn{cntF}));
        end
    end
end
    