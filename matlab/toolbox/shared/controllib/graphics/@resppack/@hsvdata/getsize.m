function s = getsize(this)
%GETSIZE  Returns grid size required for plotting data. 

%   Copyright 1986-2005 The MathWorks, Inc.
if isempty(this.HSV)
   s = [0 0];
else
   s = [1 1];
end