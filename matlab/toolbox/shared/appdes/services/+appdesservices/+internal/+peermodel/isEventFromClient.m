function isFromClient = isEventFromClient( event )
%ISEVENTFROMCLIENT - This function returns true is event originated from
%the client and it returns false if the event originated from the server
    isFromClient = appdesservices.internal.peermodel.PeerNodeProxyView.isEventFromClient(event, ...
        appdesservices.internal.peermodel.PeerNodeProxyView.PeerEventMarkerObject);   
end

