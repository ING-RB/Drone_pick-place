function out = varfunEmptyConstr(classname, size)
% VARFUNEMPTYCONSTR Constructs an empty of the specified size for empty grouped varfun output.
% Function should only be called extrinsically.

%   Copyright 2018-2020 The MathWorks, Inc.

fun = str2func(classname+".empty");
out = fun(size);
