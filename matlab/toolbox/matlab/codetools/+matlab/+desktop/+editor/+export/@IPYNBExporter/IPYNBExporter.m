classdef (Sealed) IPYNBExporter

% IPYNBExporter is called by the function exportDocumentByID.
%
% Note: 
% IPYNBExporter is not a native exporter and therefore not based 
% on RtcExporter. However, we follow the Interface for consistency.
% I.e. having export() as the main entry point which takes care of
% setup, cleanup and launch.
%
% Copyright 2022-2025, The MathWorks, Inc.

    properties (GetAccess = protected, SetAccess = private, Hidden = true)
        rtcExportInternalFormat = 'ipynb';
        markdownExporter = matlab.desktop.editor.export.MarkdownExporter;
    end

    methods
        function result = export(obj, rtcId, options)
            % Save original destination and set it for intermediate 
            % Markdown Export.
            ipynbDestination = options.Destination;
            options.Destination =  tempname + ".md";

            % Save original OpenExportedFile and switch off for
            % intermediate Markdown Export.
            openExportedIpynb = false;
            if isfield(options, 'OpenExportedFile')
                openExportedIpynb = options.OpenExportedFile;
            end
            options.OpenExportedFile = false;
            
            newOptions = obj.setup(options);
            
            % Register cleanup
            cleanup = onCleanup(@() obj.cleanup(newOptions)); 
            
            % Markdown export needs IPYNBDestination.
            newOptions.IPYNBDestination = ipynbDestination;
            mdFile = obj.markdownExporter.export(rtcId, newOptions);
            
            newOptions.MarkdownDestination = mdFile;
            result = matlab.codetools.markdown2ipynb(newOptions);
            
            if openExportedIpynb ...
                    && isfile(result)
                obj.launch(result);
            end
        end
        
        function options = setup(~, oldoptions)
            options = oldoptions;
            
            % Setting options for markdown export.
            options.AcceptHTML  = true;

            if ~isfield(options, "IncludeOutputs")
                options.IncludeOutputs = true;
            end
            if ~isfield(options, "MarkdownFormat")
                options.MarkdownFormat = "github_math";
            end
            if ~isfield(options, "ProgrammingLanguage")
                options.ProgrammingLanguage = "matlab";
            end
            if ~isfield(options, "EmbedImages")
                options.EmbedImages = true;
            end
        end

        function cleanup(~, ~)
            % Usually, this is the place to delete temporary files
            % but markdown2ipynb already took care of that.
        end

        function launch (~, filePath)
            matlab.desktop.editor.export.ExportUtils.launch(filePath);
        end

    end % methods
end % classdef
