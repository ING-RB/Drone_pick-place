function [y,Fs] = audioread(filename, range, datatype)
%AUDIOREAD Read audio files
%   [Y, FS] = AUDIOREAD(FILENAME) reads an audio file specified by the
%   character vector or string scalar FILENAME, returning the sampled data
%   in Y and the sample rate FS, in Hertz.
%
%   [Y, FS] = AUDIOREAD(FILENAME, [START END]) returns only samples START
%   through END from each channel in the file.
%
%   [Y, FS] = AUDIOREAD(FILENAME, DATATYPE) specifies the data type format of
%   Y used to represent samples read from the file.
%   If DATATYPE='double', Y contains double-precision normalized samples.
%   If DATATYPE='native', Y contains samples in the native data type
%   found in the file.  Interpretation of DATATYPE is case-insensitive and
%   partial matching is supported.
%   If omitted, DATATYPE='double'.
%
%   [Y, FS] = AUDIOREAD(FILENAME, [START END], DATATYPE);
%
%   [Y, FS] = AUDIOREAD(URL,...) reads the audio file from an Internet URL
%   or stored at a remote location. When reading data from remote locations,
%   you must specify the full path using a Uniform Resource Locator (URL).
%   For example, to read an audio file from Amazon S3 cloud specify the
%   full URL for the file:
%       s3://bucketname/path_to_file/my_audio.wav
%   For more information on accessing remote data, see "Work with Remote
%   Data" in the documentation.
%
%   Output Data Ranges
%   Y is returned as an m-by-n matrix, where m is the number of audio
%   samples read and n is the number of audio channels in the file.
%
%   If you do not specify DATATYPE, or dataType is 'double',
%   then Y is of type double, and matrix elements are normalized values
%   between -1.0 and 1.0.
%
%   If DATATYPE is 'native', then Y may be one of several MATLAB
%   data types, depending on the file format and the BitsPerSample
%   of the input file:
%
%    File Format      BitsPerSample  Data Type of Y     Data Range of Y
%    ----------------------------------------------------------------------
%    WAVE (.wav)            8           uint8             0 <= Y <= 255
%                          16           int16        -32768 <= Y <= 32767
%                          24           int32         -2^31 <= Y <= 2^31-1
%                          32           int32         -2^31 <= Y <= 2^31-1
%                          32           single         -1.0 <= Y <= +1.0
%    ----------------------------------------------------------------------
%    WAVE (.wav) (u-law)    8           int16        -32124 <= Y <= 32124
%    ----------------------------------------------------------------------
%    WAVE (.wav) (A-law)    8           int16        -32256 <= Y <= 32256
%    ----------------------------------------------------------------------
%    FLAC (.flac)           8           uint8             0 <= Y <= 255
%                          16           int16        -32768 <= Y <= 32767
%                          24           int32         -2^31 <= Y <= 2^31-1
%    ----------------------------------------------------------------------
%    MP3 (.mp3)            N/A          single         -1.0 <= Y <= +1.0
%    MPEG-4 (.m4a,.mp4)
%    OGG (.ogg,.oga,.opus)
%    ----------------------------------------------------------------------
%
%   Call audioinfo to learn the BitsPerSample of the file.
%
%   Note that where Y is single or double and the BitsPerSample is
%   32 or 64, values in Y might exceed +1.0 or -1.0.
%
% Example:
%
%     % Read audio from a local file
%     [y, Fs] = audioread('Local_folder/sample_audio.wav');
%
%     % Read audio from an Amazon S3 bucket location
%     [y, Fs] = audioread('s3://bucketname/path_to_file/sample_audio.wav');
%
%   See also AUDIOINFO, AUDIOWRITE

%   Copyright 2012-2024 The MathWorks, Inc.


