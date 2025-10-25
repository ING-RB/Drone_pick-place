function [inames,onames] = getios(src)
%GETIOS  Returns input and output names.

%  Copyright 1986-2011 The MathWorks, Inc.
onames = src.Model.OutputName;
inames = onames;
for ct = 1:numel(inames)
   if ~isempty(inames{ct})
      inames{ct} = ['e@',inames{ct}];
   end
end
