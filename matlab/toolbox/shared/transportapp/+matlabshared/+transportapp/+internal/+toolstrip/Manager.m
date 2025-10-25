classdef Manager < handle
    %MANAGER creates and maintains lifetime of the different toolstrip
    %section managers, namely the WriteSectionManager, ReadSectionManager,
    %AnalyzeSectionManager, CommunicationLogSectionManager, and
    %ExportSectionManager.

    % Copyright 2020-2023 The MathWorks, Inc.

    properties (Constant)
        EmptyColumnWidth = 10
        EmptyColumnAlignment = "left"

        % Toolstrip button common attributes
        ButtonWidth = 50
        ButtonAlignment (1, 1) string = "center"
    end

    properties
        WriteSectionManager
        ReadSectionManager
        AnalyzeSectionManager
        CommunicationLogSectionManager
        ExportSectionManager
    end

    methods
        function obj = Manager(form)
            obj.WriteSectionManager = matlabshared.transportapp.internal.toolstrip.write.Manager(form);
            obj.ReadSectionManager = matlabshared.transportapp.internal.toolstrip.read.Manager(form);
            obj.CommunicationLogSectionManager = matlabshared.transportapp.internal.toolstrip.communicationlog.Manager(form);
            obj.AnalyzeSectionManager = matlabshared.transportapp.internal.toolstrip.analyze.Manager(form);
            obj.ExportSectionManager = matlabshared.transportapp.internal.toolstrip.export.Manager(form);

            setTransportName(obj.ExportSectionManager, form.TransportName);
        end
    end

    methods (Static)
        function columnDetails = prepareToolstripColumn(width, alignment)
            % Prepare a toolstrip column where the toolstrip UI elements
            % are popuplated.

            columnDetails = ...
                matlabshared.transportapp.internal.utilities.forms.ToolstripColumn(width, alignment);
        end

        function columnDetails = prepareEmptyToolstripColumn()
            % Create an empty column to serve as buffer between 2 toolstrip
            % columns.

            import matlabshared.transportapp.internal.toolstrip.Manager
            columnDetails = ...
                matlabshared.transportapp.internal.utilities.forms.ToolstripColumn(Manager.EmptyColumnWidth, Manager.EmptyColumnAlignment);
        end
    end
end