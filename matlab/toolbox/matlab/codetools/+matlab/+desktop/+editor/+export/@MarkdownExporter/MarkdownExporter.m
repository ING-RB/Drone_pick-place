classdef (Sealed) MarkdownExporter
% MarkdownExporter is called by the function exportDocumentByID.
%
% Note:
% MarkdownExporter is not a native exporter and therefore not based
% on RtcExporter. However, we follow the Interface for consistency.
% I.e. having export() as the main entry point which takes care of
% setup, cleanup and launch.

%   Copyright 2022-2024 The MathWorks, Inc.
    properties (GetAccess = protected, SetAccess = private, Hidden = true)
        rtcExportInternalFormat = 'markdown';
        latexExporter = matlab.desktop.editor.export.LaTeXExporter;
        ExportUtils = matlab.desktop.editor.export.ExportUtils;
    end

    methods
        function result = export(obj, rtcId, options)
            % Save original destination and set it for intermediate
            % LaTeX Export.
            markdownDestination = options.Destination;
            options.Destination = tempname + ".tex";

            % Save original OpenExportedFile and switch off for
            % intermediate LaTeX Export.
            openExportedMarkDown = false;
            if isfield(options, 'OpenExportedFile')
                openExportedMarkDown = options.OpenExportedFile;
            end
            options.OpenExportedFile = false;

            % Adapt options
            newOptions = obj.setup(options);
            FigureFormat = newOptions.FigureFormat;
            if newOptions.Run && newOptions.FigureFormat == "jpeg"
                newOptions.FigureFormat = "png";
            end
            folder = obj.ExportUtils.imageFolder(newOptions.Destination);
            newOptions.imagePath = folder; newOptions.figurePath = folder;

            % Register cleanup
            cleanup = onCleanup(@() obj.cleanup(newOptions));

            % Create TeX file
            texFile = obj.latexExporter.export(rtcId, newOptions);

            % Restore options in a way convertLaTeX2Markdown expects it.
            newOptions.Destination = texFile;
            newOptions.MarkdownDestination = markdownDestination;
            newOptions.Launch = false;
            newOptions.FigureFormat = FigureFormat;
            % Begin New
            if isfield(options, "imagePath")
                newOptions.imagePath = options.imagePath;
                newOptions.figurePath = options.figurePath;
            end
            % End New

            result = convertLaTeX2Markdown(newOptions);

            if openExportedMarkDown ...
                    && isfile(result)
                obj.launch(result);
            end
        end

        function options = setup(~, oldoptions)
            options = oldoptions;
            if ~isfield(oldoptions, "Run")
                options.Run = false;
            end
            % For LaTeX
            if ~isfield(oldoptions, "FigureFormat")
                options.FigureFormat = 'png';
            end
            if ~isfield(oldoptions, "FigureResolution") && ~options.Run
                options.FigureResolution = 0;
            end

            % For Markdown
            if ~isfield(oldoptions, "MoveImages")
                options.MoveImages = true;
            end
            if ~isfield(oldoptions, "IncludeOutputs")
                options.IncludeOutputs = true;
            end
            if ~isfield(oldoptions, "MarkdownFormat")
                options.MarkdownFormat = "github";
            end
            if ~isfield(oldoptions, "AcceptHTML")
                options.AcceptHTML = false;
            end
            if ~isfield(oldoptions, "EmbedImages")
                options.EmbedImages = false;
            end
            if ~isfield(oldoptions, "RenderLaTeXOnline")
                options.RenderLaTeXOnline = "off";
            end
        end

        function cleanup(~, ~)
            % Usually, this is the place to delete the temporary TeX files
            % but convertLaTeX2Markdown already took care of that.
        end

        function launch (~, filePath)
           matlab.desktop.editor.export.ExportUtils.launch(filePath);
        end

    end % methods
end % classdef
