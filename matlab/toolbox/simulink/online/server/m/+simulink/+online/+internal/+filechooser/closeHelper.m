function closeHelper()
    % Publish to channel telling clients to close the file chooser dialog.
    serverToClientChannel = ['/slonline/closeHelper'];
    message.publish(serverToClientChannel, "");
end