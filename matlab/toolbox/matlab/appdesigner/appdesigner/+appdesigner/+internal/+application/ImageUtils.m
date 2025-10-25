classdef (Sealed, Abstract) ImageUtils < handle
    % IMAGEUTILS - Collection of functions for converting image between
    %   different data types.

    % Copyright 2017-2024 The MathWorks, Inc.

    methods(Static)
        function imageString = getImageDataURIFromBytes(bytes, imageFormat)
            % Base 64 encode and convert to URL

            if isempty(bytes)
                imageString = '';
            else
                base64String = matlab.net.base64encode(bytes);
                imageString = sprintf('data:image/%s;base64,%s',imageFormat, base64String);
            end                   
        end    
     
        function imageString = getImageDataURIFromFile(imagePath)
            [bytes, imageFormat] = appdesigner.internal.application.ImageUtils.getBytesFromImageFile(imagePath);                        
            imageString = appdesigner.internal.application.ImageUtils.getImageDataURIFromBytes(bytes, imageFormat);                                    
        end

        function [bytes, imageFormat] = getBytesFromImageFile(imagePath)
            [~,~,imageFormat] = fileparts(imagePath);
            imageFormat = strrep(imageFormat,'.','');
            
            % Using fread instead of java ImageIO to support reading all
            % of the images of a gif file and not just the first one.
            fid = fopen(imagePath, 'r');
            bytes = fread(fid, 'uint8=>uint8');
            fclose(fid);
        end

        function bytes = getBytesFromCDataRGB(cdata, imageFormat)                                                                      
            % Write the file to a temporary location, and re-read it
            
            tmpDir = fullfile(tempdir, 'ImageUtils');            
            [~,~,~] = mkdir(tmpDir);
            
            % create tempfile for image writing
            tmpFile = fullfile([tempname(tmpDir), '.', imageFormat]);
            
            % convert CData to image file
            imwrite(cdata, tmpFile);
            
            % Clear out the temp file
            deleteFile = onCleanup(@() delete(tmpFile));
            
            bytes = appdesigner.internal.application.ImageUtils.getBytesFromImageFile(tmpFile)';        
        end

        function createImageFileFromBytes(imagePath, bytes)
            
            % Using fwrite instead of java ImageIO to support writting all
            % of the images of a gif file and not just the first one.
            fid = fopen(imagePath, 'w+');
            fwrite(fid, bytes);
            fclose(fid);
        end
    end

end