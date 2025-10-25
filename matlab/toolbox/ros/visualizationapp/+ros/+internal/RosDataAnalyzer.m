classdef RosDataAnalyzer < handle
    %This function is for internal use only. It may be removed in the future.
    
    %RosDataAnalyzer launches the ROS Data Analyzer app
    
    %   Copyright 2023-2024 The MathWorks, Inc.
    
    properties (SetAccess = private)
        Events
        Presenter
        Model
    end
    
    methods
        function obj = RosDataAnalyzer()
            %RosDataAnalyzer
            % Checkout ROS Toolbox License
            ros.internal.utilities.checkoutROSToolboxLicense();

            obj.Events = ros.internal.RosbagViewerEvents;
            obj.Presenter = ros.internal.ViewerPresenter(obj.Events);
            obj.Model = ros.internal.ModelEventHandler(obj.Events);

            appMap = ros.internal.RosDataAnalyzer.getAppMap;
            appMap(obj.Presenter.UniqueTagApp) = obj; %#ok<NASGU>
        end
    end

    methods(Static, Access = ?ros.internal.ViewerPresenter)
        function appMap = getAppMap

            mlock
            persistent appHandleMap;
            if isempty(appHandleMap)
                appHandleMap = containers.Map;
            end
            appMap = appHandleMap;
        end
    end
end

