classdef PrintDialog < matlab.ui.internal.dialog.PrintExportDialog
    % This function is undocumented and will change in a future release.
    
    properties
        DestinationSubscription;
        PrintSubsciption;
        OrientationSubscription;
        PaperSizeSubscription;
        PlacementSubscription;
        PaperUnitsSubscription;
        CustomPaperSizeSubscription;
        CustomMarginsSubscription;
        
        DefaultPaperPosition;
        DefaultPaperPositionMode;
        DefaultPaperUnits;
        DefaultPaperOrientation;

        Destination;
        Placement;
        PaperType;
        InitialPaperPosition;
        InitialUnits;

        CustomMarginTop;

        % Using these to handle multiple messages
        RefreshingPreview = false;
        RefreshNeeded = false;

        % Using this to handle situations where the new preview is being
        % printed after the dialog is closed
        DialogClosed = false;

        NewPaperPosition;
        NewPaperUnits;
        NewPaperOrientation;
        NewPaperPositionMode;
    end

    properties (Access = private, Constant = true)
        % When paper size is set on the print dialog, the figure PaperType
        % property is updated. When the paper size value is 'custom', we need to set
        % the PaperType property value to '<custom>'.
        % refer geck g2592632.
        CustomPaperType = '<custom>';
        %The printing option provided by MATLAB
        MATLABPrinter = 'MATLAB Print to PDF';
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
                startingStruct = struct('fig', [], 'paperOrientation', [], 'paperUnits', [], 'paperType', [], 'paperSize', [], 'placement', []);
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
                    returnedData.paperOrientation = [];
                    returnedData.paperUnits = [];
                    returnedData.paperType = [];
                    returnedData.paperSize = [];
                    returnedData.placement = [];
                else
                    returnedData.paperOrientation = figureHandleArray(figureHandleIndex).paperOrientation;
                    returnedData.paperUnits = figureHandleArray(figureHandleIndex).paperUnits;
                    returnedData.paperType = figureHandleArray(figureHandleIndex).paperType;
                    returnedData.paperSize = figureHandleArray(figureHandleIndex).paperSize;
                    returnedData.placement = figureHandleArray(figureHandleIndex).placement;
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
        function obj = PrintDialog(varargin)
            obj = obj@matlab.ui.internal.dialog.PrintExportDialog(varargin);

            initialUIWarningState = warning('off','MATLAB:print:ExcludesUIInFutureRelease');
            warnUICleanup = onCleanup(@()warning(initialUIWarningState));
            initialLargeFigureWarningState = warning('off','MATLAB:print:FigureTooLargeForPage');
            warnLargeFigureCleanup = onCleanup(@()warning(initialLargeFigureWarningState));
            invHardCopyWarningState = warning('off','MATLAB:print:InvertHardcopyIgnoredFigureColorUsed');
            warnInvHardCopyCleanup = onCleanup(@()warning(invHardCopyWarningState));

            obj.FormatType = 'pdf';
            obj.DefaultPaperPosition = obj.Fig.PaperPosition;
            obj.DefaultPaperPositionMode = obj.Fig.PaperPositionMode;
            obj.DefaultPaperUnits = obj.Fig.PaperUnits;
            obj.DefaultPaperOrientation = obj.Fig.PaperOrientation;

            obj.DestinationSubscription = obj.MessageService.subscribe([obj.Channel 'destination'],@(msg) obj.adaptToNewDestination(msg));
            obj.PrintSubsciption = obj.MessageService.subscribe([obj.Channel 'print'],@(msg) obj.print(msg));
            obj.OrientationSubscription = obj.MessageService.subscribe([obj.Channel 'orientation'],@(msg) obj.adaptToNewPaperOrientation(msg));
            obj.PaperSizeSubscription = obj.MessageService.subscribe([obj.Channel 'paperSize'],@(msg) obj.adaptToNewPaperSize(msg));
            obj.PlacementSubscription = obj.MessageService.subscribe([obj.Channel 'placement'],@(msg) obj.adaptToNewPlacement(msg));
            obj.PaperUnitsSubscription = obj.MessageService.subscribe([obj.Channel 'paperUnits'],@(msg) obj.adaptToNewPaperUnits(msg));
            obj.CustomPaperSizeSubscription = obj.MessageService.subscribe([obj.Channel 'customPaperSize'],@(msg) obj.adaptToNewCustomPaperSize(msg));
            obj.CustomMarginsSubscription = obj.MessageService.subscribe([obj.Channel 'customMargins'],@(msg) obj.adaptToNewCustomMargins(msg));

            obj.openDialog();
            obj.blockMATLAB();
            drawnow;
        end

        function openDialog(obj)
            openDialog@matlab.ui.internal.dialog.PrintExportDialog(obj);
        end
        
        function start(obj, msg)
            obj.IsStarting = true;
            obj.InitialPaperPosition = obj.Fig.PaperPosition;
            obj.InitialUnits = obj.Fig.PaperUnits;
            [currentPrinter, printers] = findprinters;

            %We want to have 'MATLAB Print to PDF' as an always available
            %option for printer.
            printers{1, end+1} = obj.MATLABPrinter;

            % Get figure-specific settings if they exist
            figureSpecificSettings = matlab.ui.internal.dialog.PrintDialog.accessFigureHandleDataArray(obj.Fig, [], true);
            
            %We always have a default printer in the priority order of
            %Printer from App data, system default, MATLAB Print to PDF
            if isempty(currentPrinter)
                currentPrinter = obj.MATLABPrinter;
            end
            destination = getappdata(groot, 'destination');
            if ~isempty(destination)
                currentPrinter = destination;
            end
            obj.Destination = currentPrinter;
            obj.InitialConfig.currentPrinter = currentPrinter;
            obj.InitialConfig.printers = printers;

            % We do not use gcf when retrieving the figure, since the Print
            % dialog is compatible with both uifigure and figure objects
            % and gcf only applies to active figure objects
            paperOrientation = figureSpecificSettings.paperOrientation;
            paperUnits = figureSpecificSettings.paperUnits;
            paperType = obj.getPaperTypeFromAppData(figureSpecificSettings);
            placement = figureSpecificSettings.placement;

            if ~isempty(paperOrientation)
                obj.Fig.PaperOrientation = paperOrientation;
                obj.InitialConfig.paperOrientation = paperOrientation;
            else
                obj.InitialConfig.paperOrientation = obj.Fig.PaperOrientation;
            end

            if ~isempty(paperUnits)
                obj.Fig.PaperUnits = paperUnits;
                obj.InitialConfig.paperUnits = paperUnits;
            else
                obj.InitialConfig.paperUnits = obj.Fig.PaperUnits;
            end

            if ~isempty(paperType)
                if strcmp(paperType, 'custom')
                    obj.Fig.PaperSize = figureSpecificSettings.paperSize;
                else
                    obj.Fig.PaperType = paperType;
                end
                obj.InitialConfig.paperType = paperType;
            else
                if strcmp(obj.Fig.PaperType, obj.CustomPaperType)
                    obj.InitialConfig.paperType = 'custom';
                else
                    obj.InitialConfig.paperType = obj.Fig.PaperType;
                end
            end
            obj.PaperType = obj.InitialConfig.paperType;

            if ~isempty(placement)
                obj.Placement = placement;
                obj.InitialConfig.placement = obj.getPlacementInitialValue(placement);
                switch (obj.Placement)
                    case('auto')
                        obj.centerFigureOnPaper();
                    case('-bestfit')
                        matlab.graphics.internal.export.calculateBestFit(obj.Fig);
                    case('-fillpage')
                        matlab.graphics.internal.export.calculateFillPage(obj.Fig);
                end
            else
                % Placement property tracks placement state in back end.
                % The "-" is for when passing it in as an argument
                obj.Placement = '-bestfit';
                %------------------------------------------------------
                matlab.graphics.internal.export.calculateBestFit(obj.Fig);
                obj.MessageService.publish([obj.Channel 'margins'], struct(...
                    'left', obj.Fig.PaperPosition(1), ...
                    'top', obj.Fig.PaperSize(2) - obj.Fig.PaperPosition(2) - obj.Fig.PaperPosition(4), ...
                    'width', obj.Fig.PaperPosition(3), ...
                    'height', obj.Fig.PaperPosition(4)));
                %------------------------------------------------------
                % InitialConfig is passed into the dialog when it first
                % starts up to intialize the settings
                obj.InitialConfig.placement = 'bestfit';
            end
            obj.updateCustomMarginTop();

            obj.publishCustomPaperProperties();

            obj.FormatType = 'pdf';

            obj.initializeSharedSettings();

            start@matlab.ui.internal.dialog.PrintExportDialog(obj, msg);
        end

        function adaptToNewPaperOrientation(obj, msg)
            obj.Fig.PaperOrientation = msg.orientation;
            if msg.center
                obj.centerFigureOnPaper();
                obj.updateCustomMarginTop();
            end
            obj.updateAndPublishPaperSizeAndPlacementValues();
            obj.refreshPreview();
        end
        
        function adaptToNewPaperSize(obj, msg)
            if strcmp(msg.paperSize, 'custom')
                obj.PaperType = obj.CustomPaperType;
                return;
            else
                obj.Fig.PaperType = msg.paperSize;
                obj.PaperType = msg.paperSize;
            end

            if msg.center
                obj.centerFigureOnPaper();
                obj.updateCustomMarginTop();
            end
            obj.updateAndPublishPaperSizeAndPlacementValues();
            
            obj.refreshPreview();
        end

        function adaptToNewDestination(obj, msg)
            obj.Destination = msg;
        end
        
        
        function adaptToNewPlacement(obj, msg)
            % Set the Placement property based on the message
            if strcmpi(msg, 'bestfit') || strcmpi(msg, 'fillpage')
                obj.Placement = ['-' msg];
            elseif strcmpi(msg, 'custom')
                obj.Placement = 'custom';
                return;
            elseif strcmpi(msg, 'auto')
                obj.Placement = 'auto';
            end

            switch (msg)
                case('auto')
                    oldUnits = obj.Fig.PaperUnits;
                    obj.Fig.PaperUnits = obj.InitialUnits;
                    obj.Fig.PaperPosition = obj.InitialPaperPosition;
                    obj.Fig.PaperUnits = oldUnits;
                    obj.centerFigureOnPaper();
                case('bestfit')
                    matlab.graphics.internal.export.calculateBestFit(obj.Fig);
                case('fillpage')
                    matlab.graphics.internal.export.calculateFillPage(obj.Fig);
                case('center')
                    % center on page
                    obj.centerFigureOnPaper();
            end

            % Using CustomMarginTop to manually keep track of "Top" margin,
            % while Left/Width/Height can be directly derived from PaperPosition
            obj.updateCustomMarginTop();
            obj.MessageService.publish([obj.Channel 'margins'], struct(...
                'left', obj.Fig.PaperPosition(1), ...
                'top', obj.CustomMarginTop, ...
                'width', obj.Fig.PaperPosition(3), ...
                'height', obj.Fig.PaperPosition(4)));

            obj.refreshPreview();
        end
        
        function adaptToNewPaperUnits(obj, msg)
            obj.Fig.PaperUnits = msg;
            obj.NewPaperUnits = obj.Fig.PaperUnits;
            obj.NewPaperPosition = obj.Fig.PaperPosition;
            obj.updateCustomMarginTop();
            obj.publishCustomPaperProperties();
        end
        
        function adaptToNewCustomPaperSize(obj, msg)
            obj.Fig.PaperSize = [msg.width msg.height];

            if msg.center
                obj.centerFigureOnPaper();
                obj.updateCustomMarginTop();
            end
            obj.updateAndPublishPaperSizeAndPlacementValues();

            obj.refreshPreview();
        end
        
        function adaptToNewCustomMargins(obj, msg)
            obj.CustomMarginTop = msg.top;
            obj.Fig.PaperPosition = [ ...
                msg.left, ...
                obj.Fig.PaperSize(2)-obj.CustomMarginTop-msg.height, ...
                msg.width, ...
                msg.height];
            if msg.center
                obj.centerFigureOnPaper();
                obj.updateCustomMarginTop();
                obj.MessageService.publish([obj.Channel 'margins'], struct(...
                'left', obj.Fig.PaperPosition(1), ...
                'top', obj.CustomMarginTop, ...
                'width', obj.Fig.PaperPosition(3), ...
                'height', obj.Fig.PaperPosition(4)));
            end
            obj.refreshPreview();
        end
        
        function publishCustomPaperProperties(obj)
            obj.MessageService.publish([obj.Channel 'paperSize'], struct(...
                'width', obj.Fig.PaperSize(1), ...
                'height', obj.Fig.PaperSize(2)));
            obj.MessageService.publish([obj.Channel 'margins'], struct(...
                'left', obj.Fig.PaperPosition(1), ...
                'top', obj.Fig.PaperSize(2)-obj.Fig.PaperPosition(2)-obj.Fig.PaperPosition(4), ...
                'width', obj.Fig.PaperPosition(3), ...
                'height', obj.Fig.PaperPosition(4)));
        end
        
        function refreshPreview(obj)
            obj.NewPaperUnits = obj.Fig.PaperUnits;
            obj.NewPaperPosition = obj.Fig.PaperPosition;
            obj.NewPaperOrientation = obj.Fig.PaperOrientation;
            obj.NewPaperPositionMode = obj.Fig.PaperPositionMode;
            if obj.IsStarting
                return;
            end

            obj.RefreshNeeded = true;
            if obj.RefreshingPreview
                return;
            else
                obj.RefreshingPreview = true;
            end

            while (obj.RefreshNeeded)
                % If the most recent event is in the middle of
                % regenerating the preview file, all other received events 
                % will not regenerate the preview and will only update the 
                % dialog and figure properties. The most recent event will
                % regenerate the preview again if additional changes to the
                % dialog and figure properties are made by other events.
                pause(1);
                obj.RefreshNeeded = false;

                opts.Handle = obj.Fig;
                opts.FileName = obj.TempPreviewFilePath;
                opts.Format = obj.FormatType;
                opts.ColorSpace = obj.ColorSpace;
                opts.Resolution = obj.ResolutionInt;
                opts.BackgroundColor = obj.BackgroundColor;

                matlab.graphics.internal.export.generatePrintPreview(opts);

                obj.Fig.PaperUnits = obj.NewPaperUnits;
                obj.Fig.PaperPosition = obj.NewPaperPosition;
                obj.Fig.PaperOrientation = obj.NewPaperOrientation;
                obj.Fig.PaperPositionMode = obj.NewPaperPositionMode;
            end
            obj.RefreshingPreview = false;

            if (obj.DialogClosed)
                obj.restorePaperProperties();
            end

            obj.MessageService.publish([obj.Channel 'generatePreview'], struct('path', obj.TempPreviewURL, 'fileFormat', obj.FormatType));
        end
        
        function print(obj, msg)
            try
                args = {};
                % 'custom' and 'auto' are NOT valid arguments to print function
                if strcmp(obj.Placement, '-bestfit') || strcmp(obj.Placement, '-fillpage')
                   args{end+1} = obj.Placement;
                end
                if ~isempty(obj.Resolution)
                   args{end+1} = obj.Resolution;
                end
                destination = strcat('-P',msg);

                % save current background color, unless it is 'auto'
                if ~strcmpi(obj.BackgroundColor, 'auto') 
                    obj.Fig.Color_I = obj.BackgroundColor;
                    % Make the ColorMode 'manual' so that the background color avoids
                    % using the theme default color when background color is not 'auto'
                    obj.Fig.ColorMode = 'manual';
                end

                % If the color space is color, use -dprnc
                % If the color space is gray, use -dprn
                if strcmp(obj.ColorSpace, 'rgb')
                    colorSpace = '-dprnc';
                elseif strcmp(obj.ColorSpace, 'gray')
                    colorSpace = '-dprn';
                end

                try
                    %MATLAB Print to PDF needs to be handled separately
                    %since our internal print system doesn't recognize it
                    %as a printer userpath vs pwd
                    %case when 'MATLAB Print to PDF' is selected
                    if strcmp(msg, obj.MATLABPrinter)
                         filter = {'*.pdf'};
                         
                         figObjName = obj.Fig.Name;
                         figNumber = "";
                         if ~isempty(obj.Fig.Number)
                            figNumber = string(obj.Fig.Number);
                         end
                         %Default name of the pdf file in the save dialog
                         %is the name of the figure, if exists
                         %otherwise, it is based on figure number
                         %If no figure number is available, it is just
                         %'figure'
                         onlyFileName = "figure" + figNumber;
                         if ~isempty(figObjName)
                             onlyFileName = figObjName;
                         end
                         fileNameWithExtension = onlyFileName + ".pdf";
                         defaultPathAndName = fullfile(pwd, fileNameWithExtension);
                         [filename, selectedDestination] = uiputfile(filter, obj.MATLABPrinter, defaultPathAndName);
                         %uiputfile returns 0 if a user cancels the saving
                         if ~isequal(filename, 0)
                             savingPath =  fullfile(selectedDestination, filename);

                             opts.Handle = obj.Fig;
                             opts.FileName = savingPath;
                             opts.Format = obj.FormatType;
                             opts.ColorSpace = obj.ColorSpace;
                             opts.Resolution = obj.ResolutionInt;
                             opts.BackgroundColor = obj.BackgroundColor;
            
                             matlab.graphics.internal.export.generatePrintPreview(opts);
                         else
                             return;
                         end
                    %If selected printer is not 'MATLAB Print to PDF' and
                    %there are args, pass to the print command called
                    %without flags
                    elseif ~isempty(args)
                         print(args{:},obj.Fig, destination, colorSpace);
                    %If selected printer is not 'MATLAB Print to PDF',
                    %neither the args are available, call print without
                    %args and without flags
                    else
                         print(obj.Fig, destination, colorSpace);
                    end 
                catch ME
                    obj.MessageService.publish([obj.Channel 'error'], struct('identifier', ME.identifier, 'message', ME.message));
                    obj.resetColor();
                    return;
                end

                obj.resetColor();

                % After printing, save the current settings for next time
                % the Print dialog is opened with the same figure
                savedFigureSettings = struct('fig', obj.Fig, 'paperOrientation', obj.Fig.PaperOrientation, 'paperUnits', obj.Fig.PaperUnits, 'paperType', obj.PaperType, 'paperSize', obj.Fig.PaperSize, 'placement', obj.Placement);
                matlab.ui.internal.dialog.PrintDialog.accessFigureHandleDataArray(obj.Fig, savedFigureSettings, false);
                setappdata(groot, 'destination', msg);
                setappdata(groot, 'backgroundColor', obj.BackgroundColor);
                setappdata(groot, 'resolution', obj.ResolutionInt);
                setappdata(groot, 'includeUIComponents', obj.IncludeUIComponents);
                setappdata(groot, 'colorSpace', obj.ColorSpace);

                obj.closeWindow;
            catch ex
                obj.MessageService.publish([obj.Channel 'error'], struct('identifier', ex.identifier, 'message', ex.message));
            end
        end
        
        function closeWindow(obj)
            obj.restorePaperProperties();
            obj.DialogClosed = true;
            
            obj.Placement = '';
            
            closeWindow@matlab.ui.internal.dialog.PrintExportDialog(obj);
        end

        function restorePaperProperties(obj)
            if (isvalid(obj.Fig))
                obj.Fig.PaperUnits = obj.DefaultPaperUnits;
                obj.Fig.PaperPosition = obj.DefaultPaperPosition;
                obj.Fig.PaperPositionMode = obj.DefaultPaperPositionMode;
                obj.Fig.PaperOrientation = obj.DefaultPaperOrientation;
            end
        end
    end

    methods (Access = private)
        function paperType = getPaperTypeFromAppData(obj, figureSpecificSettings)
            % If the figure PaperType property value is '<custom>', convert
            % it to 'custom' before sending to client.
            paperType = figureSpecificSettings.paperType;
            if strcmp(paperType, obj.CustomPaperType)
                paperType = 'custom';
            end
        end

        function placementInitialVal = getPlacementInitialValue(obj, placement)
            placementInitialVal = placement;
            % remove the '-' in placement when value is '-bestfit' or
            % '-fillpage'
            if strcmp(placement, '-bestfit') || strcmp(placement, '-fillpage')
                placementInitialVal = placement(2:end);
            end
        end

        function updateAndPublishPaperSizeAndPlacementValues(obj)
            % Update PaperPosition based on current placement settings
            % Using CustomMarginTop to manually keep track of custom "Top" margin,
            % while Left/Width/Height can be directly derived from PaperPosition
            switch (obj.Placement)
                case('custom')
                    % We want to update the bottom margin of PaperPosition based
                    % on the current displayed value of "CustomMarginTop"
                    obj.Fig.PaperPosition = [
                        obj.Fig.PaperPosition(1), ...
                        obj.Fig.PaperSize(2) - obj.CustomMarginTop - obj.Fig.PaperPosition(4), ...
                        obj.Fig.PaperPosition(3), ...
                        obj.Fig.PaperPosition(4)];
                case('auto')
                    obj.centerFigureOnPaper();
                case('-bestfit')
                    matlab.graphics.internal.export.calculateBestFit(obj.Fig);
                case('-fillpage')
                    matlab.graphics.internal.export.calculateFillPage(obj.Fig);
            end
            obj.updateCustomMarginTop();
            
            % Update paper size and placement values on client
            obj.publishCustomPaperProperties();
        end

        function centerFigureOnPaper(obj)
            xPosition = (obj.Fig.PaperSize(1) - obj.Fig.PaperPosition(3)) / 2;
            yPosition = (obj.Fig.PaperSize(2) - obj.Fig.PaperPosition(4)) / 2;
            obj.Fig.PaperPosition = [
                xPosition, ...
                yPosition, ...
                obj.Fig.PaperPosition(3), ...
                obj.Fig.PaperPosition(4)];
        end

        function updateCustomMarginTop(obj)
            obj.CustomMarginTop = obj.Fig.PaperSize(2) - obj.Fig.PaperPosition(2) - obj.Fig.PaperPosition(4);
        end
    end
end