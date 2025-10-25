function out = invokeUnaryCast(fcnInfo, in)
%invokeUnaryCast Invokes unary cast methods like DOUBLE, UINT8 etc.

% Copyright 2016-2022 The MathWorks, Inc.

% This prevents this frame and anything below it being added to the gather
% error stack.
stack = createInvokeStack(fcnInfo.Name);
markerFrame = matlab.bigdata.internal.InternalStackFrame(stack); %#ok<NASGU>

try
    args = invokeInputCheck(fcnInfo, in);
    fcn = str2func(fcnInfo.Name);
        
    fcn = matlab.bigdata.internal.FunctionHandle(fcn);
    out = elementfun(fcn, args{:});
    out = invokeOutputInfo(fcnInfo, out, in);
catch E
    matlab.bigdata.internal.throw(E);
end
end
