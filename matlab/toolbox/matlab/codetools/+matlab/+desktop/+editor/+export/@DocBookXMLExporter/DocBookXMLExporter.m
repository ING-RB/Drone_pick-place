classdef (Sealed) DocBookXMLExporter < matlab.desktop.editor.export.RtcExporter
%matlab.desktop.editor.export.DocBookXMLExporter Exports an RTC document
% with given ID to DocBookXML.

% Inherits the main export method from RtcExporter.
%       result = DocBookXMLExporter.export(editorId, options)
% where options is a struct of name/value pairs.
%
% This exporter respects the following options.
%   Destination:  The path to the target file.
%
% All other options are silently passed through.
%
% Example usage:
%   exp = matlab.desktop.editor.export.DocBookXMLExporter;
%   filePath = exp.export('123456', struct('Destination', 'path/to/file.xml'))
%
%   opts.Destination = 'path/to/file.m';
%   exp.export('123456', opts)
%
% This class shouldn't be used directly.
% Better use matlab.desktop.editor.exportDocument
% or matlab.desktop.editor.internal.exportDocumentByID

%   Copyright 2020 The MathWorks, Inc.
    properties (GetAccess = protected, SetAccess = private, Hidden = true)
        rtcExportInternalFormat = 'docbookxml';
    end

    methods

        function newoptions = setup(~, oldoptions)
            matlab.desktop.editor.export.ExportUtils.assertHasDestination(oldoptions)
            newoptions = oldoptions;
            if ~isfield(newoptions, 'examplePath')
               try
                    error('This export format requires an examplePath.');
                catch ex
                    throwAsCaller(ex);
                end
            end
        end

        function result = handleResponse(obj, responseData, sentData)

            [dir, ~, ~] = fileparts(sentData.Destination);
            dataArray = responseData.content;
            for n = 1 : length(dataArray)
                switch dataArray(n).dataType
                    case 'Raw'
                        result = fullfile(dir, dataArray(n).fileName);
                        obj.writeToFile(result, dataArray(n).data, {});
                    case 'Base64'
                        imagePath = fullfile(dir,  dataArray(n).fileName);
                        splitResult = split(dataArray(n).data, ',');
                        base64Data = char(splitResult(2));
                        % Make sure connector is running
                        connector.ensureServiceOn
                        % Using C++ exportutilities connector plugin
                        sendData.filePath = imagePath;
                        sendData.base64Data = base64Data;
                        message.publish('/editor/exportutilities/base64tofile', sendData);
                    otherwise
                        error('Unknown type in response data.')
                end
            end
        end

        function launch (~, filePath)
            edit(filePath);
        end
    end
end
