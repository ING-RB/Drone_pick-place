
classdef (Sealed) LaTeXExporter < matlab.desktop.editor.export.RtcExporter
%matlab.desktop.editor.export.LaTeXExporter Exports an RTC document with
% given ID to LaTeX.
%
% Inherits the main export method from RtcExporter.
%       result = LaTeXExporter.export(editorId, options)
% where options is a struct of name/value pairs.
%
% This exporter respects the following options.
%   Destination:  The path to the target file. This is mandatory.
%   OpenExportedFile:   If true, it opens the exported LaTeX file in the most
%                 appropriate application.
% All other options are silently passed through.
% Returns: The path to the .tex file.
%
% The LaTeXExporter creates a matlab.sty file on the same leven as the .tex
% file. Furthermore, it creates an image directory if needed. The name of
% that directory is '<given_filename>_images'.
%
% Example usage:
%   exp = matlab.desktop.editor.export.LaTeXExporter;
%   filePath = exp.export('123456', struct('Destination', 'path/to/file.tex'))
%
%   opts.Destination = 'path/to/file.text';
%   opts.OpenExportedFile = true;
%   exp.export('123456', opts)
%
% This class shouldn't be used directly.
% Better use matlab.desktop.editor.exportDocument
% or matlab.desktop.editor.internal.exportDocumentByID

%   Copyright 2020-2023 The MathWorks, Inc.

    properties (GetAccess = protected, SetAccess = private, Hidden = true)
        rtcExportInternalFormat = 'tex';
    end

    methods
        function newoptions = setup(~, oldoptions)

            import matlab.desktop.editor.export.ExportUtils

            newoptions = oldoptions;
            ExportUtils.assertHasDestination(oldoptions);

            if isfield(newoptions, 'imagePath')
                imagedir = newoptions.imagePath;
                if (startsWith(imagedir, "."))
                    [path, ~, ~] = fileparts(fullfile(char(newoptions.Destination)));
                    imagedir = fullfile(path, imagedir);
                end
                % Normalize path, remove '/' or '\' at the end.
                imagedir = regexprep(imagedir, '[\\/]+$', '');
            else
                imagedir = ExportUtils.imageFolder(oldoptions.Destination);
            end

            % Default image path.
            [dpath, name] = fileparts(newoptions.Destination);
            dpath = fullfile(dpath, name + "_media");
            % Normalize image path, but don't override original image path.
            [ipath, name, ext] = fileparts(string(imagedir));
            ipath = fullfile(ipath, name + ext);
            % Now check if default image path and image path are the same.
            if strcmp(dpath, ipath)
                % Default image path is used. Delete the folder.
                if exist(imagedir, 'dir')
                    rmdir(imagedir, 's')
                end
                mkdir(imagedir);
             else
                % Custom image path is used. Do not delete the folder!
                % Existing files in imagedir are overwritten.
                if ~exist(imagedir, 'dir')
                   mkdir(imagedir);
                end
             end

            % LaTeXExporter.js expects graphics path in Unix style.
            newoptions.imagePath = [strrep(imagedir, '\', '/') '/'];
        end

        function result = handleResponse(obj, responseData, sentData)
            result = obj.writeToFile(sentData.Destination, responseData.content);
            % Copying matlab.sty if not already there.
            [fileDir, ~, ~] = fileparts(fullfile(char(sentData.Destination)));
            styFile = fullfile(fileDir, 'matlab.sty');
            if ~exist(styFile, 'file')
                [thisDir, ~, ~] = fileparts(mfilename('fullpath'));
                copyfile(fullfile(thisDir, 'LaTeX_style_sheet.txt'), styFile, 'f');
                fileattrib(styFile, '+w');
            end
        end

        function cleanup(~, sentOptions)
            % Try to remove a possibly empty image directory.
            status = rmdir(sentOptions.imagePath); %#ok<NASGU>
        end

        function launch (~, filePath)
            matlab.desktop.editor.export.ExportUtils.launch(filePath);
        end
    end
end
