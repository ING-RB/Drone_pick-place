classdef ExportDialog < matlab.ui.internal.dialog.PrintExportDialog
    % This function is undocumented and will change in a future release.
    %
    % Copyright 2021-2024 The MathWorks, Inc.
    
    properties
        FileFormatSubscription;
        FileSubscription;
        BrowseSubscription;
        ExportSubscription;
        OverwriteSubscription;
        UnitsSubscription;
        SizeSubscription;
        ContentTypeSubscription;
        
        % Temporarily using these to maintain persistent state
        File;
        Folder;
        ManualDim = false;
        Width;
        Height;
        Units = 'inches';
        ContentType = 'auto';

        % Using this to manage unit conversions
        UnitPos = matlab.graphics.general.UnitPosition;

        % Using these to handle multiple messages
        RefreshingPreview = 0;
        RefreshNeeded = 0;
    end
    
    methods (Static)
        function returnedData = accessFigureHandleDataArray(targetFig, savedFigureSettings, getData)
            % This static function takes and stores the settings specific
            % to figure handles.
            %
            % targetFig- The figure handle that we want to access or store
            % savedFigureSettings- The handle-specific settings we want to
            % save. This is only used when "getData" is set to false.
            % getData- The flag for whether we're storing or taking data
            persistent FigureHandleDataArray;
            % Initialize figure handle struct array if it doesn't exist yet
            if isempty(FigureHandleDataArray)
                startingStruct = struct('fig', [], 'file', [], 'manualDim', [], 'dimensions', []);
                startingArray = startingStruct(false);
                FigureHandleDataArray = startingArray;
            end

            figureHandleArray = FigureHandleDataArray;
            figureHandleIndex = [figureHandleArray.fig] == targetFig;
            if getData
                % Get figure-specific saved settings if available

                % If the array is empty or the figure handle doesn't exist
                % yet, create an empty struct to trigger default values.
                if isempty(figureHandleArray) || all(~figureHandleIndex)
                    returnedData.file = [];
                    returnedData.manualDim = [];
                    returnedData.dimensions = [];
                else
                    returnedData.file = figureHandleArray(figureHandleIndex).file;
                    returnedData.manualDim = figureHandleArray(figureHandleIndex).manualDim;
                    returnedData.dimensions = figureHandleArray(figureHandleIndex).dimensions;
                end
    
                % Also remove any deleted figure handles from the array
                if ~isempty(figureHandleArray)
                    validFigureHandles = isvalid([figureHandleArray.fig]);
                    FigureHandleDataArray = FigureHandleDataArray(validFigureHandles);
                end
            else
                % Save figure-specific settings in the persistent variable

                % If the array is empty or the figure handle doesn't exist
                % yet, add to the end of the array
                if isempty(figureHandleArray) || all(~figureHandleIndex)
                    FigureHandleDataArray(end+1) = savedFigureSettings;
                else
                    FigureHandleDataArray(figureHandleIndex) = savedFigureSettings;
                end
            end
        end
    end

    methods
        function obj = ExportDialog(varargin)
            obj = obj@matlab.ui.internal.dialog.PrintExportDialog(varargin);

            initialContentWarningState = warning('off', 'MATLAB:print:ContentTypeImageSuggested');
            warnContentCleanup = onCleanup(@()warning(initialContentWarningState));
            initialUICompWarningState = warning('off', 'MATLAB:print:ExportappForUIFigureWithUIControl');
            warnUICompCleanup = onCleanup(@()warning(initialUICompWarningState));
            
            obj.FileSubscription = obj.MessageService.subscribe([obj.Channel 'file'],@(msg) obj.updateFile(msg));
            obj.FileFormatSubscription = obj.MessageService.subscribe([obj.Channel 'fileformat'],@(msg) obj.updateFileFormat(msg));
            obj.ExportSubscription = obj.MessageService.subscribe([obj.Channel 'export'],@(msg) obj.exportButtonPushed(msg));
            obj.OverwriteSubscription = obj.MessageService.subscribe([obj.Channel 'overwrite'],@(msg) obj.continueExport(msg));
            obj.ContentTypeSubscription = obj.MessageService.subscribe([obj.Channel 'contentType'],@(msg) obj.updateContentType(msg));
            obj.UnitsSubscription = obj.MessageService.subscribe([obj.Channel 'units'],@(msg) obj.updateUnits(msg));
            obj.SizeSubscription = obj.MessageService.subscribe([obj.Channel 'size'],@(msg) obj.updateSize(msg));
            obj.BrowseSubscription = obj.MessageService.subscribe([obj.Channel 'browse'],@(msg) obj.browse(msg));
            obj.openDialog();
            obj.blockMATLAB();
        end

        function openDialog(obj)
            openDialog@matlab.ui.internal.dialog.PrintExportDialog(obj);
        end
        
        function start(obj, msg)
            obj.IsStarting = true;

            % Get figure-specific settings if they exist
            figureSpecificSettings = matlab.ui.internal.dialog.ExportDialog.accessFigureHandleDataArray(obj.Fig, [], true);
            
            % File & format
            fileName = figureSpecificSettings.file;
            folder = getappdata(groot, 'folder');
            fileFormat = getappdata(groot, 'fileFormat');

            if isempty(folder)
                folder = pwd;
            end
            
            if isempty(fileName)
                fileName = 'Untitled';
            end

            obj.InitialConfig.fileName = fileName;
            obj.InitialConfig.folder = folder;
            obj.InitialConfig.fileFormat = fileFormat;
            
            % For some reason this pause resolves a timing issue
            pause(0.1);
            if ~isempty(fileFormat)
                obj.updateFileFormat(struct('fileExtension', fileFormat, 'unitsChanged', false, 'newUnits', 'inches'));
            end

            % Content type
            contentType = getappdata(groot, 'contentType');
            if ~isempty(contentType)
                obj.InitialConfig.contentType = contentType;
                if ~isempty(fileFormat) && strcmpi(contentType, 'vector') && ...
                        (strcmpi(fileFormat, 'pdf') || strcmpi(fileFormat, 'emf') || strcmpi(fileFormat, 'eps') || strcmpi(fileFormat, 'svg'))
                    obj.MessageService.publish([obj.Channel 'disableResolution'], true);
                end
            end

            % Width, height, units
            manualDim = figureSpecificSettings.manualDim;
            if ~isempty(manualDim)
                obj.ManualDim = manualDim;
            end
            dimensions = figureSpecificSettings.dimensions;
            % Use the dimensions of the graphics object if previous export
            % dialog session did not use manual dimensions
            if ~obj.ManualDim
                if ~isempty(dimensions) && ~isempty(dimensions.units)
                    initialUnits = dimensions.units;
                else
                    initialUnits = obj.Fig.PaperUnits;
                end
                [obj.Width, obj.Height] = matlab.graphics.internal.export.getDefaultExportDimensions(obj.Fig, initialUnits);
                obj.Units = initialUnits;
                obj.InitialConfig.width = obj.Width;
                obj.InitialConfig.height = obj.Height;            
                obj.InitialConfig.units = obj.Units;
            else
                obj.Width = dimensions.width;
                obj.Height = dimensions.height;
                obj.InitialConfig.width = dimensions.width;
                obj.InitialConfig.height = dimensions.height;
                if ~isempty(dimensions.units)
                    obj.InitialConfig.units = dimensions.units;
                    obj.Units = dimensions.units;
                end
            end
            obj.InitialConfig.oldUnits = obj.Fig.PaperUnits;
            % Initialize UnitPos for unit conversions
            obj.UnitPos.ScreenResolution = obj.Fig.ScreenPixelsPerInch;
            obj.UnitPos.Units = obj.Units;
            obj.UnitPos.Position = [0 0 obj.Width obj.Height];

            obj.initializeSharedSettings();
                
            start@matlab.ui.internal.dialog.PrintExportDialog(obj, msg);
        end
        
        function updateFile(obj, msg)
            % User typed a file name (possibly including path info) or folder.
             [pat,name,ext] = fileparts(string(msg));
             
             if isfolder(pat)
                 obj.Folder = pat;
             else
                 fullPathToFile = which(string(msg));
                 if ~isempty(fullPathToFile)
                    [pat,name,ext] = fileparts(fullPathToFile);
                    obj.File = name;
                 else
                    obj.File = name;
                 end
             end
        end

        function updateFileFormat(obj, msg)
            % Cover for scenarios when Units needs to change out of Pixels
            if (msg.unitsChanged)
                obj.updateUnits(msg.newUnits);
            end

            % Handle updating the FormatType property
            switch lower(msg.fileExtension) % Using lower() to make the comparison case-insensitive
                case {'pdf', 'emf', 'eps', 'tiff', 'svg'}
                    obj.FormatType = lower(msg.fileExtension);
                case {'jpeg', 'jpg'}
                    obj.FormatType = 'jpeg';
                otherwise
                    obj.FormatType = 'png';
            end

            % Handle publishing to message service
            if ismember(lower(msg.fileExtension), {'pdf', 'emf', 'eps', 'svg'}) && strcmpi(obj.ContentType, 'vector')
                % For vector content types, always disable the resolution
                obj.MessageService.publish([obj.Channel 'disableResolution'], true);
            else
                % For raster content types including jpeg, jpg, tiff, and
                % the default png, enable resolution based on whether UI
                % components are included
                obj.MessageService.publish([obj.Channel 'disableResolution'], obj.IncludeUIComponents);
            end
            
            obj.refreshPreview();
        end
        
        function updateContentType(obj, msg)
            obj.ContentType = msg;
            if strcmpi(msg, 'vector')
                obj.MessageService.publish([obj.Channel 'disableResolution'], true);
            else
                obj.MessageService.publish([obj.Channel 'disableResolution'], false);
            end
            
            obj.refreshPreview();
        end
        
        function updateUnits(obj, msg)
            % Set the UnitPos Units and Position to the dialog's
            % current values, then convert the values
            obj.UnitPos.Units = obj.Units;
            obj.UnitPos.Position(3) = obj.Width;
            obj.UnitPos.Position(4) = obj.Height;
            obj.UnitPos.Units = msg;
            % Update the dialog's width and height with the converted values
            obj.Units = msg;
            obj.Width = obj.UnitPos.Position(3);
            obj.Height = obj.UnitPos.Position(4);
            obj.MessageService.publish([obj.Channel 'dimensions'], [obj.UnitPos.Position(3) obj.UnitPos.Position(4)]);
        end

        function updateSize(obj, msg)
            obj.ManualDim = true;
            obj.Width = msg(1);
            obj.Height = msg(2);
            
            obj.refreshPreview();
        end
        
        function refreshPreview(obj)
            if obj.IsStarting
                return;
            end

            obj.RefreshNeeded = 1;
            if obj.RefreshingPreview
                return;
            else
                obj.RefreshingPreview = 1;
            end

            while (obj.RefreshNeeded)
                % If the most recent event is in the middle of
                % regenerating the preview file, all other received events 
                % will not regenerate the preview and will only update the 
                % dialog and figure properties. The most recent event will
                % regenerate the preview again if additional changes to the
                % dialog and figure properties are made by other events.
                pause(1);
                obj.RefreshNeeded = 0;
                previewFormat = obj.getPreviewFileExtension;
                
                try
                    exportToFile(obj,  [obj.TempPreviewFilePath '.' previewFormat]);
                catch ME
                    obj.MessageService.publish([obj.Channel 'error'], struct('identifier', ME.identifier, 'message', ME.message));
                    %In situations of errors, we need to set
                    %refreshingPreview to 0 since we return within the
                    %catch. See the problem in g2949119.
                    obj.RefreshingPreview = 0;
                    return;
                end
            end
            obj.RefreshingPreview = 0;

            obj.MessageService.publish([obj.Channel 'generatePreview'], struct('path', obj.TempPreviewURL, 'fileFormat', previewFormat));
        end

        function exportToFile(obj, filepath)
            % Initiate args to pass to exportgraphics
            % Margin is set to 'tight' to emulate exportgraphics cropping
            args = setupExportArguments(obj, true);

            if obj.IncludeUIComponents
                % Note: exportapp does not support .emf, .eps, MATLAB
                % Online, or Web Apps (MATLAB Compiler). Exporting as
                % a PDF file is not supported in the Live Editor.
                exportapp(obj.Fig, filepath);
            else
                exportgraphics(obj.Fig, filepath, args{:});
            end
        end

        function args = setupExportArguments(obj, includeDimensions)
            % Initiate args to pass to exportgraphics
            % Margin is set to 'tight' to emulate exportgraphics cropping
            args = {'ContentType', obj.ContentType, 'Padding', 'tight'};
            if (includeDimensions)
                args = cat(2,args,{'Width', obj.Width, 'Height', obj.Height, 'Units', obj.Units});
            end

            if ~isempty(obj.Resolution)
                args{end+1} = 'Resolution';
                args{end+1} = obj.ResolutionInt;
            end

            if ~isempty(obj.BackgroundColor)
                args{end+1} = 'BackgroundColor';
                args{end+1} = obj.BackgroundColor;
            end

            if ~isempty(obj.ColorSpace)
                % cmyk Colorspace is only supported for EPS file
                % format. Suppress adding the ColorSpace argument if
                % cmyk is specified for some other file format.
                if ~(strcmpi(obj.ColorSpace, 'cmyk') && ~endsWith(filepath, '.eps', 'IgnoreCase', true))
                    args{end+1} = 'Colorspace';
                    args{end+1} = obj.ColorSpace;
                end
            end
        end

        function fileExtension = getPreviewFileExtension(obj)
            % Determine the format the preview file will be created
            fileExtension = obj.FormatType;
            if strcmpi(fileExtension, 'eps') || strcmpi(fileExtension, 'emf') || strcmpi(obj.FormatType, 'svg')
                fileExtension = 'pdf';
            elseif strcmpi(fileExtension, 'tiff')
                fileExtension = 'png';
            elseif strcmpi(fileExtension, 'jpeg')
                fileExtension = 'jpg';
            end
        end
        
        function exportButtonPushed(obj, msg)
            if isfile(msg)
                obj.MessageService.publish([obj.Channel 'error'], ...
                    struct('identifier', 'ExportDialog:fileAlreadyExists', 'message', 'Prompt to overwrite existing file'));
                return;
            else
                obj.continueExport(msg);
            end
        end
        
        function continueExport(obj, msg)
            try
                [path, name, ext] = fileparts(string(msg));
                if ~isfolder(path)
                    obj.MessageService.publish([obj.Channel 'error'], ...
                        struct('identifier', 'ExportDialog:invalidPath', 'message', 'Valid export folder not found'));
                    return;
                else
                    try
                        exportToFile(obj, msg);
                    catch ME
                        obj.MessageService.publish([obj.Channel 'error'], struct('identifier', ME.identifier, 'message', ME.message));
                        return;
                    end
                end

                % After exporting, save the current settings for next time
                % the Export dialog is opened with the same figure
                savedFigureSettings = struct('fig', obj.Fig, 'file', name, 'manualDim', obj.ManualDim, 'dimensions', struct('width', obj.Width, 'height', obj.Height, 'units', obj.Units));
                matlab.ui.internal.dialog.ExportDialog.accessFigureHandleDataArray(obj.Fig, savedFigureSettings, false);
                setappdata(groot, 'folder', path);
                setappdata(groot, 'fileFormat', convertStringsToChars(ext.extractAfter(1))); % Remove the period
                setappdata(groot, 'contentType', obj.ContentType);
                setappdata(groot, 'backgroundColor', obj.BackgroundColor)
                setappdata(groot, 'resolution', obj.ResolutionInt);
                setappdata(groot, 'colorSpace', obj.ColorSpace);
                setappdata(groot, 'includeUIComponents', obj.IncludeUIComponents);
            catch ex
                obj.MessageService.publish([obj.Channel 'error'], struct('identifier', ex.identifier, 'message', ex.message));
            end
            obj.closeWindow;
        end
        
        function browse(obj, msg)
            if obj.Folder
                selPath = uigetdir(obj.Folder);
            else
                selPath = uigetdir(path);
            end
            
            if ~isempty(selPath) && ~isnumeric(selPath)
                obj.Folder = selPath;
                obj.MessageService.publish([obj.Channel 'path'], selPath);
            end
        end

        function closeWindow(obj)
            closeWindow@matlab.ui.internal.dialog.PrintExportDialog(obj);
        end
    end
end

