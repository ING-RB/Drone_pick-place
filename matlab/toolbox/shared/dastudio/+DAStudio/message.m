function [oMsg, oId, treatAsSimulinkError] = message(inMsgId, varargin)
% DASTUDIO.MESSAGE(id, varargin) is obsolete.  Use 'message' object

%   Copyright 1990-2012 The MathWorks, Inc.


mObj = message(inMsgId,varargin{:});
oMsg = mObj.getString;

oId  = inMsgId;
treatAsSimulinkError = false;

end % DAStudio.message
