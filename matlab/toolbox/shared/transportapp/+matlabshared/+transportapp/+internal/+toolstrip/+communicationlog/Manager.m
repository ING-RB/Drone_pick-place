classdef Manager < handle
    %MANAGER creates and maintains the lifetime for the View and Controller
    %instances for the Communication Log section.

    % Copyright 2020-2021 The MathWorks, Inc.

    properties
        View
        Controller
    end

    methods
        function obj = Manager(form)
            [obj.View, obj.Controller] = ...
                matlabshared.transportapp.internal.utilities.factories.ModulesFactory.getCommunicationLogSection(form);

            if ~isa(obj.Controller, "matlabshared.transportapp.internal.toolstrip.communicationlog.IController")
                throw(MException(message("transportapp:toolstrip:communicationlog:InvalidControllerType")));
            end
        end
    end
end