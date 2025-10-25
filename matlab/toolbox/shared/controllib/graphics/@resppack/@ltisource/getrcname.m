function [rnames,cnames] = getrcname(src)
%GETIONAMES  Returns input and output names.

%  Copyright 1986-2004 The MathWorks, Inc.
rnames = get(src.Model,'OutputName');
cnames = get(src.Model,'InputName');
