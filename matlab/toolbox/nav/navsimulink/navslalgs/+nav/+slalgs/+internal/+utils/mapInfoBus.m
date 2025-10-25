function mapInfo_bus = mapInfoBus()
% This class is for internal use only. It may be removed in the future.

%   Copyright 2024 The MathWorks, Inc.

mapInfo = struct();
mapInfo.Resolution = 1;
mapInfo.GridLocationInWorld = [0 0];

mapInfo.OccupancyMatrix = false(10,10);

mapInfo.GridSize = [10 10];
mapInfo.GridOriginInLocal = [0 0];

% Create Estimation Data Bus for Simulink Model
mapInfoBusInfo = Simulink.Bus.createObject(mapInfo);
mapInfo_bus = evalin('base', mapInfoBusInfo.busName);

% Delete created Bus from base workspace
evalin('base', 'clear slBus1' );
end
