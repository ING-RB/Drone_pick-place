function [fileType, openAction, loadAction, description] = finfo(filename, ext)
    % FINFO Identify file type against standard file handlers on path
    %
    %       [TYPE, OPENCMD, LOADCMD, DESCR] = finfo(FILENAME)
    %
    %       TYPE - contains type for FILENAME or 'unknown'.
    %
    %       OPENCMD - contains command to OPEN or EDIT the FILENAME or empty if
    %                 no handler is found or FILENAME is not readable.
    %
    %       LOADCMD - contains command to LOAD data from FILENAME or empty if
    %                 no handler is found or FILENAME is not readable.
    %
    %       DESCR   - contains description of FILENAME or error message if
    %                 FILENAME is not readable.
    %
    % See also OPEN, LOAD

    %   Copyright 1984-2025 The MathWorks, Inc.

    filename = convertStringsToChars(filename);
    if ~ischar(filename)
        error(message('MATLAB:finfo:InvalidType'));
    end

    if exist(filename,'file') == 0
        error(message('MATLAB:finfo:FileNotFound', filename))
    end

    if nargin == 2 && ~ischar(ext)
        error(message('MATLAB:finfo:ExtensionMustBeAString'));
    end

    % get file extension
    description = '';
    if nargin == 1 || isempty(ext)
        [~,~,ext] = fileparts(filename);
    else
        ext = convertStringsToChars(ext);
    end
    ext = lower(ext);

    % rip leading . from ext
    if contains(ext,'.')
        ext = strtok(ext,'.');
    end

    % special case for .text files (textread will give false positive)
    if strcmp(ext,'text')
        ext = '';
    end

    % check if open and load handlers exist
    openAction = '';
    loadAction = '';

    % this setup will not allow users to override the default EXTread behavior
    if ext ~= ""
        [openAction,loadAction,description,ext] = getKnownExtentionLoaders(filename,ext);
    end

    if openAction ~= "" || loadAction ~= ""
        fileType = ext;
    else
        fileType = 'unknown';
    end

    % disable avifinfo,wavfinfo, and aufinfo warnings
    avWarnState = warning('OFF', 'MATLAB:audiovideo:avifinfo:FunctionToBeRemoved');
    avWarnCleaner = onCleanup(@()warning(avWarnState));

    % make nice description and validate file format
    if nargout == 4 && description == ""
        [status, description] = fetchDescriptions(filename,ext);
        if status == ""
            % the file finfo util says this is a bogus file. return valid file
            % type but empty actions
            openAction = '';
            loadAction = '';
            % generate failure message, used by IMPORTDATA
            description = 'FileInterpretError';
        end
    end
end
%--------------------------------------------------------------------------
function isVideo = isVideoFile(ext)
    try
        % Get the list of supported video file formats on this platform
        videoFileFormats = VideoReader.getFileFormats;
        % extracting video file extensions
        videoFileExt = {videoFileFormats.Extension};
    catch
        videoFileExt = {}; % set the extensions list to empty and continue.
    end

    isVideo = any(strcmp(ext, videoFileExt));
end
%--------------------------------------------------------------------------
function isAudio = isAudioFile(ext)
    try
        % Get the list of supported audio file formats
        audioFileExt = multimedia.internal.audio.file.PluginManager.getInstance.ReadableFileTypes;
    catch
        audioFileExt = {}; % set the extensions list to empty and continue.
    end

    isAudio = any(strcmp(ext, audioFileExt));
end

%--------------------------------------------------------------------------
function [ext, description] = openAsMultimediaFile(filename, fileextension)
    % Attempt to open the file as an image, video, or audio file
    [ext, description] = getImageInfo(filename, fileextension);
    if strcmp(ext,'im')
        % done
    elseif isVideoFile(fileextension)
        [ext, description] = getVideoInfo(filename,fileextension);
    elseif isAudioFile(fileextension)
        [ext, description] = getAudioInfo(filename,fileextension);
    else
        % Even if the extendions isn't known, it could still open as audio/video
        [ext, description] = getVideoInfo(filename,fileextension);
        if ~strcmp(ext,'video')
            [ext, description] = getAudioInfo(filename,fileextension);
        end
    end
end

%--------------------------------------------------------------------------
function [ext, description] = getVideoInfo(filename, fileextension)
    % to support additional codecs that the user may have installed
    try
        videoObj = VideoReader(filename);

        % In some cases, a valid VideoReader object will be created even if the
        % file only has an audio stream.
        if ~hasVideo(videoObj)
            ext = fileextension; % return the same file extension.
            description = '';
            return;
        end

        ext = 'video';
        try
            description = getString(message('MATLAB:finfo:DescVideoFiles', ...
                videoObj.Name, ...
                sprintf('%.4f',videoObj.FrameRate), ...
                videoObj.VideoFormat, ...
                sprintf('%d',videoObj.Width),  ...
                sprintf('%d',videoObj.Height) , ...
                sprintf('%d',videoObj.NumFrames)));
        catch
            description = getString(message('MATLAB:finfo:DescVideoFileEmpty'));
        end

    catch
        ext = fileextension;% return back the same file extension.
        description = '';
    end
