% getMsgToDisplay strips message.getString output from XML artifacts
% 
%   MSG = MSLDiagnostic.getMsgToDisplay(REMOVEHOTLINKS, MESSAGE)
% 
%   MESSAGE is a formatted internationalized message, that can be 
%   created with the method message. MESSAGE's getString method can return string
%   that may have various XML elements. getMsgToDisplay strips them away.
% 
%   In addition, hotlinks will be removed from the result string if REMOVEHOTLINKS = true
% 
%   MSG = MSLDiagnostic.getMsgToDisplay(MESSAGE) is equivalent to     MSLDiagnostic.getMsgToDisplay(false, MESSAGE)
% 
%   See also MESSAGE

%   Copyright 2015-2016 The MathWorks, Inc.
%   Built-in function.
