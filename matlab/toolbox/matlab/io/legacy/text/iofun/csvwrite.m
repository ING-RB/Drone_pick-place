function csvwrite(filename, m, r, c)

if ~ischar(filename) && ~isstring(filename)
    error(message('MATLAB:csvwrite:FileNameMustBeString'));
end

if nargin < 3
    r = 0;
end

if nargin < 4
    c = 0;
end

try
    dlmwrite(filename, m, ',', r, c); %#ok<DLMWT> 
catch e
    throw(e)
end

%   Copyright 1984-2024 The MathWorks, Inc.
