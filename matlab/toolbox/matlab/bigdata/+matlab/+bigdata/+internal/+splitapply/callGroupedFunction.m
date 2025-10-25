function varargout = callGroupedFunction(fun, session, varargin)
% CALLGROUPEDFUNCTION Call the function handle, correctly translating any 
% error message to what core splitapply would issue.
%   Y = CALLGROUPEDFUNCTION(FUN,SESSION,X)
%   [Y1,Y2,...] = CALLGROUPEDFUNCTION(FUN,SESSION,X1,X2,...)

%   Copyright 2018-2023 The MathWorks, Inc

try
    [varargout{1:nargout}] = fun(varargin{:});
catch err
    if isequal(err.identifier, 'MATLAB:bigdata:array:ExecutionError')
        rethrow(err);
    end
    funStr = func2str(session.FunctionHandle);
    idx = 1;
    idx = matlab.internal.datatypes.ordinalString(idx);
    m = message('MATLAB:splitapply:FunFailed', funStr, idx);
    matlab.bigdata.internal.throw(addCause(MException(m.Identifier,getString(m)),err));
end