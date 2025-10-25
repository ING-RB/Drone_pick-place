classdef (Sealed) HTMLExporter < matlab.desktop.editor.export.RtcExporter
    %matlab.desktop.editor.export.HTMLExporter Exports an RTC document with given ID to HTML.

    % Inherits the main export method from RtcExporter.
    %       result = HTMLExporter.export(editorId, options)
    % where options is a struct of name/value pairs.
    %
    % This exporter respects the following options. All are optional.
    %   Destination:  The path to the target file.
    %   OpenExportedFile:   If true, it opens the exported HTML file in the default
    %                 web browser. This requires Destination to be set.
    %   MATLABRelease: A relese information which goes to the HTML meta data.
    %                  If not given, the output of version('-release') is used.
    % All other options are silently passed through.
    % Returns: If 'Destination' is set, it returns that path, Otherwise the HTML code is returned.
    %
    % Example usage:
    %   exp = matlab.desktop.editor.export.HTMLExporter;
    %   filePath = exp.export('123456', struct('Destination', 'path/to/file.html'))
    %   htmlString = exp.export('123456')
    %
    %   opts.Destination = 'path/to/file.html';
    %   opts.MATLABRelease = 'My personal MATLAB build 123';
    %   opts.OpenExportedFile = true;
    %   exp.export('123456', opts)
    %
    % This class shouldn't be used directly.
    % Better use matlab.desktop.editor.exportDocument
    % or matlab.desktop.editor.internal.exportDocumentByID

    %   Copyright 2020-2024 The MathWorks, Inc.

    properties (GetAccess = protected, SetAccess = private, Hidden = true)
        rtcExportInternalFormat = 'html';
    end

    methods

        function newoptions = setup(~, oldoptions)
            newoptions = matlab.desktop.editor.export.ExportUtils.fillMATLABRelease(oldoptions);
            generateFigureAnimationVideo = (isfield(newoptions, 'GenerateFigureAnimationVideo') && newoptions.GenerateFigureAnimationVideo);
            if ~isfield(newoptions, 'figurePath') && ~isfield(newoptions, 'embeddedImages')
                mTemp = tempname;
                mkdir(mTemp)
                figurePath = [mTemp filesep];
                newoptions.figurePath = figurePath;
                if generateFigureAnimationVideo
                    if isfield(newoptions, 'MediaLocation') && exist(newoptions.MediaLocation, 'dir')
                        mediaLocation = newoptions.MediaLocation;
                    else
                        [path, filename, ~] = fileparts(fullfile(char(oldoptions.Destination)));
                        mediaLocation = fullfile(path, [filename '_media']);
                    end
                    if ~exist(mediaLocation, 'dir')
                        mkdir(mediaLocation);
                    end
                    newoptions.MediaLocation = [strrep(mediaLocation, '\', '/') '/'];
                end
            elseif isfield(newoptions, 'embeddedImages') && newoptions.embeddedImages == 0
                if isfield(oldoptions, 'figurePath')
                    figurePath = oldoptions.figurePath;
                    if (startsWith(oldoptions.figurePath, "."))
                        path = fileparts(fullfile(char(oldoptions.Destination)));
                        figurePath = fullfile(path, oldoptions.figurePath);
                    end
                else
                    [path, filename, ~] = fileparts(fullfile(char(oldoptions.Destination)));
                    figurePath = fullfile(path, [filename '_media']);
                end

                % Default image path.
                [dpath, name] = fileparts(newoptions.Destination);
                dpath = fullfile(dpath, name + "_media");
                % Normalize image path, but don't override original image path.
                [ipath, name, ext] = fileparts(string(figurePath));
                ipath = fullfile(ipath, name + ext);
                % Now check if default image path and image path are the same.
                if strcmp(dpath, ipath)
                    % Default image path is used. Delete the folder.
                    if exist(figurePath, 'dir')
                        rmdir(figurePath, 's')
                    end
                    mkdir(figurePath);
                 else
                    % Custom image path is used. Do not delete the folder!
                    % Existing files in figurePath are overwritten.
                    if ~exist(figurePath, 'dir')
                       mkdir(figurePath);
                    end
                 end

                newoptions.imagePath = [strrep(figurePath, '\', '/') '/'];
            end
        end

        function result = handleResponse(obj, responseData, sentData)
            if ~isfield(sentData, 'Destination')
                % If there is no destination, return the HTML content.
                result = responseData.content;
                return;
            end
            result = obj.writeToFile(sentData.Destination, responseData.content);
        end

        function launch (~, filePath)
            web(filePath, '-browser')
        end

        function cleanup(~, sentOptions)
            if ~isfield(sentOptions, 'embeddedImages')
                status = rmdir(sentOptions.figurePath, 's'); %#ok<NASGU>
            end
        end
    end
end
