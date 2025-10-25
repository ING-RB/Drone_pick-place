classdef FigureLifecycleControllerManager < handle
    % Manager for the singleton instance of FigureLifecycleController
    %
    % No other logic other than storing the instance should go here

    % Copyright 2022 The MathWorks, Inc.
    methods(Static)
        function obj = instance(varargin)
            % 0 arguments - gets the instance, lazily creating if needed
            %
            % 1+ arguments - clears the instance and gets new instance

            mlock;
            persistent uniqueInstance;

            % Clear
            if(nargin == 1)
                if(~isempty(uniqueInstance))
                    delete(uniqueInstance);
                    uniqueInstance = [];
                end
            end

            if isempty(uniqueInstance)
                masterChannel = '/figure/meta';
                obj = matlab.ui.internal.controller.FigureLifecycleController(masterChannel);
                uniqueInstance = obj;
            end

            obj = uniqueInstance;
        end

        function handleFevalMessage(uuid, returnChannel, eventType)
            figureLifecycleController = matlab.ui.internal.controller.FigureLifecycleControllerManager.instance();
            figureLifecycleController.handleFevalMessage(uuid, returnChannel, eventType);
        end
    end
end