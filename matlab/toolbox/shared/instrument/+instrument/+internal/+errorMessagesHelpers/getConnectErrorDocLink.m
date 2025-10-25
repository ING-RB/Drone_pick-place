function completeMessage = getConnectErrorDocLink(interfaceName)
%GETCONNECTERRORDOCLINK returns the troubleshooting doc link and the
% connect error message for Instrument Control and MATLAB Hardware
% Interfaces for all connection errors.
% To add a doc link for a new interface, update the ConnectErrorDocInfo
% class.

%   Copyright 2021 The MathWorks, Inc.

% Retrieve the doc tag and location information for an interface.
% Parses the first string from the input to get only the interface name and
% not the interface type(if provided).
docInfo = instrument.internal.errorMessagesHelpers.ConnectErrorDocInfo.DocInfoMap(interfaceName{1});

% Get the doc link from the doc tag and location information.
docIDRef = getDocIDRef(docInfo(1), docInfo(2));

connectErrorID = "transportlib:utils:ConnectError";

% Form the complete error message using the doc link and return the message.
completeMessage = message(connectErrorID, docIDRef).getString;
end

function docRef = getDocIDRef(docID, docIDMapLoc)
% Get the doc reference link for the specified doc anchor id.

% Label name to show for connection error message doc links.
linkTag = message("transportlib:utils:ConnectErrorLinkTag").getString;

% Create the topic ID for interface specific connection error troubleshooting doc
TopicID = docIDMapLoc + docID + ")";

% Create the doc link
docRef = "<a href=" + """" + TopicID + """" + ">" + linkTag + "</a>";
end