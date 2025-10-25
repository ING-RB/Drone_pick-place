function b = blanks(n)
%

%   Copyright 1984-2023 The MathWorks, Inc.

if (isnumeric(n) || islogical(n)) && isempty(n)
    n = 0;
elseif ~isscalar(n)
    error(message("MATLAB:NonScalarInput"))
end

b = repmat(' ', 1, n);
