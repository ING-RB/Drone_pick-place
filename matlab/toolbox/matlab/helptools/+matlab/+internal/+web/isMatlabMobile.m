function is_mobile = isMatlabMobile()
    clientType = connector.internal.getClientType();
    is_mobile = startsWith(clientType, 'mobile');
end