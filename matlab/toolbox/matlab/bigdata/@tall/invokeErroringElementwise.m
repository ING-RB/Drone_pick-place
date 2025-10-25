function varargout = invokeErroringElementwise(fcnInfo, varargin)
%INVOKEERRORINGELEMENTWISE Invokes elementwise function that can throw runtime errors

%   Copyright 2015-2022 The MathWorks, Inc.

% This prevents this frame and anything below it being added to the gather
% error stack.
stack = createInvokeStack(fcnInfo.Name);
markerFrame = matlab.bigdata.internal.InternalStackFrame(stack); %#ok<NASGU>

try
    args = invokeInputCheck(fcnInfo, varargin{:});
    fcn = str2func(fcnInfo.Name);
    
    fcn = matlab.bigdata.internal.FunctionHandle(fcn);
    [varargout{1:max(1, nargout)}] = elementfun(fcn, args{:});
    varargout = cellfun(@(out) invokeOutputInfo(fcnInfo, out, args), varargout, 'UniformOutput', false);
catch E
    matlab.bigdata.internal.throw(E);
end
end
