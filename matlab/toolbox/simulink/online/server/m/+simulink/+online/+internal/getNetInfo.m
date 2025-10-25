function getNetInfo()
    isAuto = slonline.isStreamingAuto();
    isStable = slonline.isNetworkStable();
    latency = slonline.getLatency();
    networkTime = slonline.getNetworkTime();
    serverTime = slonline.getServerTime();
    
    % Display the results
    disp(['isStreamingAuto: ', bool2str(isAuto)]);
    disp(['isNetworkStable: ', bool2str(isStable)]);
    disp(['latency: ', num2str(latency)]);
    disp(['networkTime: ', num2str(networkTime)]);
    disp(['serverTime: ', num2str(serverTime)]);
end

function str = bool2str(val)
    if val
        str = 'true';
    else
        str = 'false';
    end
end
