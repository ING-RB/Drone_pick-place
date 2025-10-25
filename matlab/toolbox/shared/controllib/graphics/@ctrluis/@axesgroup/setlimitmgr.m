function setlimitmgr(h,eventdata)
%SETLIMITMGR  Enables/disables limit manager.

%   Copyright 1986-2008 The MathWorks, Inc.
% Postset for LimitManager property: enable/disable listeners managing limits

h.LimitListeners.setEnabled(strcmpi(h.LimitManager,'on'))
