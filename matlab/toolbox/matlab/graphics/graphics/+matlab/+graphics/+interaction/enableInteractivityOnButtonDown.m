function enableInteractivityOnButtonDown(ax)
%ENABLEINTERACTIVITYONBUTTONDOWN enables interactions on buttondown

% This function disables both default interactions and the axes toolbar and
% enables them again on the first buttondown. Subsequent buttondowns have
% no effect.

%   Copyright 2019 The MathWorks, Inc.

disableDefaultInteractivity(ax);

a = addlistener(ax,'Hit',@(o,e)noop());
weakA = matlab.lang.WeakReference(a);
a.Callback = @(o,e)enableInteractionsAndDelete(o, weakA);
end

function enableInteractionsAndDelete(ax, a)    
    enableDefaultInteractivity(ax)
    delete(a.Handle);
end
