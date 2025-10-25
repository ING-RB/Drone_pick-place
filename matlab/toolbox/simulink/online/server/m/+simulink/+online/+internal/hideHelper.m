function hideHelper()
    serverToClientChannel = ['/slonline/hideHelper'];
    message.publish(serverToClientChannel, "");
end