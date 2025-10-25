classdef (Sealed, Abstract) AppThumbnailUtils < handle
    % APPTHUMBNAILUTILS - Collection of functions for retrieving and writing
    % app thumbnail

    % Copyright 2024 The MathWorks, Inc.

    methods(Static)

        function dataURI = getThumbnailDataURI(appFullFileName)
            % Gets the app thumbnail screenshot contained in the app file
            % and returns it as a base64 encoded data URI.
            % Returns empty ([]) if the app has no screenshot.
            
            metadataReader = mlapp.internal.MLAPPMetadataReader(appFullFileName);
            [screenshotBytes, screenshotFormat] = metadataReader.readMLAPPScreenshot();
            dataURI = appdesigner.internal.application.ImageUtils.getImageDataURIFromBytes(screenshotBytes, screenshotFormat);
        end

        function dataURI = createAppThumbnailDataURI(screenshotCdataOrPath)
            % Creates a base64 data URI for the provided screenshot image
            % The input can be an RGB cdata image or a path to an image
            % file
            %
            % The returned base64 image will be a jpg & resized to fit 
            % within 220x165 px to minimize the size of the base64 string

            if ischar(screenshotCdataOrPath)
                % image is a file
                im = imread(screenshotCdataOrPath);
            else
                % image is RGB cdata image
                im = screenshotCdataOrPath;
            end

            sz = size(im);

            % Resize so that image fits within 220x165 (width x height)
            if sz(1) > sz(2) && sz(1) > 165 % height (rows) > width (cols) and height > 165
                im = imresize(im, [165, NaN]);
            elseif sz(2) > sz(1) && sz(2) > 220 % width (cols) is > height (rows) and width > 220
                im = imresize(im, [NaN, 220]);
            else
                % don't resize as image is within 220x165
            end

            bytes = appdesigner.internal.application.ImageUtils.getBytesFromCDataRGB(im, 'jpg');
            dataURI = appdesigner.internal.application.ImageUtils.getImageDataURIFromBytes(bytes, 'jpg');
        end

        function sectionStr = createThumbnailAppendixSectionStr(appFullFileName, screenshotMode, screenshotCdataOrPath)

            switch screenshotMode
                case 'auto'
                    autoCapture = 'true';
                    try
                        thumbnailURI = appdesigner.internal.application.AppThumbnailUtils.getThumbnailDataURI(appFullFileName);
                    catch
                        % App file doesn't yet exist or there was some
                        % other issue trying to get the thumbnail.
                        thumbnailURI = '';
                    end
                case 'manual'
                    autoCapture = 'false';
                    try
                        if isempty(screenshotCdataOrPath)
                            thumbnailURI = appdesigner.internal.application.AppThumbnailUtils.getThumbnailDataURI(appFullFileName);
                        else
                            thumbnailURI = appdesigner.internal.application.AppThumbnailUtils.createAppThumbnailDataURI(screenshotCdataOrPath);
                        end
                    catch
                        thumbnailURI = '';
                    end
                case 'none'
                    autoCapture = 'false';
                    thumbnailURI = '';
                otherwise
                    % This should not happen but in case it does revert to
                    % default behavior
                    autoCapture = 'true';
                    thumbnailURI = '';
            end

            % Comments in the plain text appendix are not localized. Hard
            % coding the thumbnail section string to optimize performance
            % as this code is used in app save.
            thumbnailSectionTemplate = strjoin({...
                '%%---'...
                '%%[app:thumbnail]'...
                '%%{'...
                '<!-- Thumbnail is used by file previewers. To change how the thumbnail is captured or stored, use the App Details dialog box in App Designer. -->'...
                '<?xml version=''1.0'' encoding=''UTF-8'' standalone=''yes'' ?>'...
                '<Thumbnail autoCapture=''%s''>%s</Thumbnail>'...
                '%%}'...
                }, newline);

            sectionStr = sprintf(thumbnailSectionTemplate, autoCapture, thumbnailURI);
        end

    end

end