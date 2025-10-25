function s = getsize(this)
%GETSIZE  Returns grid size required for plotting data. 
%
%   S = GETSIZE(THIS) returns the plot size needed to render the
%   data (S(1) is the number of rows and S(2) the number of columns).
%   The value [0 0] indicates that the data is invalid, and NaN's 
%   is used for arbitrary sizes.

%   Copyright 2015 The MathWorks, Inc.
if numel(this.Index)==numel(this.Frequency)
   s = [1 1];
else
   s = [0 0];
end