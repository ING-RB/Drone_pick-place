classdef DesktopFigureService < appdesigner.internal.application.figure.FigureService
    % DesktopFigureService Object to interact with the running figure when
    % in the Desktop
    
    % Copyright 2018-2024 The MathWorks, Inc.
    
    methods
        function captureScreenshot(~, appInstance, appFullFileName)
            % Captures the screenshot of the running app and saves to disk
            
            % If the app is deleted, closed, etc... do not try to find its
            % figure
            if(isempty(appInstance) || ~isvalid(appInstance))
                return;
            end
            
            function asyncCapture()
                % Make sure app is fully rendered and the window is
                % created before proceeding.
                drawnow;
                
                try
                    appFigure = appdesigner.internal.service.AppManagementService.getFigure(appInstance);

                    if isempty(appFigure)
                        return;
                    end

                    % Capture the screenshot
                    frame = getframe(appFigure);

                    fileFormat = appdesigner.internal.serialization.util.getFileFormatByExtension(appFullFileName);
                    if strcmp(fileFormat, appdesigner.internal.serialization.FileFormat.Text)
                        % Format is plain text

                        dataURI = appdesigner.internal.application.AppThumbnailUtils.createAppThumbnailDataURI(frame.cdata);

                        fileContent = appdesigner.internal.cacheservice.readAppFile(char(appFullFileName));

                        % Replace thumbnail value
                        pattern = "(<Thumbnail autoCapture='true'>)(.*?)(</Thumbnail>)";
                        fileContent = regexprep(fileContent, pattern, ['$1' dataURI '$3']);

                        fid = fopen(appFullFileName, 'w', 'n', 'UTF-8');
                        c = onCleanup(@()fclose(fid));

                        fwrite(fid, fileContent); 
                    else
                        % Format is binary

                        % Convert frame data to byte array for comparison
                        frameBytes = appdesigner.internal.application.ImageUtils.getBytesFromCDataRGB(frame.cdata, 'png');

                        % Get screenshot inside the MLAPP file
                        [screenshotBytes, ~] = appdesigner.internal.serialization.getAppScreenshot(appFullFileName);

                        if numel(frameBytes) ~= numel(screenshotBytes) || ...
                                ~any(eq(frameBytes, screenshotBytes))
                            % Write the screenshot to the MLAPP file
                            fileWriter = appdesigner.internal.serialization.FileWriter(appFullFileName);
                            fileWriter.writeAppScreenshot(frameBytes);
                        end
                    end
                catch ex
                    % no-op
                    % avoid showing error message or interfering with app running
                    % since screen capturing is not an essential step for app running.
                end
            end

            appdesigner.internal.async.AsyncTask(@asyncCapture).run();
        end
        
        function bringToFront(~, appInstance)
            % If the app is deleted, closed, etc... do not try to find its
            % figure            
            if(isempty(appInstance) || ~isvalid(appInstance))
                return;
            end
            
            % Find the figure for the running app and show
            appFigure = appdesigner.internal.service.AppManagementService.getFigure(appInstance);
            figure(appFigure);            
        end
    end    
end
