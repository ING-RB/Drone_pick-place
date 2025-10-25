classdef (Hidden) BindingLifecycleControllerManager < handle
    % BINDINGLIFECYCLECONTROLLERMANAGER is a singleton which manages the
    % current instance of BindingLifecycleController
    %
    % To get the current BindingLifecycleController:
    %
    %  currentFactory =
    %  matlab.lang.internal.bind.BindingLifecycleControllerManager.Instance.LifecycleController

    % Copyright 2022 The MathWorks, Inc.

    properties(Constant)
        % Singleton instance of the class
        Instance = matlab.lang.internal.bind.BindingLifecycleControllerManager;
    end

    properties
        LifecycleController;
    end

    methods (Access=private)
        % Private constructor
        function obj = BindingLifecycleControllerManager
            obj.LifecycleController = matlab.lang.internal.bind.BindingLifecycleController;

            % put an mlock in this constructor to avoid any of the "clear"
            % commands from freeing up the Instance of the object.
            mlock;
        end
    end
end

