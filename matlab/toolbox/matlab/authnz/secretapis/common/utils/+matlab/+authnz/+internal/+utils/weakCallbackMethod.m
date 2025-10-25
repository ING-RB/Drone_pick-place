function fcn = weakCallbackMethod(obj, method)
%weakCallbackMethod Adaptor store weak reference to object in callback
%   fcn = weakCallbackMethod(obj, method) returns an adapted function fcn
%   that keeps a weak reference to obj, and invokes
%     method(obj, varargin{:})
%   if obj remains live.
%
%   Typical use case would be:
%     obj.Listener = event.listener(src, evtName, weakCallbackMethod(obj, handleEvent));

% Copyright 2024 The MathWorks, Inc.
arguments
    obj (1,1) handle
    method (1,1) function_handle
end
weakObj = matlab.lang.WeakReference(obj);
fcn = @(varargin) iMaybeInvoke(weakObj, method, varargin{:});
end

function iMaybeInvoke(weakObj, method, varargin)
obj = weakObj.Handle;
if isvalid(obj)
    % Invoke the callback
    method(obj, varargin{:});
else
    % Ignore
end
end
