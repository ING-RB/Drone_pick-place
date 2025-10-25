classdef Manager < handle
    % MANAGER creates and controls lifetime of the different sections
    % (communication log, code log, and property inspector) of the app
    % space area. It also creates the parent panels of the above sections.

    % Copyright 2020-2022 The MathWorks, Inc.

    %% Managers
    properties
        CommunicationLogManager
        CodeLogManager
        PropertyInspectorManager matlabshared.transportapp.internal.appspace.propertyinspector.IInspectable = ...
            matlabshared.transportapp.internal.appspace.propertyinspector.Manager.empty

    end

    %% Other Properties
    properties (Constant)
        Constants = matlabshared.transportapp.internal.appspace.Constants
    end

    methods
        function obj = Manager(form)
            arguments
                form (1, 1) matlabshared.transportapp.internal.utilities.forms.AppSpaceForm
            end

            import matlabshared.transportapp.internal.utilities.factories.ModulesFactory
            import matlabshared.transportapp.internal.utilities.factories.AppSpaceElementsFactory

            % Create the base grid on which all appspace elements are
            % going to be created.
            baseGrid = obj.createBaseGridLayout(form.Parent);

            % Construct the panels for all appspace sections.
            % Communication Log Panel
            communicationLogPanel = AppSpaceElementsFactory.createPanel ...
                (baseGrid, obj.Constants.CommunicationLogLayout, obj.Constants.CommunicationLog);

            % Code Log Panel
            codeLogPanel = AppSpaceElementsFactory.createPanel ...
                (baseGrid, obj.Constants.CodeLogLayout, obj.Constants.CodeLog);

            % Property Inspector Panel
            propertyInspectorGrid = obj.createPropertyInspectorSidePanelGridLayout(form.PropertyInspectorSidePanel);
            propertyInspectorPanel = AppSpaceElementsFactory.createPanel ...
                (propertyInspectorGrid, obj.Constants.PropertyInspectorLayout, []);

            % Create Communication Log Section Manager
            form.Parent = communicationLogPanel;
            obj.CommunicationLogManager = matlabshared.transportapp.internal.appspace.communicationlog.Manager(form);

            % Create Code Log Section Manager
            form.Parent = codeLogPanel;
            obj.CodeLogManager = matlabshared.transportapp.internal.appspace.codelog.Manager(form);

            % Create PropertyInspector Section Manager
            form.Parent = propertyInspectorPanel;
            obj.PropertyInspectorManager = ModulesFactory.getPropertyInspectorManager(form);
        end

        function setTransportProxy(obj, transportProxy)
            % Inject the TransportProxy into the Property Inspector Manager
            % to populate the Property Inspector section with the
            % TransportProxy properties.
            arguments
                obj
                transportProxy internal.matlab.inspector.InspectorProxyMixin
            end
            inspectTransportProxy(obj.PropertyInspectorManager, transportProxy);
        end

        function connect(obj)
            obj.CommunicationLogManager.connect();
            obj.PropertyInspectorManager.connect();
        end

        function disconnect(obj)
            % Perform actions before the Appspace Manager is deleted.
            obj.PropertyInspectorManager.disconnect();
            obj.CommunicationLogManager.disconnect();
        end

        function delete(obj)
            delete(obj.CommunicationLogManager);
            delete(obj.CodeLogManager);
            delete(obj.PropertyInspectorManager);
        end
    end

    methods (Access = private)
        function gridLayout = createBaseGridLayout(obj, rootWindow)
            % Create the base grid on which all appspace elements are
            % going to be created.

            gridLayout = matlabshared.transportapp.internal.utilities.factories.AppSpaceElementsFactory.createGridLayout ...
                (rootWindow, obj.Constants.BaseGrid);
        end

        function gridLayout = createPropertyInspectorSidePanelGridLayout(obj, sidePanel)
            gridLayout = matlabshared.transportapp.internal.utilities.factories.AppSpaceElementsFactory.createGridLayout ...
                (sidePanel, obj.Constants.PropertyInspectorGrid);
        end
    end
end
