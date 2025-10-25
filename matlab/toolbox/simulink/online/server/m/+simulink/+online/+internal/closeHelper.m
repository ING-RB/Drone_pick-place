function closeHelper()
    serverToClientChannel = ['/slonline/closeHelper'];
    message.publish(serverToClientChannel, "");
end