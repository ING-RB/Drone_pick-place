function [rnames,cnames] = getrcname(src)
%GETIONAMES  Returns input and output names.

%  Copyright 2013 The MathWorks, Inc.
if src.IsReal
   cnames = {''};
else
   cnames = {'Real';'Imag'};
end
D = src.IOData;
rnames = [getOutputName(D); getInputName(D)];
