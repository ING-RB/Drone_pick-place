function A = appendDataVariables(A,B,appendStr)
%appendDataVariables Append new variables to table with renaming
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.
%

%   Copyright 2021 The MathWorks, Inc.

% rename the vars and uniquify labels before concatenation
newVarNames = B.Properties.VariableNames + "_" + appendStr; 
uniqueLabels = matlab.lang.makeUniqueStrings([A.Properties.VariableNames,newVarNames],...
    string(A.Properties.DimensionNames),namelengthmax);
B.Properties.VariableNames = uniqueLabels(width(A)+1:end);
% append to input table
A = [A,B];