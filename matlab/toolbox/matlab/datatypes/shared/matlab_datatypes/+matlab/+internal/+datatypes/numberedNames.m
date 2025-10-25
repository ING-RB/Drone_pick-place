function names = numberedNames(prefix,numbers,oneName)
%NUMBEREDNAMES Append numeric suffix to a common base text.

%   Copyright 2012-2019 The MathWorks, Inc.

% Little or no error checking: prefix is assumed char row or scalar string, and
% numbers is assumed a vector of positive integers, or a scalar positive integer
% when oneName is true.

if nargin < 3 || ~oneName % return cellstr the shape of the input
    if isempty(numbers)
        names = cell(size(numbers));
    else
        names = cellstr(string(prefix) + numbers);
    end
else % return one character vector
    names = char(string(prefix) + numbers(:)); % defend against non-scalar
end
