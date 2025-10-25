classdef (Sealed) PDFExporter < matlab.desktop.editor.export.RtcExporter
%matlab.desktop.editor.export.PDFExporter Exports an RTC document with
% given ID to PDF.
%
% Inherits the main export method from RtcExporter.
%       result = PDFExporter.export(editorId, options)
% where options is a struct of name/value pairs.
%
% This exporter respects the following options.
%   Destination:  The path to the target file. This is mandatory.
%   OpenExportedFile:   If true, it opens the exported PDF file in the most
%                 appropriate application.
% All other options are silently passed through.
% Returns: The path to the .pdf file.
%
%
% Example usage:
%   exp = matlab.desktop.editor.export.PDFExporter;
%   filePath = exp.export('123456', struct('Destination', 'path/to/file.pdf'))
%
%   opts.Destination = 'path/to/file.pdf';
%   opts.OpenExportedFile = true;
%   exp.export('123456', opts)
%
% This class shouldn't be used directly.
% Better use matlab.desktop.editor.exportDocument
% or matlab.desktop.editor.internal.exportDocumentByID

%   Copyright 2020-2023 The MathWorks, Inc.

    properties (GetAccess = protected, SetAccess = private, Hidden = true)
        rtcExportInternalFormat = 'xslfo';
    end

    methods (Static)
        function pdfURL = getPDFUrlFromXSLFO(xslfoStr)
           inputs.content = xslfoStr;
           outputs.Destination = [tempname '.pdf'];
           exporter = matlab.desktop.editor.export.PDFExporter;
           pdfFileName = exporter.handleResponse(inputs, outputs);
           pdfURL = matlab.ui.internal.URLUtils.getURLToUserFile(pdfFileName);
        end

        function createAndOpenPDFFromXSLFO(xslfoStr)
            inputs.content = xslfoStr;
            outputs.Destination = [tempname '.pdf'];
            exporter = matlab.desktop.editor.export.PDFExporter;
            pdfFileName = exporter.handleResponse(inputs, outputs);
            open(pdfFileName);
         end
    end

    methods
        function newoptions = setup(~, oldoptions)
            matlab.desktop.editor.export.ExportUtils.assertHasDestination(oldoptions)
            newoptions = matlab.desktop.editor.export.ExportUtils.fillMATLABRelease(oldoptions);
            if ~isfield(newoptions, 'figurePath')
                mTemp = tempname;
                mkdir(mTemp)
                figurePath = [mTemp filesep];
                newoptions.figurePath = figurePath;
            end
        end

        function result = handleResponse(obj, responseData, sentData)
            xslfoFile = [tempname '.fo'];
            % Delete temp file on cleanup.
            scopedDelete = onCleanup(@()delete(xslfoFile));
            % Save XSL string to file
            obj.writeToFile(xslfoFile, responseData.content);
            % Setup and run fop.
            fop = mlreportgen.internal.fop.createFOPObject();
            fop.DebugMode = 0; % Disable debug messages, e.g. about glyph re-mapping.
            fop.DocumentURI = xslfoFile;
            fop.OutputFilePath = sentData.Destination;
            fop.execute();
            result = sentData.Destination;
        end

        function cleanup(~, sentOptions)
            status = rmdir(sentOptions.figurePath, 's'); %#ok<NASGU>
            % It's not a disaster if this fails so we ignore the result.
        end

        function launch (~, filePath)
            uiopen(filePath, true);
        end
    end
end
