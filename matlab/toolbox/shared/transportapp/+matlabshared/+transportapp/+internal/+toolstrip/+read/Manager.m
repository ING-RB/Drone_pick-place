classdef Manager < handle
    %MANAGER creates and maintains the lifetime for the View and Controller
    %instances for the read section.

    % Copyright 2021 The MathWorks, Inc.

    properties
        View
        Controller
    end

    methods
        function obj = Manager(form)
            [obj.View, obj.Controller] = ...
                matlabshared.transportapp.internal.utilities.factories.ModulesFactory.getReadSection(form);

            if ~isa(obj.Controller, "matlabshared.transportapp.internal.toolstrip.read.IController")
                throw(MException(message("transportapp:toolstrip:read:InvalidControllerType")));
            end
        end
    end
end