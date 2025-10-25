function analyzePerf(filePath)

% The function reads the perf data from a xml file and analyze it.
% Inputs:
%     filePath: string, path to the perf xml file

% Copyright 2021 The MathWorks, Inc.

%data = readstruct(filePath);

txt = fileread(filePath);
data = jsondecode(txt);

if isempty(data)
    error("No valid data from " + filePath);
end

analyzeUpdateRegions(data.updateregions);

end

function analyzeUpdateRegions(dataArr)
len = length(dataArr);

network = zeros(1, len);
ping = zeros(1, len);
imgSize = zeros(1, len);
server = zeros(1, len);
time = zeros(1, len);

for i = 1 : len
    data = dataArr(i).data;
    network(i) = data.network;
    ping(i) = data.ping;
    imgSize(i) = data.imageSize;
    server(i) = data.server;
    time(i) = data.time;
end
timeOffset = min(time);


% calculate mean, median, std, max, min value
% analyze('Client-server round trip ping', ping);
% analyze('Server-client round trip with one way playload', network);
% analyze('Server process time', server);

% plot the numbers for each update
figure('Name', 'Update region');
plot(time - timeOffset, server);
hold on;
plot(time - timeOffset, network);
hold on;
plot(time - timeOffset, ping);

ylabel('milliseconds');
xlabel('log timestamp in milliseconds');
legend('server process time','one way payload', 'ping');

% plot time vs image size
figure('Name', 'Image size')
plot(imgSize, server,'b.', imgSize, network, 'r.');

xlabel('image pixel numbers')
ylabel('milliseconds')
legend('server process time','one way payload');
end

function analyze(name, data)
disp(name);
fprintf('mean: %d, median: %d, min: %d, max: %d, std: %d \n',...
    round(mean(data)), round(median(data)), round(min(data)), round(max(data)),...
    round(std(data)));
end
