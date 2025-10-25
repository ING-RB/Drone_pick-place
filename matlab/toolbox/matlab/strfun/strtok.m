function [token, remainder] = strtok(str, delimiters)
%

%   Copyright 1984-2023 The MathWorks, Inc.

    if nargin < 1 || nargin > 2
        narginchk(1, 2);
    end
    
    if nargin < 2
        delimiters = char([9:13, 32]); % White space characters
    elseif iscell(delimiters)
        delimiters = char([delimiters{:}]);
    elseif isstring(delimiters)
        delimiters(ismissing(delimiters)) = [];
        delimiters = char([delimiters{:}]);
    end

    computeRemainder = (nargout > 1);
    
    if iscell(str)
        token = str;
        remainder = str;
        for idx = 1:numel(str)
            [token{idx}, remainder{idx}] = doStrtok(str{idx}, delimiters, computeRemainder);
        end
    elseif isstring(str)
        token = str;
        remainder = str;
        for idx = 1:numel(str)
            if ismissing(str(idx))
                remainder(idx) = '';
                continue;
            end
            [token{idx}, remainder{idx}] = doStrtok(str{idx}, delimiters, computeRemainder);
        end
    else
        [token, remainder] = doStrtok(str, delimiters, computeRemainder);
    end

end

function [token, remainder] = doStrtok(str, delimiters, computeRemainder)

    token = str([]);
    remainder = token;

    len = length(str);
    if len == 0
        return;
    end

    idx = 1;
    while (any(str(idx) == delimiters))
        idx = idx + 1;
        if (idx > len)
           return;
        end
    end

    start = idx;
    while (~any(str(idx) == delimiters))
        idx = idx + 1;
        if (idx > len)
           break;
        end
    end
    finish = idx - 1;

    token = str(start:finish);
    if computeRemainder && finish < len
        remainder = str(finish + 1:len);
    end

end
