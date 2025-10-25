function [rnames,cnames] = getrcname(src)
%GETIONAMES  Returns input and output names.

%  Copyright 1986-2015 The MathWorks, Inc.
rnames = get(src.Model,'OutputName');
cnames = get(src.Model,'InputName');
if isempty(cnames)
   % ths assumption is that time series models always need to be treated as
   % I/O models with noise channels serving as inputs. In other words, the
   % @idnlmodelsource would always be used for step/impulse plots. 
   cnames = cellstr(idpack.utCreateNoiseInputNames(rnames,'e',length(rnames)));
end
