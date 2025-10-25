function s = table2struct(t,varargin)  %#codegen
%

%   Copyright 2012-2024 The MathWorks, Inc.

if ~coder.target('MATLAB')
    % codegen, redirect to codegen specific function and return
    s = matlab.internal.coder.table2struct(t, varargin{:});
    return
end

pnames = {'ToScalar'};
dflts =  {    false };
[toScalar] = matlab.internal.datatypes.parseArgs(pnames, dflts, varargin{:});

toScalar = matlab.internal.datatypes.validateLogical(toScalar,'ToScalar');
if toScalar
    s = getVars(t);
else
    s = cell2struct(table2cell(t),matlab.internal.tabular.makeValidVariableNames(t.Properties.VariableNames,'warn'),2);
end
