function defaulterrorcallback(~, evt)
% The default value for ErrorCallback properties.

%   Copyright 2009-2024 The MathWorks, Inc.
[id, msg] = matlab.graphics.internal.prepareDefaultErrorCallbackWarning(evt);
stack = dbstack('-completenames');
if (size(stack,1) == 1)
    warningstatus = warning('OFF', 'BACKTRACE');
    warning(id, '%s', msg);
    warning(warningstatus);
else
    warning(id, '%s', msg);
end

end
