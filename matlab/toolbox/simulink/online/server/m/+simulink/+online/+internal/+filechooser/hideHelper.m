function hideHelper()
    % Publish to clients to hide the file chooser dialog if they are not active.
    serverToClientChannel = ['/slonline/hideHelper'];
    message.publish(serverToClientChannel, "");
end