% Parse input arguments:
    if nargin > 0
        filename = convertStringsToChars(filename);
    end

    if nargin > 1
        range = convertStringsToChars(range);
    end

    if nargin > 2
        datatype = convertStringsToChars(datatype);
    end

    narginchk(1, 3);

    if nargin < 2
        range = [1 inf];
        datatype = 'double';
    elseif nargin < 3 && ischar(range)
        datatype = range;
        range = [1 inf];
    elseif nargin < 3
        datatype = 'double';
    end

    validateattributes(filename, {'char', 'string'}, {'scalartext', 'vector'});
    % If remote file exists, copies the file to a temp local folder
    try
        fileNameObj = matlab.io.internal.vfs.stream.RemoteToLocal(filename);
        filename = fileNameObj.LocalFileName;
    catch ME
        throw(ME);
    end

    % validate range attributes
    validateattributes( ...
        range,{'double'}, ...
        {'positive','nonempty','nonnan','ncols',2,'nrows',1}',...
        'audioread','range',2);

    % workaround for reading incorrect samples from opus files when some
    % offsets are specified
    [~,~,fileExtension] = fileparts(filename);
    % if it is an opus file and reading is from the offset
    if (strcmpi(fileExtension, ".opus") && range(1) ~= 1)
        % read the entire file and manually return the correct portion
        [y, Fs] = readaudio(filename, fileNameObj.RemoteFileName, [1 inf], datatype);
        [startSample, samplesToRead] = validateRange(range, size(y, 1));
        % validateRange returns zero-based indices
        indicesToReturn = (startSample+1) : (startSample+samplesToRead);
        y = y(indicesToReturn, :);
        return
    end
    % end of workaround

    % Workaround for missing samples when reading ogg files from offset on
    % Debian 11
    if isunix() && ~ismac()
        [~,~,fileExtension] = fileparts(filename);
        % if it is an ogg/oga/vorbis file and reading is not from the very beginning
        if (any(strcmpi(fileExtension, [".ogg", ".oga", ".vorbis"])) && range(1) ~= 1)
            % read the entire file and manually return the correct portion
            [y, Fs] = readaudio(filename, fileNameObj.RemoteFileName, [1 inf], datatype);
            [startSample, samplesToRead] = validateRange(range, size(y, 1));
            % validateRange returns zero-based indices
            indicesToReturn = (startSample+1) : (startSample+samplesToRead);
            y = y(indicesToReturn, :); 
            return
        end
    end
    % end of workaround

    % Calling 'readaudio' ensures channel deletion before 'fileNameObj' deletion
    [y, Fs] = readaudio (filename, fileNameObj.RemoteFileName, range, datatype);

end

function [y, Fs] = readaudio(LocalFileName, RemoteFileName, range, datatype)

