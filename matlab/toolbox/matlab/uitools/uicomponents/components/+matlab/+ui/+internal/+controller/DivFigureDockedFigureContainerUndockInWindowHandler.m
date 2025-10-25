classdef DivFigureDockedFigureContainerUndockInWindowHandler < handle
% This class helps manage the behavior of undocking the docked figure
% container "in-window" in environments where this workflow is needed. An
% example is an environment which is in a browser window, such as MO+MPA

    properties (Access = private)
        messageHandled = false;
        messageHandler;
    end % private properties

    methods(Access = private)
        function this = DivFigureDockedFigureContainerUndockInWindowHandler()
            this.messageHandler = message.subscribe('/gbtweb/divfigure/setUndockInWindowFigureContainer', @(varargin) (this.sendMessageUndockInWindow()));
        end
    end

    methods(Static)
        function obj = instance()
            mlock;
            persistent uniqueInstance;

            if(~isempty(uniqueInstance))
                % Means we have already instantiated our listener
                obj = uniqueInstance;
                return;
            else
                obj = matlab.ui.internal.controller.DivFigureDockedFigureContainerUndockInWindowHandler();
                uniqueInstance = obj;
            end

        end
    end
    
    methods
        function sendMessageUndockInWindow(this)
            message.publish('/updateUndockInWindowFigureContainer', matlab.ui.internal.FigureServices.inEnvironmentForInWindowDialogFigures());
            this.messageHandled = true;
        end

        function messageHandledVal = getMessageHandledValue(this)
            messageHandledVal = this.messageHandled;
        end

        function clearMessageHandledValue(this)
            % For testing purpose
            this.messageHandled = false;
        end

    end
end
