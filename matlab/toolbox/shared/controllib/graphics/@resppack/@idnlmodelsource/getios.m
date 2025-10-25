function [inames,onames] = getios(src)
%GETIOS  Returns input and output names.

%  Copyright 2010 The MathWorks, Inc.
inames = src.Model.InputName;
onames = src.Model.OutputName;
if isempty(inames)
   % time series!
   inames = cellfun(@(x)['e@',x],onames,'UniformOutput',false);
end
