function tf = isCharVector(x)
%isCharVector  True for a character vector.
%   This function returns true if x is a row character array and false
%   otherwise.

%   Copyright 2016-2018 The MathWorks, Inc.

tf = ischar(x) && ( isrow(x) || isequal(x, '') );
end
