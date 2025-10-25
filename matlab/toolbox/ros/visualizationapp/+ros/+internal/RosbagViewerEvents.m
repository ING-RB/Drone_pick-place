classdef RosbagViewerEvents < handle
%This class is for internal use only. It may be removed in the future.

%   Copyright 2021-2023 The MathWorks, Inc.

    events
        % Triggered when a new bagfile is selected
        RosbagSelectedPM

        % Triggered when a rosbag has been accessed
        RosbagLoadedMP

        % Triggered when data sources are added, removed, or changed
        DataSourcesRequiredPM

        % Triggered when the current time changes
        CurrentTimeChangedPM

        % Triggered during playback or when using next/previous buttons
        MoveToNextMessagePM

        % Triggered when new data is available for a timestamp
        DataForTimeMP

        % Triggered when new data source is requested for range of times
        DataRangeRequestedPM

        % Triggered when new data is available for range of times
        DataForTimeRangeMP

        % Triggered when network details are entered
        InputRosNetworkPM

        % Triggered when topic details are fetched by model
        TopicsInfoMP
		
		% Triggerred when rosbag is opened for first time
        CreateAppSessionCachePM

        % Triggered when user creates and close visualizer, closes the
        % app and change in datasource
        UpdateAppSessionCachePM

        % Triggered when rosbag has cache file available and request for
        % data
        RequestAppSessionCacheDataPM

        % Triggered when rosbag cache file is requested, return the data
        % from the cachefile
        ReturnAppSessionCacheDataMP

        % Update Frame ID 
        UpdateFrameIdPM
    end
end