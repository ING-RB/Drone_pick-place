classdef (Sealed) DOCXExporter < matlab.desktop.editor.export.RtcExporter
    %matlab.desktop.editor.export.DOCXExporter Exports an RTC document with given ID to DOCX.
    
    % Inherits the main export method from RtcExporter.
    %       result = DOCXExporter.export(editorId, options)
    % where options is a struct of name/value pairs.
    %
    % This exporter respects the following options. All are optional.
    %   Destination:  The path to the target file.
    %   OpenExportedFile:   If true, it opens the exported DOCX file in the default
    %                 application (e.g. MS Word). This requires Destination to be set.
    % All other options are silently passed through.
    % Returns: The path to the .docx file.
    %
    % Example usage:
    %   exp = matlab.desktop.editor.export.DOCXExporter;
    %   filePath = exp.export('123456', struct('Destination', 'path/to/file.docx'))
    %
    %   opts.Destination = 'path/to/file.docx';
    %   opts.OpenExportedFile = true;
    %   exp.export('123456', opts)
    %
    % This class shouldn't be used directly.
    % Better use matlab.desktop.editor.exportDocument
    % or matlab.desktop.editor.internal.exportDocumentByID
    
    %   Copyright 2020-2021 The MathWorks, Inc.
    
    properties (GetAccess = protected, SetAccess = private, Hidden = true)
        rtcExportInternalFormat = 'docx';
    end
    
    methods
        
        function newoptions = setup(~, oldoptions)
            newoptions = oldoptions;
            matlab.desktop.editor.export.ExportUtils.assertHasDestination(oldoptions);
            if exist(newoptions.Destination, 'file')
                try
                    delete(newoptions.Destination);
                catch me
                    throwAsCaller(me);
                end
            end
            if ~isfield(newoptions, 'figurePath')
                mTemp = tempname;
                mkdir(mTemp)
                figurePath = [mTemp filesep];
                newoptions.figurePath = figurePath;
            end
        end
        
        function cleanup(~, sentOptions)
            status = rmdir(sentOptions.figurePath, 's'); %#ok<NASGU>
        end
        
        function result = handleResponse(~, ~, options)
            result = options.Destination;
        end
        
        function launch (~, filePath)
            uiopen(filePath, true);
        end
    end
end
