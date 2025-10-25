function [inames,onames] = getios(src)
%GETIOS  Returns input and output names.

%  Copyright 1986-2004 The MathWorks, Inc.
inames = src.Model.InputName;
onames = src.Model.OutputName;
