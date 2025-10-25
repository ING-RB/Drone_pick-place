function tf = isTextStrict(value)
%

%   Copyright 2017-2023 The MathWorks, Inc.

    tf = (ischar(value) && ((isempty(value) && isequal(size(value),[0 0])) || isrow(value))) || isstring(value) || iscellstr(value);
end