end

%--------------------------------------------------------------------------
function [ext, description] = getAudioInfo(filename, fileextension)
    % to support additional codecs that the user may have installed
    try
        audioObj = audioinfo(filename);
        ext = 'audio';
        if isstruct(audioObj)
            try
                description = getString(message('MATLAB:finfo:DescAudioFiles', ...
                    fileextension, audioObj.TotalSamples, ...
                    audioObj.NumChannels));
            catch
                description = getString(message('MATLAB:finfo:DescAudioFileEmpty'));
            end
        else
            description = getString(message('MATLAB:finfo:DescAudioFileEmpty'));
        end
    catch
        ext = fileextension;% return back the same file extension.
        description = '';
    end
end

%--------------------------------------------------------------------------
function [ext, description] = getImageInfo(filename, fileextension)
    try
        % Turn off all (including imfinfo) warnings. Users do not need to see
        % them while accessing the image files using uiimport/open/finfo
        orig_state = warning;
        warning('off','all');
        % Restore the original state of warnings
        c = onCleanup(@()warning(orig_state));

        s = imfinfo(filename);
        ext = 'im';
        if length(s) > 1
            description = getString(message('MATLAB:finfo:DescMultiImageFirstOnly',...
                upper(s(1).Format),...
                length(s),...
                length(s)));
        else
            description = getString(message('MATLAB:finfo:DescNbitImage',...
                s.BitDepth,...
                s.ColorType, ...
                upper(s.Format)));
        end
    catch
        ext = fileextension;
        description = '';
    end
end

%--------------------------------------------------------------------------
function [openAction,loadAction,description,ext] = getKnownExtentionLoaders(filename,ext)
    description = '';
    % First, try to find open and load handlers on the path
    openAction = getExtFcn("open" + ext);
    loadAction = getExtFcn(ext + "read");
    % known data formats go to uiimport and importdata
    uiImportExts = [{'avi', ...          % retaining avi file checks for backwards compatibility
        'csv', 'dat', 'dlm', 'tab', ...  % text files
        'ods'}, extractAfter(matlab.io.internal.xlsreadSupportedExtensions,'.')]; % worksheet files

    if any(strcmp(ext,uiImportExts))
        openAction = 'uiimport';
        loadAction = 'importdata';

    elseif startsWith(ext, 'doc')
        openAction = 'opendoc';

    elseif startsWith(ext, 'h5')
        openAction = 'uiimport';

    elseif startsWith(ext, 'nc')
        openAction = 'uiimport';

    elseif startsWith(ext, 'ppt')
        openAction = 'openppt';

    elseif openAction == "" && loadAction == ""
        codeExts = ["js","css","html","c","h","cxx","cpp","hpp","java","class","py","sh","bat"];
        newCodeExts = ["arxml","cgt","cu","cuh","json","md","shtml","sv","tlc","ts","wsdl","xsl","yaml","yml"];
        nonMultimediaExts = ["cat", "tdx", "txt", "log", "vhd", "vhdl", "v"];
        if ~any(strcmp(ext,[codeExts, newCodeExts, nonMultimediaExts]))
            % Attempt to open the file as a multimedia file i.e. image, audio
            % or video file
            [ext, description] = openAsMultimediaFile(filename, ext);
            if any(strcmp(ext, {'im','video','audio'}))
                openAction = 'uiimport';
                loadAction = 'importdata';
            end
        end
    end
end

%--------------------------------------------------------------------------
function [status, description] = fetchDescriptions(filename,ext)
    xlsExts = matlab.io.internal.xlsreadSupportedExtensions;
    finfoFcn = getExtFcn(ext + "finfo");
    if any(strcmp(['.' ext], xlsExts)) || strncmp(ext, 'ods', 3)
        [status, description] = xlsfinfo(filename);
        % if the file is type mlx, use getCode instead of fread
    elseif strcmp(ext, 'mlx')
        try
            description = matlab.internal.getCode(filename);
            status = 'MLX-file';
        catch
            error(getString(message('MATLAB:finfo:MlxNotSupported')));
        end
    elseif ext ~= "" && finfoFcn ~= ""
        [status, description] = feval(finfoFcn, filename);
    else
        switch ext
        case 'docx'
            description = 'Microsoft Word Document';
        case 'pptx'
            description = 'Microsoft PowerPoint Presentation';
        case 'nc'
            description = 'Network Common Data Form';
        case 'h5'
            description = 'Hierarchical Data Format 5';
        otherwise
            % no finfo for this file, give back contents
            fid = fopen(filename);
            if fid > 0
                description = fread(fid,1024*1024,'*char')';
                fclose(fid);
            else
                description = getString(message('MATLAB:finfo:DescFileNotFound'));
            end
        end
        status = 'NotFound';
    end

end

function extFcn = getExtFcn(targetFcn)
    extFcn = '';
    whichFcn = which(targetFcn + "('char')");
    if whichFcn ~= ""
        [~, whichFcn] = fileparts(whichFcn);
        if whichFcn == targetFcn
            extFcn = whichFcn;
        end
    end
end
