function sz = getIOSize(this, varargin)
%GETIOSIZE get IO size.

%   Copyright 2013-2017 The MathWorks, Inc.
IOD = this.IOData;
if isempty(IOD)
   sz = [0 0]; % prevent error at construction
else
   sz = getIOSize(this.IOData);
end
