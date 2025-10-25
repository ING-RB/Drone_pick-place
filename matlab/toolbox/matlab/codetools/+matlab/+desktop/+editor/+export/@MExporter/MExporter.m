classdef (Sealed) MExporter < matlab.desktop.editor.export.RtcExporter
%matlab.desktop.editor.export.MExporter Exports an RTC document with given ID to M.

% Inherits the main export method from RtcExporter.
%       result = MExporter.export(editorId, options)
% where options is a struct of name/value pairs.
%
% This exporter respects the following options. All are optional.
%   Destination:  The path to the target file.
%   Encoding:     A Character encoding used for fopen. The default is 'UTF-8'.
%   OpenExportedFile:   If true, it opens the exported M file in the editor. This requires
%                 Destination to be set.
% All other options are silently passed through.
% Returns: If 'Destination' is set, it returns that path, Otherwise the M code is returned.
%
% Example usage:
%   exp = matlab.desktop.editor.export.MExporter;
%   filePath = exp.export('123456', struct('Destination', 'path/to/file.m'))
%   mString = exp.export('123456')
%
%   opts.Destination = 'path/to/file.m';
%   opts.Encoding = '';
%   opts.OpenExportedFile = true;
%   exp.export('123456', opts)
%
% This class shouldn't be used directly.
% Better use matlab.desktop.editor.exportDocument
% or matlab.desktop.editor.internal.exportDocumentByID

%   Copyright 2020-2021 The MathWorks, Inc.

    properties (GetAccess = protected, SetAccess = private, Hidden = true)
        rtcExportInternalFormat = 'm';
    end

    methods
        % Override.
        function result = handleResponse(obj, responseData, sentOptions)
            if ~isfield(sentOptions, 'Destination')
                % If there is no destination, return the M content.
                result = responseData.content;
                return;
            end
            fopenOpts = {};
            if isfield(sentOptions, 'Encoding')
                fopenOpts = {'n', sentOptions.Encoding};
            end
            result = obj.writeToFile(sentOptions.Destination, responseData.content, fopenOpts);
        end

        % Override
        function launch (~, filePath)
            edit(filePath);
        end
    end
end
