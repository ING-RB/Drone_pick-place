classdef RtcExporterInterface < handle
%matlab.desktop.editor.export.RtcExporterInterface Interface for RTC document exporters.

%   Copyright 2020 The MathWorks, Inc.

    %% Instance properties
    properties (Abstract, GetAccess = protected, SetAccess = private, Hidden = true)
        % The internal format name of the exporter.
        rtcExportInternalFormat;
    end

    %% Instance methods
    methods (Abstract)
        % Main export method
        result = export(obj, rtcId, options)

        % Setup and prepare option
        outOptions = setup(obj, inOptions)

        % Handle data came back from JS exporters.
        result = handleResponse(obj, data, sentOptions)

        % Launch file of these exporter's type
        launch(obj, filePath)

        % Clean up.
        cleanup(obj, sentOptions)
    end
end
