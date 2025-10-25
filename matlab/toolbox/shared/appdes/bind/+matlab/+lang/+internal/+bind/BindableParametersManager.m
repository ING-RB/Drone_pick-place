classdef (Hidden) BindableParametersManager < handle
    % BINDABLEPARAMETERSMANAGER is a singleton which manages the current
    % instance of BindableParameters which is used to get what parameters
    % (properties, events, key indexes) can be bound to.

    % Copyright 2022 The MathWorks, Inc.

    properties (Constant)
        % Singleton instance of the class
        Instance = matlab.lang.internal.bind.BindableParametersManager;
    end

    properties
        BindableParameters;
    end

    methods (Access = 'private')
        % Private constructor
        function obj = BindableParametersManager
            obj.BindableParameters = matlab.lang.internal.bind.BindableParameters;

            % put an mlock in this constructor to avoid any of the "clear"
            % commands from freeing up the Instance of the object.
            mlock;
        end
    end
end