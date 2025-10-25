classdef Exporter < handle
    % DESCRIPTION - Exporter can be used to export web diagram to PDF
    % (vector graphics) and raster image formats such as PNG, JPG, TIFF...
    %
    % DOCUMENTATION AND KNOWN ISSUES - https://confluence.mathworks.com/display/WDE/WDF+Export+RFA
    properties (Access = {?diagram.editor.print.Exporter, ...
            ?wdftest.DiagramModelTestCase})
        subscription
        window
        filename
        syntax
        editorController
        format
        size
        appIndex
        indexParams
        appCss
        debug (1,1) logical = false;
        readyToPrint (1,1) logical = false; % fitToViewCompleteEvent is dispatched by the client more than once. This ensures we print only once.
        isProcessingJobs (1,1) logical = false;
        hasARunningJob (1,1) logical = false;
        queue  % If export() is called again immediately by the client before the current print process has completed, it will add the request to this queue. 
        error
        noCleanupRequired (1,1) logical = false;
    end
    
    properties (Constant = true, Access = private)
        padding = 300;
        maxSize = 10000;
    end

    methods
        function obj = Exporter(syntax, options)
            arguments
                syntax (1,1) diagram.interface.DiagramSyntax
                options.AppIndex (1,:) string = '/toolbox/diagram/editor/web/export/index.html'
                options.IndexParams (1,:) string = []
                options.AppCss (1,:) char
            end
            
            obj.syntax = syntax;
            obj.appIndex = options.AppIndex;
            obj.indexParams = options.IndexParams;
            if (isfield(options, 'AppCss'))
                obj.appCss = options.AppCss;
            end
        end

        
        function export(obj, filename, options)
            arguments
                obj
                filename (1,:) char {diagram.editor.print.Exporter.mustBeValidPath(filename)}
                options.Format (1,1) string = diagram.editor.print.Exporter.getFileFormat(filename);
                options.Size (1,2) {mustBeNumeric, mustBeInteger, mustBeNonnegative, mustBeLessThanOrEqual(options.Size, 10000)} = obj.calculateSize();
                options.Debug (1,1) logical = false;
            end
            cleanupObj = onCleanup(@() cleanup(obj));
            % Put the request on the queue.
            inputArgs = struct(filename=filename, options=options);
            if isempty(obj.queue)
                obj.queue = [inputArgs];
            else
                obj.queue(end+1) = inputArgs;
            end

            % Exit if a request is currently being processed.
            if obj.isProcessingJobs
                obj.noCleanupRequired = true;
                return;
            end
            
            % Dequeue.
            obj.isProcessingJobs = true;
            while ~isempty(obj.queue)
                inputArgs = obj.queue(1);
                obj.queue(1) = [];
            
                obj.filename = diagram.editor.print.Exporter.rel2abs(inputArgs.filename);
                obj.format = inputArgs.options.Format;
                obj.size = inputArgs.options.Size;
                obj.debug = inputArgs.options.Debug;
            
                obj.print();

                % Wait till the process completes.
                while obj.hasARunningJob
                    pause(0.1);
                end

                % Throw if an error was found.
                if ~isempty(obj.error)
                    rethrow(obj.error);
                end
            end
            
            function cleanup(obj)
                if ~obj.noCleanupRequired
                    obj.hasARunningJob = false;
                    obj.isProcessingJobs = false;
                    obj.error = [];
                    obj.queue = [];
                else
                    obj.noCleanupRequired = false;
                end
            end
        end
    end
    methods (Static = true)
        
        function absPath = rel2abs(filename)
            testPath = strrep(strip(filename), '\', '/');
            rnbits = strsplit(testPath, '/');
            if (testPath(1)=='/') || any(rnbits{1}==':')
                absPath = filename;
            else
                absPath = fullfile(pwd, filename);
            end
        end
        
        function mustBeValidPath(filename)
            filename = diagram.editor.print.Exporter.rel2abs(filename);
            if (isfolder(filename))
                eidType = 'mustBeValidPath:filenameIsFolder';
                msgType = getString(message('diagram_editor_registry:General:FilenameIsFolder'));
                throw(MException(eidType,msgType));
            end
            
            [folder,~, ~] = fileparts(filename);
            if (~isfolder(folder))
                eidType = 'mustBeValidPath:filenameDoesNotExist';
                msgType = getString(message('diagram_editor_registry:General:FilenameDoesNotExist'));
                throw(MException(eidType,msgType));
            end
        end
        
        function ext = getFileFormat(filename)
            [~, ~, ext] = fileparts(filename);
            if ~isempty(ext)
                ext = ext(2:end); % Remove dot from ext.
            else
                eidType = 'diagram_editor_print_Exporter:formatNotSpecified';
                msgType = getString(message('diagram_editor_registry:General:FormatNotSpecified'));
                throw(MException(eidType,msgType));
            end
        end

        function [width, height] = getScreenSize()
            config = pf.display.getConfig(pf.display.getPrimaryScreen);
            width = double(config.availableScreenSize.width);
            height = double(config.availableScreenSize.height);
        end
    end
        
    methods (Access = {?diagram.editor.print.Exporter, ...
            ?wdftest.DiagramModelTestCase})
        function print(obj)
            obj.hasARunningJob = true;
            obj.editorController = diagram.editor.registry.EditorController(obj.syntax, obj.syntax.root.uuid, obj.appIndex);
            obj.subscription = message.subscribe(strcat('/WDF/',obj.editorController.uuid,'/event'), @obj.handleMessage);

            urlToLoad = obj.generateUrl();
            obj.window = matlab.internal.webwindow(urlToLoad, matlab.internal.getDebugPort);
            % Place the window at 0,0 coordinates of the screen
            % This matters for raster image export as it uses
            % getScreenshot web window api which needs the whole window
            % to fit inside the screen.
            % To allow setting the size of the window to the maximum
            % possible width and height, we place the window at the leftmost part of
            % the screen.
            obj.window.Position(1:2) = [0 0]; 
            if obj.debug
                obj.window.show;
                obj.window.executeJS('cefclient.sendMessage("openDevTools");');
            end
            obj.window.PageLoadFinishedCallback = @obj.setsize;
        end
        
        function url = generateUrl(obj)
            url = obj.editorController.url;
            if (~isempty(obj.indexParams))
                params = strjoin(obj.indexParams, '&');
                url = append(url, '&', params);
            end
            connector.ensureServiceOn;
            connector.newNonce;
            url = connector.getUrl(url);
        end
        
        function setsize(obj,~,~)
            % Calculate the width or height if not provided
            size = [obj.size(1) obj.size(2)];
            if any(size == 0)
                calcSize = obj.calculateSize;
                size = (not(logical(size)).*calcSize) + size; % If height or width either or both of them are zero, replace the value with calculated size value.
            end

            [maxWidth, maxHeight] = obj.getMaxPossibleSize();

            maxSize = [maxWidth, maxHeight];
            if any(size > maxSize)
                size = min(size, maxSize);
                warning('diagram_editor_print_Exporter:sizeMustNotBeGreaterThanMaxPossibleSize', ...
                    getString(message('diagram_editor_registry:General:SizeMustNotBeGreaterThanMaxPossibleSize')));
            end
            
            % Dont need to be warned that the window is resizing.
            w(1) = warning('off','cefclient:webwindow:updatePositionMinSize');
            w(2) = warning('off','cefclient:webwindow:updatePositionMaxSize');

            % Restore original warning state on cleanup
            cleanup = onCleanup(@() warning(w));

            obj.setWindowSize(size);
            obj.resetSizeOnWindowsIfNeeded(size);
        end

        % Cannot let window size to be greater than the screen size on
        % windows and linux for raster image formats as getScreenshot API that is
        % used to capture the image does not guarantee proper functioning
        % for this case.
        % g2658347.
        function [width, height] = getMaxPossibleSize(obj)
            if strcmpi(obj.format, diagram.editor.print.ExportFormat.PDF) 
				width = diagram.editor.print.Exporter.maxSize;
                height = diagram.editor.print.Exporter.maxSize;
            else
                [width, height] = diagram.editor.print.Exporter.getScreenSize();
            end
        end

        function setWindowSize(obj, size)
            % Dont need to be warned that the window is resizing.
            wmin = warning('off','cefclient:webwindow:updatePositionMinSize');
            wmax = warning('off','cefclient:webwindow:updatePositionMaxSize');

            obj.window.setMinSize(size);
            obj.window.setMaxSize(size);

            warning(wmin);
            warning(wmax);
        end
        
        % There is a bug in webwindow/Windows where if you set the window
        % size to be larger than the screen size, the window manager
        % shrinks the window size to be less than the screen size. 
        % I dont know why but setting the window size again forces the window
        % manager to set the correct size. g2658347.
        function resetSizeOnWindowsIfNeeded(obj, size)
            if (ispc && any(obj.window.Position(3:4) ~= size))
                obj.setWindowSize(size);
            end
        end

        function size = calculateSize(obj) 
            maxx = [];
            maxy = [];
            minx = [];
            miny = [];
            size = [obj.padding obj.padding];
            d = obj.syntax.root;
            if ~isempty(d.entities)
                for e = d.entities'
                    top = e.getSize.top + e.getPosition.y;
                    left = e.getSize.left + e.getPosition.x;
                    bottom = top + e.getSize.height;
                    right = left + e.getSize.width;
                    if (isempty(maxx) || maxx < right)
                        maxx = right;
                    end
                    if (isempty(maxy) || maxy < bottom)
                        maxy = bottom;
                    end
                    if (isempty(minx) || minx > left)
                        minx = left;
                    end
                    if (isempty(miny) || miny > top)
                        miny = top;
                    end
                end
                size = size + [maxx - minx maxy - miny] + 1; % Adding 1px to account for any rounding error - g2643525
                [maxWidth, maxHeight] = obj.getMaxPossibleSize();
                size = min(size, double([maxWidth maxHeight]));
                size = ceil(size);
            end
        end
        
        function handleMessage(obj, msg)
            switch msg
                case 'diagramLoadCompleteEvent'
                    % Add css file after the diagram has been loaded
                    if (~isempty(obj.appCss))
                        script = ['let link=document.createElement("link");link.rel="stylesheet";link.type="text/css";link.href="' (obj.appCss) '";document.head.append(link)'];
                        obj.window.executeJS(script);
                    end
                    obj.editorController.getCanvas.fitToView();
                    obj.readyToPrint = true;
                case 'fitToViewCompleteEvent'
                    if obj.readyToPrint
                        obj.readyToPrint = false;
                        obj.printToFormat();
                        message.unsubscribe(obj.subscription);
                        obj.hasARunningJob = false;
                    end
            end
        end
        
        function printToFormat(obj)
            obj.appendExtensionIfAbsent();
            % Issue warning if file extension and format provided so not match
            [~, ~, ext] = fileparts(obj.filename);
            if ~strcmpi(ext(2:end), obj.format)
                warning('diagram_editor_print_Exporter:formatMismatch', ...
                    getString(message('diagram_editor_registry:General:FormatMismatch')));
            end
            
            if (strcmp(obj.format, diagram.editor.print.ExportFormat.PDF))
                obj.window.printToPDF(obj.filename);
                obj.closeWindow();
            else
                img = obj.window.getScreenshot();
                obj.closeWindow();
                try
                    imwrite(img, obj.filename, obj.format);
                catch e
                    %Turn off trace for the warning.
                    wasTrace = warning('off', 'backtrace');
                    wasVerbose = warning('off', 'verbose');
                    warning(wasTrace);
                    warning(wasVerbose);
                    obj.error = e;
                end
            end
        end
        
        function closeWindow(obj)
            if (~obj.debug)
                obj.window.close();
            end
        end
        
        function appendExtensionIfAbsent(obj)
            [~, ~, ext] = fileparts(obj.filename);
            if isempty(ext)
                obj.filename = char(obj.filename + "." + obj.format);
            end
        end
    end
end
