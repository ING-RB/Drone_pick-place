function m = csvread(filename, r, c, rng)

narginchk(1,Inf);

if ~ischar(filename) && ~(isstring(filename) && isscalar(filename))
    error(message('MATLAB:csvread:FileNameMustBeString')); 
end
filename = char(filename);


if exist(filename,'file') ~= 2 
    error(message('MATLAB:csvread:FileNotFound'));
end

if nargin < 2
    r = 0;
end

if nargin < 3
    c = 0;
end

if nargin < 4
    m=dlmread(filename, ',', r, c); %#ok<*DLMRD> 
else
    m=dlmread(filename, ',', r, c, rng);
end

%   Copyright 1984-2024 The MathWorks, Inc.