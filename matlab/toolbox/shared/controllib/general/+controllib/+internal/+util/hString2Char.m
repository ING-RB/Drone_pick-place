function val = hString2Char(val)
% hString2Char helper function for string to char conversion. It takes a
% string or a string array and returns a charactor array or a cell array of
% charactors, repectively. If the input is a cell or a struct, the function
% loops thourgh each element in the cell or each field in the struct to
% convert any string to a char.

% Copyright 2016 The MathWorks, Inc.

import controllib.internal.util.*

% Case 1: Cell array of character arrays (pass through)
if ~iscellstr(val)
    % Case 2: Cell array
    if iscell(val)
        for ct = 1:numel(val)
            val{ct} = hString2Char(val{ct});
        end
    % Case 3: Structure array	
    elseif isstruct(val)
        fn = fieldnames(val);
        for ctf = 1:numel(fn)
            for ct = 1:numel(val)
                val(ct).(fn{ctf}) = hString2Char(val(ct).(fn{ctf}));
            end
        end
    elseif isstring(val)
        % Case 4: String scalar
        if isscalar(val)
            val = char(val);
        % Case 5: Empty string
        elseif isempty(val)
            val = '';
        % Case 6: String array
        else
            val = cellstr(val);
        end	
    end
end


