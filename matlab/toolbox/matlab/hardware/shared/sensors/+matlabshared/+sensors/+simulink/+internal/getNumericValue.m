function numericValue = getNumericValue(varargin)
% Function to get the numeric value from strings like 64.24Hz
% e.g numericValue = getNumericValue('64.24Hz') 
% >> numericValue = 64.24

%   Copyright 2020 The MathWorks, Inc.
num = nargin;
numericValue = zeros(1,num);
for i= 1:num
    numericValue(i) =  sscanf(varargin{i},'%f');
end
end