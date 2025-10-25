function value = prepStringForValidation(value)
% 

% PREPSTRINGFORVALIDATION  Prepare strings or character vectors for
% validation. In particular, deblank and convert to char vector or cellstr
% if it is a string
%
% See also OPTIM.OPTIONS.META.FORMATSETOFSTRINGS
    
%   Copyright 2019 The MathWorks, Inc.

if ischar(value)
    value = strip(value);
elseif isStringScalar(value)
    value = char(strip(value));
elseif isstring(value)
    value = cellstr(strip(value));
end

