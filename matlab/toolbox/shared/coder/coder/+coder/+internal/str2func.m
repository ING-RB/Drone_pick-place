%

% Copyright 2020 The MathWorks, Inc.
%
% coder.internal.str2func(fcnName, functionNames, defaultFcn)
%
% Usage:
% fh = coder.internal.str2func(fcnName, {'fcn1', 'fcn2',...}, @defaultFcn) OR
% fh = coder.internal.str2func(fcnName, {'fcn1', 'fcn2',...})
%
% Call to this function returns an object that acts like a function handle.
% The returned object can be "called" using fh(args) syntax, and it dispatches 
% to the function named fcnName, as long as that function name is in the list of fcn1..fcnN provided.
%
% Think of this as a "bounded" version of str2func that supports code generation. You give it 
% an exhaustive list of all possible values of fcnName, and it'll generate code for all of those,
% and at run-time, it'll find the appropriate one and call it.
% 
% The 2nd input (functionNames) must be a constant value.
% 
% In MATLAB execution, coder.internal.str2func(a,...) is equivalent to str2func(a). 
%
function fh = str2func(fcnName, functionNames, defaultFcn)
%#codegen

coder.allowpcode('plain');
coder.internal.prefer_const(functionNames);
coder.internal.assert(iscellstr(functionNames) || isstring(functionNames), 'Coder:toolbox:BoundedStr2FuncNamesNotConstant');
if nargin < 3
    defaultFcn = @errorDefaultFcn;
end
if isempty(coder.target)
    if ~any(strcmp(functionNames, fcnName))
        fh = defaultFcn;
    else
        fh = str2func(fcnName);
    end
else
    coder.internal.assert(coder.internal.isConst(functionNames), 'Coder:toolbox:BoundedStr2FuncNamesNotConstant');
    fh = coder.internal.BoundedStr2FuncImpl(fcnName, functionNames, defaultFcn);
end

function out = errorDefaultFcn(varargin)
    coder.internal.error('Coder:toolbox:BoundedStr2FuncUnexpectedInput', fcnName); 
    out = [];
end
end
