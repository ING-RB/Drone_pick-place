classdef Manager < handle
    %MANAGER creates and maintains the lifetime for the View and Controller
    %instances for the communication log section.

    % Copyright 2020-2021 The MathWorks, Inc.

    properties
        View
        Controller
    end

    methods
        function obj = Manager(form)
            [obj.View, obj.Controller] = ...
                matlabshared.transportapp.internal.utilities.factories.ModulesFactory.getAppSpaceCommunicationLog(form);
        end

        function connect(obj)
            obj.Controller.connect();
        end

        function disconnect(obj)
            obj.Controller.disconnect();
        end

        function delete(obj)
            delete(obj.Controller);
            delete(obj.View);
        end
    end
end