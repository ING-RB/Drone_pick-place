function [rnames,cnames] = getrcname(src)
%GETIONAMES  Returns input and output names.

%  Copyright 2011 The MathWorks, Inc.
rnames = get(src.Model,'OutputName');
cnames = rnames;

for ct = 1:numel(rnames)
   if ~isempty(rnames{ct})
      cnames{ct} = ['e@',rnames{ct}];
   end
end
