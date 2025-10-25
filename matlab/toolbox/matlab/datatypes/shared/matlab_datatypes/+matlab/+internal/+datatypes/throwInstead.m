function ME = throwInstead(ME,oldMsgID,newMsg)
%THROWINSTEAD Look for a specified MException, and throw or return a different one instead.
%   THROWINSTEAD(ME,OLDERRID1,NEWERRID)
%   THROWINSTEAD(ME,{OLDERRID1,OLDERRID2,...},NEWERRID)
%   THROWINSTEAD(ME,...,NEWERRMSG)
%   NEWME = THROWINSTEAD(ME,...)

%   Copyright 2014-2020 The MathWorks, Inc.

if ~isa(newMsg,'message')
    % Input is a message ID, not a message, create a new message. If args are needed to
    % create the message, caller should pass in a message.
    newMsg = message(newMsg);
end

% If the exception is one of the specified errors, return the desired one instead.
if matches(ME.identifier,oldMsgID) % ME.identifier is always scalar.
   ME = MException(newMsg);
end

if nargout == 0
    throwAsCaller(ME);
end