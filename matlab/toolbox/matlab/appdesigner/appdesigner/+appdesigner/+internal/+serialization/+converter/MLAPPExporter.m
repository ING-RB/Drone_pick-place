classdef MLAPPExporter < handle
    %MLAPPEXPORTER A class to export an AppModel's appcode to .m

    % Copyright 2018 The MathWorks, Inc.

    properties (Access = 'private')
        Filepath = ''
        Options = {}
    end

    methods (Access = 'public')

        function obj = MLAPPExporter(filepath, options)
            % MLAPPEXPORTER constructor - takes the destination filepath
            % and the client options as arguments

            obj.Filepath = filepath;
            obj.Options = options;
        end

        function ExportAppCode (obj, generatedCode)
            % EXPORTAPPCODE - entry to export an appModel's appcode to
            % file, filepath is the full filepath anywhere on disk, options
            % contains any additional data passed from the client.

            try
                obj.validateFileExtension();
                CloseExistingDoc(obj);
                fid = fopen(obj.Filepath, 'w', 'n', 'utf-8');
                if (fid < 0)
                    error(message('MATLAB:appdesigner:appdesigner:NotWritableLocation', obj.Filepath));
                else
                    fileCleanup = onCleanup(@()fclose(fid));
                    fprintf(fid, '%s', obj.getGeneratedCodeForExport(generatedCode));
                    edit(obj.Filepath);
                end
            catch e
                rethrow(e);
            end
        end

        function CloseExistingDoc (obj)
            % CLOSEEXISTINGDOC - determine if the document/location the
            % user is attempting to write to is already open in the editor,
            % if so close it to prevent MATLAB editor from creating an
            % untitled document.

            if matlab.desktop.editor.isOpen(obj.Filepath)
                doc = matlab.desktop.editor.findOpenDocument(obj.Filepath);
                if ~isempty(doc)
                    doc.close();
                end
            end
        end

        function generatedCodeForExport = getGeneratedCodeForExport (obj, generatedCode)
            % GETGENERATEDCODEFOREXPORT - prepares the appModel's appcode
            % for export. The client has already synchronized the generated
            % code, it is up to date and ready to export.

            generatedCodeForExport = obj.getGeneratedCode(generatedCode);
            
            % ensure windows is using CRLF line feeds
            if strcmp(computer('arch'), 'win64')
                generatedCodeForExport = regexprep(generatedCodeForExport, '(\n)', '\r\n');
            end
        end
        
        function updatedGeneratedCode = getGeneratedCode(obj, generatedCode)
            % GETGENERATEDCODE - update the generated code with new app name

            [~, filename, ~] = fileparts(obj.Filepath);
            updatedGeneratedCode = generatedCode;

            % check if filename and class name are different
            if ~strcmp(filename, obj.Options.originalName)
                % swap class name with the exported filename
                updatedGeneratedCode = strrep(generatedCode, ...
                    ['classdef ', obj.Options.originalName], ...
                    ['classdef ', filename]);
                
                % swap help comment name with the exported filename
                updatedGeneratedCode = strrep(updatedGeneratedCode, ...
                    ['%', upper(obj.Options.originalName)], ...
                    ['%', upper(filename)]);

                % swap constructor name with the exported filename
                updatedGeneratedCode = strrep(updatedGeneratedCode, ...
                    ['function app = ', obj.Options.originalName], ...
                    ['function app = ', filename]);
            end
        end

    end

    methods (Access = private)

        function validateFileExtension(obj)
            % Make sure the exported file has .m as the extension.
            % Compare without regard to case as the Editor lets users
            % save .M files.
            defaultFileExt = '.m';
            [~, ~, ext] = fileparts(obj.Filepath);

            if ~strcmpi(ext, defaultFileExt)
                error(message('MATLAB:appdesigner:appdesigner:InvalidExportFileExtension'));
            end
        end
    end

end
