% This function provides the runtime mean and var analysis.
% Will return network and server time for each measurement.
function [mNetwork, mPing, mServer, mImage] = getPerfData(filePath)
    txt = fileread(filePath);
    data = jsondecode(txt);
    
    if isempty(data)
        error("No valid data from " + filePath);
    end
    
    [mNetwork, mPing, mServer, mImage] = analyzeUpdateRegions(data.updateregions);
    
    end
    
    function [mNetwork, mPing, mServer, mImage] = analyzeUpdateRegions(dataArr)
    len = length(dataArr);
    
    network = zeros(1, len);
    ping = zeros(1, len);
    imgSize = zeros(1, len);
    server = zeros(1, len);
    time = zeros(1, len);
    startTime = [];
    
    for i = 1 : len
        data = dataArr(i).data;
        if isfield(data, 'network')
            network(i) = data.network;
        else 
            network(i) =  -100;
        end
        if isfield(data, 'ping')
            ping(i) = data.ping;
        else 
            ping(i) = -100;
        end
        imgSize(i) = data.imageSize;
        server(i) = data.server;
        
        if isempty(startTime)
            startTime = data.time;
        end
        time(i) = data.time - startTime;
    end
    
    mNetwork = analyze('network', network);
    mPing = analyze('ping', ping);
    mServer = analyze('server', server);
    mImage = analyze('image size', imgSize);
    end
    
    function m = analyze(name, data)
    m = mean(data);
end