function [rnames,cnames] = getrcname(src)
%GETIONAMES  Returns input and output names.

%  Copyright 2022 The MathWorks, Inc.
rnames = get(src.Model,'OutputName');
cnames = get(src.Model,'InputName');
