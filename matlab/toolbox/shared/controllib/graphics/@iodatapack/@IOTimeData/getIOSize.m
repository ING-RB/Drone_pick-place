function s = getIOSize(this)
%GETIOSIZE  Returns io size required for plotting data. 
%
%   S = GETIOSIZE(THIS) returns the plot size needed to render the
%   data.

%   Copyright 2013 The MathWorks, Inc.
ny = length(this.OutputData);
nu = length(this.InputData);
s = [ny nu];
