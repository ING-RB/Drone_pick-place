function info = audioinfo(filename)
%audioinfo Information about an audio file.
%   INFO = AUDIOINFO(FILENAME) returns a structure whose fields contain
%   information about an audio file. FILENAME is a character vector or
%   string scalar that specifies the name of the audio file. FILENAME must
%   be in the current directory, in a directory on the MATLAB path, or a
%   full path to a file.
%
%   INFO = AUDIOINFO(URL,...) returns information on an audio file from an
%   Internet URL or stored at a remote location. When reading data from
%   remote locations, you must specify the full path using a Uniform
%   Resource Locator (URL). For example, to read information from an audio
%   file from Amazon S3 cloud specify the full URL for the file:
%       s3://bucketname/path_to_file/my_audio.wav
%   For more information on accessing remote data, see "Work with Remote
%   Data" in the documentation.
%
%   The set of fields in INFO depends on the individual file and
%   its format.  However, the first nine fields are always the
%   same. These common fields are:
%
%   'Filename'          A character vector or string scalar containing the name of the file
%   'CompressionMethod' Method of audio compression in the file
%   'NumChannels'       Number of audio channels in the file.
%   'SampleRate'        The sample rate (in Hertz) of the data in the file.
%   'TotalSamples'      Total number of audio samples in the file.
%   'Duration'          Total duration of the audio in the file, in seconds.
%   'Title'             character vector or string scalar representing the value of the Title tag
%                       present in the file. Value is empty if tag is not
%                       present.
%   'Comment'           character vector or string scalar representing the value of the Comment tag
%                       present in the file. Value is empty if tag is not
%                       present.
%   'Artist'            character vector or string scalar representing the value of the Artist or
%                       Author tag present in the file. Value is empty if
%                       tag not present.
%
%   Format specific fields areas follows:
%
%   'BitsPerSample'     Number of bits per sample in the audio file.
%                       Only supported for WAVE (.wav) and FLAC (.flac)
%                       files. Valid values are 8, 16, 24, 32 or 64.
%
%   'BitRate'           Number of kilobits per second (kbps) used for
%                       compressed audio files. In general, the larger the
%                       BitRate, the higher the compressed audio quality.
%                       Only supported for MP3 (.mp3) and MPEG-4 Audio
%                       (.m4a, .mp4) files.
%
% Example
%     % Read audio information from a local file
%     info = audioinfo('Local_folder/sample_audio.wav');
%
%     % Read audio information from an Amazon S3 location
%     info = audioinfo('s3://bucketname/path_to_file/sample_audio.wav');
%
%   See also AUDIOREAD, AUDIOWRITE

%   Copyright 2012-2024 The MathWorks, Inc.

% Parse input arguments:
    narginchk(1,1);
    filename = convertStringsToChars(filename);
    validateattributes(filename, {'char', 'string'}, {'vector'}, mfilename, 'FILENAME');

    % If remote file exists, copies the file to a temporary local folder
    try
        fileObj = matlab.io.internal.vfs.stream.RemoteToLocal(filename);
        filename = fileObj.LocalFileName;
    catch ME
        throw(ME);
    end

    % Expand the path, using the matlab path
    filename = multimedia.internal.io.absolutePathForReading(...
        filename, ...
        'MATLAB:audiovideo:audioinfo:fileNotFound', ...
        'MATLAB:audiovideo:audioinfo:filePermissionDenied');

    errorIfTextFormat(filename);

    % Calling 'extractinfo' ensures channel deletion before 'fileNameObj' deletion
    info = extractinfo(filename,fileObj.RemoteFileName);

    % If the remote location exists, overwrite the local filename with the
    % remote filename (not needed with HTTP path)
    if ~isempty(fileObj) && ~strcmp(fileObj.LocalFileName, fileObj.RemoteFileName)
        info.Filename = fileObj.RemoteFileName;
    end

end

function info = extractinfo(LocalFilename,RemoteFileName)

    import multimedia.internal.audio.file.PluginManager;

    try
        readPlugin = PluginManager.getInstance.getPluginForRead(LocalFilename);
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
            exception = PluginManager.replacePluginExceptionPrefix(exception, 'MATLAB:audiovideo:audioinfo');
        end
        throwAsCaller(exception);
    end

    try
        options.Filename = LocalFilename;
        options.ReadDuration = true;
        
        % When getting invalid value for total samples (for libsndfile
        % files), always try to calculate total samples manually
        options.calculateTotalSamples = true; 

        % Create Channel object and give it
        channel = matlabshared.asyncio.internal.Channel( ...
            readPlugin,...
            PluginManager.getInstance.MLConverter,...
            Options = options, ...
            StreamLimits = [0, 0]);

        info.Filename = LocalFilename;
        info.CompressionMethod = channel.CompressionMethod;
        info.NumChannels = channel.NumberOfChannels;
        info.SampleRate = channel.SampleRate;
        info.TotalSamples = channel.TotalSamples;
        info.Duration = channel.Duration;

        info.Title = [];
        if ~isempty(channel.Title)
            info.Title = channel.Title;
        end

        info.Comment = [];
        if ~isempty(channel.Comment)
            info.Comment = channel.Comment;
        end

        info.Artist = [];
        if ~isempty(channel.Artist)
            info.Artist = channel.Artist;
        end

        if any(ismember(properties(channel),'BitsPerSample'))
                info.BitsPerSample = channel.BitsPerSample;
        end

        if any(ismember(properties(channel),'BitRate'))
                info.BitRate = channel.BitRate / 1000; % convert to kbps
        end
    catch exception
        exception = PluginManager.convertPluginException(exception, ...
                                                         'MATLAB:audiovideo:audioinfo');

        throwAsCaller(exception);
    end

end

function errorIfTextFormat(fileName)
%Don't try to open text files with known text extensions.
    [~,~,ext] = fileparts(fileName);
    textExts = {'txt','text','csv','html','xml','m'};
    if ~isempty(ext) && any(strcmpi(ext(2:end),textExts))
        error(message('MATLAB:audiovideo:audioinfo:unsupportedText'));
    end
end
