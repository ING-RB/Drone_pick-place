function tf = hasvar(t, varname)
%HASVAR Checks if table contains variable with given name
%
%   TF = HASVAR(T, VARNAME) returns true if table t contains variable
%   varname, false otherwise.

% Copyright 2022 The MathWorks, Inc.

varnames = t.Properties.VariableNames;
tf = matches(varname, varnames);