% Expand the path, using the matlab path if necessary
    LocalFileName = multimedia.internal.io.absolutePathForReading(...
        LocalFileName, ...
        'MATLAB:audiovideo:audioread:fileNotFound', ...
        'MATLAB:audiovideo:audioread:filePermissionDenied');

    import multimedia.internal.audio.file.PluginManager;

    try
        readPlugin = PluginManager.getInstance.getPluginForRead(LocalFileName);
    catch exception
        if matlab.io.internal.vfs.validators.hasIriPrefix(RemoteFileName) && ...
                any(matlab.io.internal.vfs.validators.GetScheme(RemoteFileName) == ["http", "https"]) && ...
                contains(matlab.io.internal.filesystem.getContentType(RemoteFileName), "text/html", IgnoreCase=true)
            % If the file being read is from an HTTP link and its content type is HTML,
            % throw an error. This is because we are attempting to read the HTML content
            % as one of the supported formats. This scenario can occur when the HTTP link
            % requires authentication, and instead of the desired content, we receive a
            % login page.
            exception = MException('multimedia:audiofile:readHTMLWithAuth',message('multimedia:audiofile:readHTMLWithAuth', RemoteFileName));
        else
            % The exception has been fully formed. Only the prefix has to be
            % replaced.
            exception = PluginManager.replacePluginExceptionPrefix(exception, 'MATLAB:audiovideo:audioread');
        end
        throwAsCaller(exception);
    end

    try
        options.Filename = LocalFileName;
        % Disable reading metadata tags from the file as they are not used
        % during reading data. This can help improve performance, atleast on
        % Linux.
        options.ReadTags = false;
        % Read duration only in the case when the total number of samples
        % are unspecified, i.e. any value in range is 'Inf'. Applicable for
        % MP3 files only.
        if any(isinf(range))
            options.ReadDuration = true;
        else
            options.ReadDuration = false;
        end            

        % When getting invalid value for total samples (for libsndfile
        % files), try to calculate total samples manually only if the range
        % values need to be validated against TotalSamples (i.e. when we
        % are not trying to read the entire file)
        if ~all(range == [1,Inf])
            options.calculateTotalSamples = true;
        end

        % Create Channel object
        channel = matlabshared.asyncio.internal.Channel( ...
            readPlugin,...
            PluginManager.getInstance.MLConverter, ...
            Options = options, ...
            StreamLimits = [0, 0]);

        channel.InputStream.addFilter( ...
            PluginManager.getInstance.TransformFilter, ...
            []);

        % Check if Duration is available
        if (channel.Duration == -1)
            channel.TotalSamples = channel.Duration;
        end

        % Validate the datatype is correctly formed
        datatype = validateDataType(datatype, channel);

        [startSample, samplesToRead] = validateRange(range, channel.TotalSamples);

        options.StartSample = startSample;
        options.FrameSize = double(multimedia.internal.audio.file.FrameSize.Optimal);
        options.FilterTransformType = 'DeinterleaveTranspose';
        options.FilterOutputDataType = datatype;

        channel.open(options);
        c = onCleanup(@()channel.close()); % close when going out of scope

        % For certain MP3 files, 'Duration' is only available after reading
        % till the end of file. The listener will listen to the event which
        % signals the availibility of 'Duration'.

        % Attach the duration listener
        durationListener = event.listener(channel,'Custom', ...
                                          @(src, event) computeTotalSamples(src,event));
        cl = onCleanup(@() delete(durationListener)); % delete when going out of scope

        Fs = double(channel.SampleRate);

        % Read the samples
        % If one of the range values is Inf, we have already made sure to
        % get the duration value and hence the total number of samples for
        % MP3 files. In that case samplesToRead would never be NaN or Inf
        y = channel.InputStream.read(samplesToRead);

        % Generate a warning if the number of samples read is lesser than the
        % number requested.
        actNumSamplesRead = size(y, 1);
        if actNumSamplesRead < samplesToRead
            while (channel.TotalSamples < 0)
                drawnow limitrate;
            end
            % Once TotalSamples is available, validate the range
            validateRangeWithTotalSamples(range, channel.TotalSamples);
            stopSample = startSample + samplesToRead - 1;
            if (startSample+1 ~= 1) || (stopSample+1 ~= channel.TotalSamples)
                warning(message('MATLAB:audiovideo:audioread:incompleteRead', actNumSamplesRead));
            end
        end

    catch exception
        exception = PluginManager.convertPluginException(exception, ...
                                                         'MATLAB:audiovideo:audioread');

        throwAsCaller(exception);
    end

end

function datatype = validateDataType(datatype, channel)

    datatype = validatestring(datatype, {'double','native'},'audioread','datatype');

    if strcmp(datatype,'native')
        if ismember('BitsPerSample',properties(channel))
            % Channel has a 'BitsPerSample' property and is most likely
            % uncompressed or lossless.
            % Set the 'native' data type to the underlying channel's
            % datatype.
            datatype = channel.DataType;
        else
            % Channel is most likely compressed. 'native' datatype
            % should be single
            datatype = 'single';
        end
    else
        datatype = 'double';
    end

end



    function [startSample, samplesToRead] = validateRange(range, totalSamples)

        if totalSamples >= 0
            range = validateRangeWithTotalSamples(range, totalSamples);
        else
            % sample ranges are zero based. Get the correct startSample
            range = range - 1;
        end

        % Validate that start of range is less than the end of range
        if (range(1) > range(2))
            error(message('MATLAB:audiovideo:audioread:invalidrange'));
        end

        startSample = range(1);
        samplesToRead = (range(2) - startSample) + 1;
    end

    function range = validateRangeWithTotalSamples(range, totalSamples)
        % replace any Inf values with total samples
        range(range == Inf) = totalSamples;

        if any(range > totalSamples)
            error(message('MATLAB:audiovideo:audioread:endoffile', totalSamples));
        end


        range = range - 1; % sample ranges are zero based
        range = max(range, 0); % bound the range by zero

        % Validate that all values are integers
        validateattributes( ...
            range,{'numeric'}, ...
            {'integer'},...
            'audioread','range',2);
    end


    function computeTotalSamples(src,event)
        if event.Type == "FileDurationEvent"
            src.TotalSamples = floor(src.SampleRate * event.Data.Duration);
        end
    end