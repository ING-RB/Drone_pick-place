classdef ROSMiddlewareConfigurationWorkflow < matlab.hwmgr.internal.hwsetup.Workflow
    % This class is for internal use only. It may be removed in the future.

    % ROSMiddlewareConfigurationWorkflow is a class that contains all of 
    % the persistent information for the ROS Middleware Configuration
    % setup screens.

    %  Copyright 2022 The MathWorks, Inc.

    properties
        % Properties inherited from Workflow class
        Name = 'ROS Middleware';
        FirstScreenID
    end
    
    properties
        % RMWImplementation - Name of the ros middleware(rmw) implementation
        % that user has which will be configured to work with.
        RMWImplementation
    end

    methods(Static)
        function session = getSession
            persistent sessionMap;
            if isempty(sessionMap)
                sessionMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
            end
            session = sessionMap;
        end
    end
    
    methods
        function obj = ROSMiddlewareConfigurationWorkflow(varargin)           
            % Call base class
            obj@matlab.hwmgr.internal.hwsetup.Workflow(varargin{:})
            obj.Window.Title = message('ros:mlros2:rmwsetup:MainWindowTitle').getString();
            obj.FirstScreenID = 'ros.internal.rmwsetup.SelectRMWImplementation';
            
            % Set defaults where applicable
            obj.RMWImplementation = message('ros:mlros2:rmwsetup:RMWFastrtpsCpp').getString();
        end

        function delete(obj)
            session = obj.getSession;
            remove(session, keys(session));
        end
    end
    
end