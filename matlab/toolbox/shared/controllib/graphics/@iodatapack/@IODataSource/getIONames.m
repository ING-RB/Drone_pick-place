function [ynames,unames] = getIONames(src)
%GETIONAMES  Returns input and output names.

%  Copyright 2013 The MathWorks, Inc.

D = src.IOData;
ynames = getOutputName(D); 
unames = getInputName(D);
