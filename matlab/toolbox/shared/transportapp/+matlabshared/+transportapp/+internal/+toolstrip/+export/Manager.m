classdef Manager < handle
    %MANAGER creates and maintains the lifetime for the View and Controller
    %instances for the export section.

    % Copyright 2020-2021 The MathWorks, Inc.

    properties
        View
        Controller
    end

    methods
        function obj = Manager(form)
            [obj.View, obj.Controller] = ...
                 matlabshared.transportapp.internal.utilities.factories.ModulesFactory.getExportSection(form);

             if ~isa(obj.Controller, "matlabshared.transportapp.internal.toolstrip.export.IController")
                 throw(MException(message("transportapp:toolstrip:export:InvalidControllerType")));
             end
        end

        function setTransportName(obj, transportName)
            obj.Controller.setTransportName(transportName);
        end
    end
end