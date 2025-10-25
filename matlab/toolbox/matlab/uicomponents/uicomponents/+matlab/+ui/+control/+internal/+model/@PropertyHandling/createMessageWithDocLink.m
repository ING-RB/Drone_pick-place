function messageWithDocLink = createMessageWithDocLink(errorText, linkId, docFunction)
% CREATEMESSAGEWITHDOCLINK - This function will create a
% message object for cases where the default message has a
% hyperlink, but when hyperlinks are not available, there is a
% second message providing context that the link might have provided.
% For example:
% With link (sprintf is link)
% For more information on formatting operators, see sprintf.
% Without link, a little more context is provided so user can
% find the same information without a link.
% For more information on formatting operators, see the documentation for sprintf.


if matlab.internal.display.isHot
    % Create message object with link
    docReference = ['<a href="matlab: helpPopup(''', docFunction, ''')">', docFunction, '</a>'];
else
    % Create message object without link
    docReference = docFunction;
end

messageObj = message(linkId, docReference);

% Use string from object
messageText = getString(messageObj);
messageWithDocLink = sprintf('%s %s', errorText, messageText);

end