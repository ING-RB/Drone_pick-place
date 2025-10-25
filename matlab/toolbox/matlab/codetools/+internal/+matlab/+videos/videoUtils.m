classdef videoUtils
    % videoUtils   Utilities for extracting a frame from a video
    %              and saving the frame as an image.
    %
    % These utilities are doing a minimal argument checking and
    % error handling because these utilities should be fast and
    % they are only used for MathWorks internal purposes.
    % Note: On purpose, only functions which are available in
    %       core MATLAB are used. No MATLAB toolboxes are required.
    %
    % Copyright 2024 The MathWorks, Inc.

    methods (Static, Hidden)

        function N = extractImage(videoFile, imageFile, imageFolder, varargin)
            % Automatically finds the first frame in the video which is
            % not monochrome and saves this frame as an image.
            % If the heuristic cannot find a monochrome frame, it chooses
            % the last processed frame.

            threshold = internal.matlab.videos.videoUtils.validateArguments(      ...
                videoFile, imageFile, imageFolder, "image", varargin{:} ...
            );

            readerObj = VideoReader(videoFile);
            nFrames = internal.matlab.videos.videoUtils.info(videoFile).NumFrames;
            step = ceil(nFrames / 100);
            startFrame = floor(floor(readerObj.Duration * readerObj.FrameRate) / 3);
            frameNumber = 1;
            found = false;
            while ~found && hasFrame(readerObj)
                try
                    frame = readFrame(readerObj);
                catch
                    found = false;
                end
                if frameNumber > startFrame
                    if ~internal.matlab.videos.videoUtils.isMostlyBlack(frame, threshold)
                        found = true;
                    end
                end
                frameNumber = frameNumber + step;
            end
            internal.matlab.videos.videoUtils.writeImage(frame, imageFile);
            N = internal.matlab.videos.videoUtils.base64file(imageFile);
        end % extractImage

        function posterImage = generatePosterImage(videoFile, videoName)
            % Generate a temporary folder and image file name
            tempFolder = tempname;
            mkdir(tempFolder);
            imageFile = fullfile(tempFolder, [videoName, '.png']);

            % Extract the image from the video file
            try
                posterImage = internal.matlab.videos.videoUtils.extractImage(videoFile, imageFile, tempFolder);
            catch
                % If an error occurs, return an empty array to indicate that no image was created
                posterImage = [];
            end

            % Clean up the temporary folder
            onCleanup(@()rmdir(tempFolder, 's'));
        end %generatePosterImage

        % Encode image stored in file 'filename' as base64.
        % 'encodedString' contains the base64 string,
        % or an empty string if the encoding failed.
        function encodedString = base64file(filename)
            encodedString = string.empty;
            fid = fopen(filename, "rb");
            if fid == -1
                % File 'filename' not found or cannot be opened
            return;
            end
            obj = onCleanup(@() fclose(fid));
            image = fread(fid);
            image = uint8(image);
            encodedString = matlab.net.base64encode(image);
        end % base64file

        function tempFolder = getTempFolderPath()
            tempFolder = tempname;
            mkdir(tempFolder);
            tempFolder = [tempFolder filesep];
        end % getTempFolderPath

        function extractFrame(videoFile, imageFile, varargin)
            frameNumber = internal.matlab.videos.videoUtils.validateArguments(              ...
                videoFile, imageFile, "frame", varargin{:} ...
            );

            readerObj = VideoReader(videoFile);
            frame = read(readerObj, frameNumber);
            imwrite(frame, imageFile);
        end % extractFrame

        function fileInfo = info(fileName)
            % Get information about a video or image file
            %
            % Syntax:
            % fileInfo = internal.matlab.videos.videoUtils.info(fileName)
            %
            % Description:
            % fileInfo = internal.matlab.videos.videoUtils.info(fileName)
            %     returns information stored in the video resp. image file.
            %
            % Examples:
            % >> fileInfo = internal.matlab.videos.videoUtils.info("xylophone.mp4")
            %
            % >> fileInfo = internal.matlab.videos.videoUtils.info("football.jpg")
            %
            % >> fileInfo = internal.matlab.videos.videoUtils.info("trees.tif")
            %
            % Input Argument:
            % fileName - the name of the video resp. image file.
            %            'fileName' must be a string or a character vector.
            %
            % Output Argument:
            % fileInfo - an object that contains information of the video or image
            %            stored in the file 'fileName'. fileInfo is VideoReader object,
            %            if 'fileName' contains a video, or fileInfo is a struct array,
            %            if 'fileName' contains an image.

            fileExtension = internal.matlab.videos.videoUtils.fileExtension(fileName);
            if contains(fileExtension, internal.matlab.videos.videoUtils.imageFormats())
                fileInfo = internal.matlab.videos.videoUtils.ImageReader(fileName);
            else
                fileInfo = VideoReader(fileName);
            end
        end % info

        function [isMostlyBlack, percentage] = isMostlyBlack(image, thresholdValue)
            % Read the image
            if isstring(image)
                RGB = imread(image);
            else
                RGB = image;
            end
            if numel(size(RGB)) ~= 3
                error("Expected a truecolor image.");
            end

            % Convert image to grayscale
            grayImage = rgb2gray(RGB);

            % Define a threshold for what is considered "black"
            blackThreshold = 70; % This can be adjusted based on your needs

            % Calculate the percentage of "black" pixels
            numBlackPixels = sum(grayImage(:) < blackThreshold);
            totalPixels = numel(grayImage);
            percentage = (numBlackPixels / totalPixels) * 100;

            % Determine if the image is mostly black
            isMostlyBlack = percentage > thresholdValue;
        end

        function oldVal = checkArguments(varargin)
            persistent checkArgumentsVal;

            if nargin == 0
                oldVal = checkArgumentsVal;
            elseif nargin == 1
                newVal = varargin{1};
                if ~islogical(newVal)
                    error("'checkArguments' must be a logical.");
                end
                oldVal = checkArgumentsVal;
                checkArgumentsVal = newVal;
            end
        end % checkArguments


    end % methods (Static)

    methods (Static, Hidden)

        %-------------------------------------------------------------
        % Get the image formats supported by imwrite
        %-------------------------------------------------------------
        function formats = imageFormats()
            formats = imformats;
            formats = string([formats.ext]);
        end % imageFormats

        function ext = fileExtension(filename)
            [~,~,ext] = fileparts(filename);
            if strcmp(ext, "")
                error("Filename must have a file extension.");
            end
            ext = char(ext); ext = string(ext(2:end)); ext = lower(ext);
        end % fileExtension

        function N = validateArguments(videoFile, imageFile, imageFolder, method, varargin)
            if internal.matlab.videos.videoUtils.checkArguments()
                return
            end

            default = 0;
            switch method
                case "image"
                    default = internal.matlab.videos.videoUtils.threshold();
                case "frame"
                    default = 1;
            end
            if nargin == 4
                N = default;
            else
                N = varargin{1};
            end

            if ~isfolder(imageFolder)
                mkdir(imageFolder);
            end

            if ~exist(videoFile, "file")
                error("'%s' not found.", videoFile);
            end

            supportedFormats = internal.matlab.videos.videoUtils.imageFormats();
            if ~contains(internal.matlab.videos.videoUtils.fileExtension(imageFile), supportedFormats)
                error("Image format not supported.");
            end

            switch method
                case "image"
                    N = internal.matlab.videos.videoUtils.validatePercentage(N);
                case "frame"
                    N = internal.matlab.videos.videoUtils.validateFrameNumber(videoFile, N);
            end

        end % validateArguments

        function s = ImageReader(inputName)
            info = imfinfo(inputName);
            s.NumFrames = numel(info);
            info = info(1);
            [path, name, ext] = fileparts(info.Filename);
            info = rmfield(info, "Filename");
            s.Name = string(name) + string(ext);
            s.Path = string(path);
            fields = fieldnames(info);
            for i = 1:numel(fields)
                s.(fields{i}) = info.(fields{i});
            end
        end % ImageReader

        function percentage = threshold
            percentage = 95;
        end % threshold

        function N = validatePercentage(percentage)
            if nargin == 0
                N = internal.matlab.videos.videoUtils.threshold();
                return
            end

            if isscalar(percentage) && isreal(percentage) && 0 < percentage && percentage <= 100
                N = percentage;
            else
                error("Second argument must be a real number between 0 and 100, exclusive.");
            end
        end % validatePercentage

        function N = validateFrameNumber(videoFile, varargin)
            if nargin == 1
                N = 1;
                return;
            end

            frameNumber = varargin{1};
            maxFrame = internal.matlab.videos.videoUtils.info(videoFile).numFrames;

            if ~(isscalar(frameNumber) && isreal(frameNumber) && round(frameNumber) == frameNumber && 0 < frameNumber && frameNumber <= maxFrame)
                error("Second argument must be an integer N, 1 <= N <= %d.", maxFrame);
            end

            N = frameNumber;
        end % validateFrameNumber

        function writeImage(frameData, outputFileName)
            % Write the frame data to a file.
            %
            %   internal.matlab.videos.videoUtils.writeImage(frameData, outputFileName)
            %
            %   frameData - The data from the frame to write.
            %   outputFileName - The name of the file to write to.

            % Check if the output file name is a GIF
            if strcmp(internal.matlab.videos.videoUtils.fileExtension(outputFileName), "gif")
                % Convert the frame to an indexed image and write it with the color map
                [indexedFrame, colorMap] = rgb2ind(frameData, 256);
                imwrite(indexedFrame, colorMap, outputFileName);
            else
                % Write the frame data to the file
                imwrite(frameData, outputFileName);
            end
        end % writeImage

    end % methods (Static, Hidden)

end % classdef internal.matlab.videos.videoUtils