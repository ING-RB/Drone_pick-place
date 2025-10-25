function warningstr = getReadWarning(messageText, classtype, doclink, datatag)

% GETREADWARNING returns the warning string for interface objects.

% WARNINGSTR = DISPLAYREADWARNING(MESSAGETEXT, CLASSTYPE, DOCLINK, DATATAG)
% specifically filters out whether a valid doc help link exists for the
% warning messages. If exists, the doc link is displayed along with the
% warning message. Else, a new warning message is displayed without mention
% of the doc links.
% MESSAGETEXT is the warning text returned from the instrument java object.
% CLASSTYPE is the interface object for which the warning message is being
% displayed.
% DOCLINK is the documentation link.
% DATATAG is a character array identifier. It can be either 'nodata' or 'somedata'.

% WARNINGSTR is the entire warning text, coalesced and returned back.

%   Copyright 2017 The MathWorks, Inc.
validLink = ~isempty(doclink);

switch datatag
    case 'nodata'
        if validLink
            IOmessageID = 'instrument:iowarnings:noDataRead';
        else
            IOmessageID = 'instrument:iowarnings:noDataReadNoLink';
        end
    case 'somedata'
        if validLink
            IOmessageID = 'instrument:iowarnings:unsuccessfulRead';
        else
            IOmessageID = 'instrument:iowarnings:unsuccessfulReadNoLink';
        end
end
% Get the the final warning string.
if validLink
    warningstr = message(IOmessageID, messageText, classtype, doclink).getString();
else
    warningstr = message(IOmessageID, messageText, classtype).getString();
end
end