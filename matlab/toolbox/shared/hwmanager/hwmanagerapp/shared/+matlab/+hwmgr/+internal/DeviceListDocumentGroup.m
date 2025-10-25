classdef DeviceListDocumentGroup < matlab.ui.container.internal.appcontainer.DocumentGroup
    %DEVICELISTDOCUMENTGROUP A custom DocumentGroup using
    %clientapp-startpage-ui as a dynamically loaded bundle.

    % Copyright 2022 The MathWorks, Inc.

    properties(Hidden, Constant)
        GroupTag = "DeviceListDocumentGroup"
    end

    methods
        function obj = DeviceListDocumentGroup(varargin)
            obj = obj@matlab.ui.container.internal.appcontainer.DocumentGroup(varargin{:});

            % Setup dynamic bundle factory method for Device List
            obj.DocumentFactory = struct("Modules", matlab.hwmgr.internal.DeviceListModuleInfo);

            % Use default group tag if no Tag is specified
            if isempty(obj.Tag)
                obj.Tag = obj.GroupTag;
            end

            % Set CollectiveLabel for documents if none is specified
            if isempty(obj.CollectiveLabel)
                obj.CollectiveLabel = "DeviceListDocuments";
            end
        end
    end
end