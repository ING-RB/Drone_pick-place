function names = numberedNames(prefix,numbers,oneName)   %#codegen
%NUMBEREDNAMES Append numeric suffix to a common base text.

%   Copyright 2018-2021 The MathWorks, Inc.

% Little or no error checking: prefix is assumed char row or scalar string, and
% numbers is assumed a vector of positive integers, or a scalar positive integer
% when oneName is true.
% oneName must be constant.

if nargin < 3 || ~coder.const(oneName) % return cellstr the shape of the input
    names = cell(size(numbers));
    prefixstr = string(prefix);
    for i = 1:numel(names)
        names{i} = char(prefixstr + numbers(i));
    end
else % return one character vector
    names = char(string(prefix) + numbers(:)); % defend against non-scalar
end
