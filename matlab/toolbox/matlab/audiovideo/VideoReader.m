classdef (CaseInsensitiveProperties=true, TruncatedProperties=true) ...
         VideoReader < audiovideo.internal.IVideoReader & ...
                       matlab.mixin.SetGet & matlab.mixin.CustomDisplay & ...
                       matlab.mixin.internal.Scalar %#codegen
% VIDEOREADER Create a multimedia reader object.
%
%   OBJ = VIDEOREADER(FILENAME) constructs a multimedia reader object, OBJ,
%   that can read in video data from a multimedia file.  FILENAME is a
%   character vector or string scalar specifying the name of a multimedia
%   file.  There are no restrictions on file extensions.  By default,
%   MATLAB looks for the file FILENAME on the MATLAB path.
%
%   OBJ = VIDEOREADER(FILENAME, 'P1', V1, 'P2', V2, ...) constructs a
%   multimedia reader object, assigning values V1, V2, etc. to the
%   specified properties P1, P2, etc. Note that the property value pairs
%   can be in any format supported by the SET function, e.g.
%   parameter-value character vector or string scalar pairs, structures, or
%   parameter-value cell array pairs.
%
%   Methods:
%     read              - Read one or more frames from a video file.
%     readFrame         - Read the next available frame from a video file.
%     hasFrame          - Determine if there is a frame available to read
%                         from a video file. 
%     getFileFormats    - List of known supported video file formats.
%
%   Properties:
%     Name             - Name of the file to be read.
%     Path             - Path of the file to be read.
%     Duration         - Total length of file in seconds.
%     CurrentTime      - Location from the start of the file of the current
%                        frame to be read in seconds. 
%     Tag              - Generic text for the user to set.
%     UserData         - Generic field for any user-defined data.
%
%     Height           - Height of the video frame in pixels.
%     Width            - Width of the video frame in pixels.
%     BitsPerPixel     - Bits per pixel of the video data.
%     VideoFormat      - Video format as it is represented in MATLAB.
%     FrameRate        - Frame rate of the video in frames per second.
%
%   Example:
%       % Construct a multimedia reader object associated with file
%       % 'xylophone.mp4'.
%       vidObj = VideoReader('xylophone.mp4');
%
%       % Specify that reading should start at 0.5 seconds from the
%       % beginning.
%       vidObj.CurrentTime = 0.5;
%
%       % Create an axes
%       currAxes = axes;
%       
%       % Read video frames until available
%       while hasFrame(vidObj)
%           vidFrame = readFrame(vidObj);
%           image(vidFrame, 'Parent', currAxes);
%           currAxes.Visible = 'off';
%           pause(1/vidObj.FrameRate);
%       end
%
%       % Read every 5th video frame from the start of the video
%       for cnt = 1:5:vidObj.NumFrames
%           vidFrame = read(vidObj, cnt);
%       end
%  
%   See also AUDIOVIDEO, VIDEOREADER/READ, VIDEOREADER/READFRAME, VIDEOREADER/HASFRAME, MMFILEINFO.                
%

%   Authors: NH DL NV
%   Copyright 2005-2024 The MathWorks, Inc.
    

    %------------------------------------------------------------------
    % General properties
    %------------------------------------------------------------------
    % See audiovideo.internal.IVideoReader
    
    %------------------------------------------------------------------
    % Private properties
    %------------------------------------------------------------------
    properties(Access='private')
        % To handle construction on load.
        LoadArgs
        
        % Store the schema version of the VideoReader object that was
        % saved.
        SchemaVersionSavedIn
        
        % Store any exceptions that were generated when reading ahead to
        % the next frame. 
        ReadAheadException = [];
    end
    
    %------------------------------------------------------------------
    % Documented methods
    %------------------------------------------------------------------    
    methods(Access='public')
    
        %------------------------------------------------------------------
        % Lifetime
        %------------------------------------------------------------------
        function obj = VideoReader(varargin)
            obj@audiovideo.internal.IVideoReader(varargin{:});
        end

        %------------------------------------------------------------------
        % Operations
        %------------------------------------------------------------------        
        function inspect(obj)
        %INSPECT Open the inspector and inspect VideoReader object properties.
        %
        %    INSPECT(OBJ) opens the property inspector and allows you to
        %    inspect and set properties for the VideoReader object, OBJ.
        %
        %    Example:
        %        r = VideoReader('myfilename.avi');
        %        inspect(r);

        %    NCH DTL
        %    Copyright 2004-2019 The MathWorks, Inc.
            % If called from Workspace Browser (openvar), error, so that
            % the Variable Editor will be used. If called directly, warn,
            % and bring up the Inspector.
            stack = dbstack();
            if any(strcmpi({stack.name}, 'openvar'))
                error(message('MATLAB:audiovideo:VideoReader:inspectObsolete'));
            else
                warning(message('MATLAB:audiovideo:VideoReader:inspectObsolete'));
                inspect(obj.VidReader);
            end
        end
        
        function outputFrames = read(obj, varargin)
        %READ Read one or more frames from a video file. 
        %
        %   VIDEO = READ(OBJ) reads in all video frames from the file associated 
        %   with OBJ.  VIDEO is an H x W x B x F matrix where:
        %         H is the image frame height
        %         W is the image frame width
        %         B is the number of bands in the image (e.g. 3 for RGB),
        %         F is the number of frames read
        %   The class of VIDEO depends on the data in the file. 
        %   For example, given a file that contains 8-bit unsigned values 
        %   corresponding to three color bands (RGB24), video is an array of 
        %   uint8 values.
        %
        %   VIDEO = READ(OBJ,INDEX) reads only the specified frames. INDEX can be 
        %   a single number or a two-element array representing an INDEX range 
        %   of the video stream.  Use Inf to represent the last frame of the file.
        %
        %   For example:
        %
        %      VIDEO = READ(OBJ, 1);        % first frame only
        %      VIDEO = READ(OBJ, [1 10]);   % first 10 frames
        %      VIDEO = READ(OBJ, Inf);      % last frame only
        %      VIDEO = READ(OBJ, [50 Inf]); % frame 50 thru end
        %
        %   If an invalid INDEX is specified, MATLAB throws an error.
        %
        %   VIDEO = READ(___,'native') always returns data in the format specified 
        %   by the VideoFormat property, and can include any of the input arguments
        %   in previous syntaxes.  See 'Output Formats' section below.
        %
        %   Output Formats
        %   VIDEO is returned in different formats depending upon the usage of the
        %   'native' parameter, and the value of the obj.VideoFormat property:
        %
        %     VIDEO Output Formats (default behavior):
        %                             
        %       obj.VideoFormat   Data Type   VIDEO Dimensions  Description
        %       ---------------   ---------   ----------------  ------------------
        %        'RGB24'            uint8         MxNx3xF       RGB24 image
        %        'Grayscale'        uint8         MxNx1xF       Grayscale image
        %        'Indexed'          uint8         MxNx3xF       RGB24 image
        %
        %     VIDEO Output Formats (using 'native'):
        %
        %       obj.VideoFormat   Data Type   VIDEO Dimensions  Description
        %       ---------------   ---------   ----------------  ------------------
        %        'RGB24'            uint8         MxNx3xF       RGB24 image
        %        'Grayscale'        struct        1xF           MATLAB movie*
        %        'Indexed'          struct        1xF           MATLAB movie*
        %
        %     Motion JPEG 2000 VIDEO Output Formats (using default or 'native'):
        %                             
        %       obj.VideoFormat   Data Type   VIDEO Dimensions  Description
        %       ---------------   ---------   ----------------  ------------------
        %        'Mono8'            uint8         MxNx1xF       Mono image
        %        'Mono8 Signed'     int8          MxNx1xF       Mono signed image
        %        'Mono16'           uint16        MxNx1xF       Mono image
        %        'Mono16 Signed'    int16         MxNx1xF       Mono signed image
        %        'RGB24'            uint8         MxNx3xF       RGB24 image
        %        'RGB24 Signed'     int8          MxNx3xF       RGB24 signed image
        %        'RGB48'            uint16        MxNx3xF       RGB48 image
        %        'RGB48 Signed'     int16         MxNx3xF       RGB48 signed image
        %
        %     *A MATLAB movie is an array of FRAME structures, each of
        %      which contains fields cdata and colormap.
        %
        %   Example:
        %      % Construct a multimedia reader object associated with file 
        %      % 'xylophone.mp4'.
        %      readerobj = VideoReader('xylophone.mp4');
        %
        %      % Read in all video frames.
        %      vidFrames = read(readerobj);
        %
        %      % Get the number of frames.
        %      numFrames = get(readerobj, 'NumFrames');
        %
        %      % Create a MATLAB movie struct from the video frames.
        %      for k = 1 : numFrames
        %            mov(k).cdata = vidFrames(:,:,:,k);
        %            mov(k).colormap = [];
        %      end
        %
        %      % Create a figure
        %      hf = figure; 
        %      
        %      % Resize figure based on the video's width and height
        %      set(hf, 'position', [150 150 readerobj.Width readerobj.Height])
        %
        %      % Playback movie once at the video's frame rate
        %      movie(hf, mov, 1, readerobj.FrameRate);
        %
        %   See also AUDIOVIDEO, MOVIE, VIDEOREADER, VIDEOREADER/READFRAME, VIDEOREADER/HASFRAME, MMFILEINFO.

        %    NCH DTL
        %    Copyright 2005-2019 The MathWorks, Inc.
            
            try
                outputFrames = read@audiovideo.internal.IVideoReader(obj, varargin{:});
            catch ME
                throwAsCaller(ME);
            end
        end
        
        function outputFrame = readFrame(obj, outputformat)
        %READFRAME Read the next available frame from a video file
        %
        %   VIDEO = READFRAME(OBJ) reads the next available video frame from the
        %   file associated  with OBJ.  VIDEO is an H x W x B matrix where:
        %         H is the image frame height
        %         W is the image frame width
        %         B is the number of bands in the image (e.g. 3 for RGB)
        %   The class of VIDEO depends on the data in the file. 
        %   For example, given a file that contains 8-bit unsigned values 
        %   corresponding to three color bands (RGB24), video is an array of 
        %   uint8 values.
        %
        %   VIDEO = READFRAME(OBJ,'native') always returns data in the format specified 
        %   by the VideoFormat property, and can include any of the input arguments
        %   in previous syntaxes.  See 'Output Formats' section below.
        %
        %   Output Formats
        %   VIDEO is returned in different formats depending upon the usage of the
        %   'native' parameter, and the value of the obj.VideoFormat property:
        %
        %     VIDEO Output Formats (default behavior):
        %                             
        %       obj.VideoFormat   Data Type   VIDEO Dimensions  Description
        %       ---------------   ---------   ----------------  ------------------
        %        'RGB24'            uint8         MxNx3         RGB24 image
        %        'Grayscale'        uint8         MxNx1         Grayscale image
        %        'Indexed'          uint8         MxNx3         RGB24 image
        %
        %     VIDEO Output Formats (using 'native'):
        %
        %       obj.VideoFormat   Data Type   VIDEO Dimensions  Description
        %       ---------------   ---------   ----------------  ------------------
        %        'RGB24'            uint8         MxNx3         RGB24 image
        %        'Grayscale'        struct        1x1           MATLAB movie*
        %        'Indexed'          struct        1x1           MATLAB movie*
        %
        %     Motion JPEG 2000 VIDEO Output Formats (using default or 'native'):
        %                             
        %       obj.VideoFormat   Data Type   VIDEO Dimensions  Description
        %       ---------------   ---------   ----------------  ------------------
        %        'Mono8'            uint8         MxNx1         Mono image
        %        'Mono8 Signed'     int8          MxNx1         Mono signed image
        %        'Mono16'           uint16        MxNx1         Mono image
        %        'Mono16 Signed'    int16         MxNx1         Mono signed image
        %        'RGB24'            uint8         MxNx3         RGB24 image
        %        'RGB24 Signed'     int8          MxNx3         RGB24 signed image
        %        'RGB48'            uint16        MxNx3         RGB48 image
        %        'RGB48 Signed'     int16         MxNx3         RGB48 signed image
        %
        %     *A MATLAB movie is an array of FRAME structures, each of
        %      which contains fields cdata and colormap.
        %
        %   Example:
        %       % Construct a multimedia reader object associated with file
        %       'xylophone.mp4'.
        %       vidObj = VideoReader('xylophone.mp4');
        %
        %       % Specify that reading should start at 0.5 seconds from the
        %       % beginning.
        %       vidObj.CurrentTime = 0.5;
        %
        %       % Create an axes
        %       currAxes = axes;
        %       
        %       % Read video frames until available
        %       while hasFrame(vidObj)
        %           vidFrame = readFrame(vidObj);
        %           image(vidFrame, 'Parent', currAxes);
        %           currAxes.Visible = 'off';
        %           pause(1/vidObj.FrameRate);
        %       end
        %
        %   See also AUDIOVIDEO, VIDEOREADER, VIDEOREADER/HASFRAME, VIDEOREADER/READ, MMFILEINFO.

        %    Copyright 2013-2018 The MathWorks, Inc.
        
            if nargin == 1
                outputformat = 'default';
            end
            
            try
                outputFrame = readFrame@audiovideo.internal.IVideoReader(obj, outputformat);
            catch ME
                throwAsCaller(ME);
            end
        end
        
        function flag = hasFrame(obj)
        %HASFRAME Determine if there is a frame available to read from a video file
        %
        %   FLAG = HASFRAME(OBJ) returns TRUE if there is a video frame available
        %   to read from the file. If not, it returns FALSE.
        %
        %   Example:
        %       % Construct a multimedia reader object associated with file
        %       'xylophone.mp4'.
        %       vidObj = VideoReader('xylophone.mp4');
        %
        %       % Specify that reading should start at 0.5 seconds from the
        %       % beginning.
        %       vidObj.CurrentTime = 0.5;
        %
        %       % Create an axes
        %       currAxes = axes;
        %       
        %       % Read video frames until available
        %       while hasFrame(vidObj)
        %           vidFrame = readFrame(vidObj);
        %           image(vidFrame, 'Parent', currAxes);
        %           currAxes.Visible = 'off';
        %           pause(1/vidObj.FrameRate);
        %       end
        %
        %   See also AUDIOVIDEO, VIDEOREADER, VIDEOREADER/READFRAME, VIDEOREADER/READ, MMFILEINFO.

        %    Copyright 2013-2018 The MathWorks, Inc.
            try
                flag = hasFrame@audiovideo.internal.IVideoReader(obj);
            catch ME
                throwAsCaller(ME);
            end
        end
        
        %------------------------------------------------------------------        
        % Overrides of builtins
        %------------------------------------------------------------------         
                
        function obj = saveobj(obj)
        %SAVEOBJ Save filter for VideoReader objects.
        %
        %    OBJ = SAVEOBJ(OBJ) is called by SAVE when an VideoReader object is 
        %    saved to a .MAT file. The return value, OBJ, is subsequently 
        %    written by SAVE to a MAT file.  

        %    Dinesh Iyer
        %    Copyright 2014-2019 The MathWorks, Inc.

        % Save constructor arg for load.
            obj.LoadArgs{1} = fullfile(obj.Path, obj.Name);

            currentTime = obj.CurrentTime;
            obj.LoadArgs{2} = currentTime;
            
            % We will save the schema version into the MAT file. This will
            % allow suitable forward/backward compatibility when loading
            % saved objects across different MATLAB versions.
            obj.SchemaVersionSavedIn = audiovideo.internal.IVideoReader.SchemaVersion;
        end
    end
    
    methods(Static)
        
        %------------------------------------------------------------------
        % Operations
        %------------------------------------------------------------------
        
        function formats = getFileFormats()
            % GETFILEFORMATS
            %
            %    FORMATS = VIDEOREADER.GETFILEFORMATS() returns an object
            %    array of audiovideo.FileFormatInfo objects which are the
            %    formats VIDEOREADER is known to support on the current
            %    platform.
            %
            %    The properties of an audiovideo.FileFormatInfo object are:
            %
            %    Extension   - The file extension for this file format
            %    Description - A text description of the file format
            %    ContainsVideo - The File Format can hold video data
            %    ContainsAudio - The File Format can hold audio data
            %
            
            import matlab.internal.video.PluginManager;
            extensions = PluginManager.getInstance().ReadableFileTypes;
            
            formats = audiovideo.FileFormatInfo.empty();
            for ii=1:length(extensions)
                formats(ii) = audiovideo.FileFormatInfo( extensions{ii}, ...
                                                         VideoReader.translateDescToLocale(extensions{ii}), ...
                                                         true, ...
                                                         false );
            end
            
            % sort file extension
            [~, sortedIndex] = sort({formats.Extension});
            formats = formats(sortedIndex);
        end
    end

    methods(Static, Hidden)
        %------------------------------------------------------------------
        % Persistence
        %------------------------------------------------------------------        
        function obj = loadobj(obj)
        %LOADOBJ Load filter for VideoReader objects.
        %
        %    OBJ = LOADOBJ(OBJ) is called by LOAD when an VideoReader object is 
        %    loaded from a .MAT file. The return value, OBJ, is subsequently 
        %    used by LOAD to populate the workspace.  
        %
        %    LOADOBJ will be separately invoked for each object in the .MAT file.
        %

        %    NH DT DL
        %    Copyright 2010-2019 The MathWorks, Inc.

        % Object is already created, just properly initialize it.
        % We do this to take advantage of all the load functionality provided
        % by MATLAB (e.g. object recursion detection).

            % Starting in 19a, we save 3 pieces of information to the MAT
            % file when saving the VideoReader object: fileName,
            % currentTime and SchemaVersion. Older versions save only the
            % first two.
            if ~isprop(obj, 'SchemaVersionSavedIn')
                % Entry into the loop, indicates this was an object saved
                % before 19a. 
                if numel(obj.LoadArgs) == 1
                    obj.LoadArgs{2} = NaN;
                elseif obj.LoadArgs{2} == 0
                    % Internally, the default value for CurrentTime was
                    % changed from 0 to NaN.
                    obj.LoadArgs{2} = NaN;
                end
            end
            
            obj.initReader(obj.LoadArgs{:});
        end
    end
    
    %------------------------------------------------------------------
    % For code generation support
    %------------------------------------------------------------------
    methods(Static, Hidden)
        function name = matlabCodegenRedirect(~)
            % Use the implementation in the class below when generating
            % code.
            name = 'audiovideo.internal.coder.VideoReader';
        end
    end

    %------------------------------------------------------------------
    % Overrides for Custom Display
    %------------------------------------------------------------------
    methods (Access='protected')
        function propGroups = getPropertyGroups(~)
            propGroups = audiovideo.internal.VideoReaderDisplayHelper.computePropGroups();
        end
    end
    
    %------------------------------------------------------------------
    % Overrides for Custom Display when calling get(vidObj)
    %------------------------------------------------------------------
    methods (Hidden)
        function getdisp(obj)
            display(obj);
        end
    end
    
    %------------------------------------------------------------------
    % Overrides for Custom Display when calling get(vidObj)
    %------------------------------------------------------------------
    methods(Access='protected', Hidden)
        function displayScalarObject(obj)
            % If the number of frames is available, no customization is
            % necessary.
            if obj.VidReader.IsNumFramesAvailable
                disp(getHeader(obj));
                groups = getPropertyGroups(obj);
                matlab.mixin.CustomDisplay.displayPropertyGroups(obj, groups);
                disp(getFooter(obj));
                return;
            end
            
            vh = audiovideo.internal.VideoReaderDisplayHelper(obj);
            
            % Customize the Display
            % The message to be displayed is in the message catalog to
            % allow for translation.
            if feature('hotlinks')
                numFramesMsg = message('MATLAB:audiovideo:VideoReader:NumFramesCalculatingHotLinksOn');
            else
                referDocMsg = message('MATLAB:audiovideo:VideoReader:ReferDocHotLinksOff');
                referDocMsgString = [' (' referDocMsg.getString() ')'];
                numFramesMsg = message( 'MATLAB:audiovideo:VideoReader:NumFramesCalculatingHotLinksOff', '', referDocMsgString);
            end
            
            if feature('hotlinks')
                dispStr = evalc('display(vh)');
            else
                % Even if hotlinks are OFF, in the evalc call, the hotlinks
                % appear te ON when executing via an EVALC call. Hence,
                % explicitly TURN off hotlinks before displaying the helper
                % class such that hotlinks in the header display are
                % removed.
                dispStr = evalc('feature(''hotlinks'', ''off''); display(vh); feature(''hotlinks'', ''on'')');
            end
            
            dispStr = replace(dispStr, 'VideoReaderDisplayHelper', 'VideoReader');
            dispStr = erase(dispStr, 'audiovideo.internal.');
            dispStr = extractAfter(dispStr, 'vh =');
            if feature('hotlinks')
                aLoc = strfind(dispStr, '<a');
            else
                aLoc = strfind(dispStr, 'VideoReader');
            end
            dispStr = dispStr(min(aLoc)-2:end);
            nfLoc = strfind(dispStr, 'NumFrames:');
            numFramesMsgString = numFramesMsg.getString();
            dispStr = insertAfter(dispStr, nfLoc + numel('NumFrames:'), numFramesMsgString);
            dispStr = replace(dispStr, [numFramesMsgString '0'], numFramesMsgString);
            disp(dispStr);
        end
    end
    
    %------------------------------------------------------------------        
    % Undocumented methods
    %------------------------------------------------------------------
    methods (Access='public', Hidden)
        
        %------------------------------------------------------------------
        % Lifetime
        %------------------------------------------------------------------
        function delete(obj)
            % Delete VideoReader object.
            try
                delete(obj.VidReader);
            catch exception
                VideoReader.handleImplException( exception );
            end
        end
    end
    
    methods (Static, Access='private')
        
        function handleImplException(implException)
            % Translate the exceptions received from the
            % matlab.internal.VideoReader. This involves replacing the
            % errorID.
            errorID = implException.identifier;
            
            if ~startsWith(errorID, 'multimedia:')
                throwAsCaller(implException);
            end
            
            errorID = replace(errorID, 'multimedia', VideoReader.ErrorWarnPrefix);
            
            throwAsCaller(MException(errorID, implException.message));
        end
        
        function nvPairs = flattenNVPairs(args)
            % Convert Name-value pairs supplied during object construction
            % into a suitable format for inputParser. The object
            % constructor supports set-style syntax for name-value pairs
            % i.e. 
            % v = VideoReader(fileName, {'CurrentTime', 'Tag'}, {2, 'my
            % reader'})
            % This needs to be converted into standard name-value pair
            % inputs that can be suuplied to the inputParser.
            
            % As the properties can be provided as a cell array row-vector
            % or column-vector, we need to first convert it as a column
            % vector to allow flatten it
            args = cellfun(@(x) convertToCol(x), args, 'UniformOutput', false);
            nvPairs = vertcat(args{:});
            
            % Now, identify those elements that are property-names and
            % those that are values.
            nameLoc = cellfun(@(x) checkIfName(x), nvPairs);
            
            % Order them as an 2xN cell array with Names in the first row
            % and Values in the second row.
            nvPairs = [nvPairs(nameLoc) nvPairs(~nameLoc)]';
            
            % Convert it to Name, Value, Name, Value, ...
            nvPairs = nvPairs(:);
            
            % Helper function to convert cell arrays into a column vector.
            function out = convertToCol(in)
                if iscell(in) && isrow(in)
                    out = in';
                else
                    out = in;
                end
            end
            
            % Helper function to check if a cell array element is a Name or
            % a value.
            function tf = checkIfName(in)
                in = convertStringsToChars(in);
                % If the input is not a character, then it cannot be a
                % Name. It has to be a value.
                if ~ischar(in) 
                    tf = false;
                    return;
                end
                
                % If the input is a character, then check if it is one of
                % the supported Names. If not, most likely it is a value.
                tf = ismember(in, {'Tag', 'UserData', 'CurrentTime'});
            end
        end
        
        function outputFormat = validateOutputFormat(outputFormat, callerFcn)
            validFormats = {'native', 'default'};
            outputFormat = validatestring(outputFormat, validFormats, callerFcn, 'outputformat');
        end
    end
    
    methods (Static, Access='private', Hidden)
        function fileDesc = translateDescToLocale(fileExtension)
            switch upper(fileExtension)
                case 'M4V'
                    fileDesc = getString(message('MATLAB:audiovideo:VideoReader:formatM4V'));
                case 'MJ2'
                    fileDesc = getString(message('MATLAB:audiovideo:VideoReader:formatMJ2'));
                case 'MOV'
                    fileDesc = getString(message('MATLAB:audiovideo:VideoReader:formatMOV'));
                case 'MP4'
                    fileDesc = getString(message('MATLAB:audiovideo:VideoReader:formatMP4'));
                case 'MPG'
                    fileDesc = getString(message('MATLAB:audiovideo:VideoReader:formatMPG'));
                case 'OGV'
                    fileDesc = getString(message('MATLAB:audiovideo:VideoReader:formatOGV'));
                case 'WMV'
                    fileDesc = getString(message('MATLAB:audiovideo:VideoReader:formatWMV'));
                otherwise
                    % This includes formats such as AVI, ASF
                    fileDesc = getString(message('MATLAB:audiovideo:VideoReader:formatGeneric', upper(fileExtension)));
            end
        end
    end
    
    %------------------------------------------------------------------
    % Implementation of Abstract methods
    %------------------------------------------------------------------
    methods(Access='protected', Sealed)
        function currTime = parseCreationArgs(obj, varargin)
            % The object constructor allows name-value pairs to be passed
            % in similar to the SET syntax.
            if any(cellfun(@(x) iscell(x), varargin))
                nvPairs = VideoReader.flattenNVPairs(varargin);
            else
                nvPairs = varargin;
            end

            p = inputParser;
            p.addParameter('CurrentTime', NaN);
            p.addParameter('Tag', '');
            p.addParameter('UserData', []);

            try
                p.parse(nvPairs{:});
            catch
                error( message( 'MATLAB:audiovideo:VideoReader:UnsupportedNV', ...
                                 'CurrentTime', ...
                                 'Tag', ...
                                 'UserData' ) );
            end

            obj.Tag = p.Results.Tag;
            obj.UserData = p.Results.UserData;
            currTime = p.Results.CurrentTime;            
        end
        
        function initReader(obj, fileName, currentTime)
            % Properly initialize the object on construction or load.            
            
            if nargin == 2
                currentTime = NaN;
            end
            
            % Create underlying implementation.
            try
                % On Linux, computation of timestamps results in frame
                % decoding which might lead to performance regression in
                % few cases. See geck g1643379 for more details. We defer
                % this computation until timestamps are needed. On Windows
                % and Mac, timestamp generation does not affect performance
                % as no frame decoding is done. Based on platform, we pass
                % the appropriate value of 'ComputeTimestampsOnCreation'
                % Name-Value option to matlab.internal.VideoReader
                % constructor
                computeTimestampsOnCreation = ispc || ismac;
                obj.VidReader = matlab.internal.VideoReader( fileName, ...
                                        'ComputeTimestampsOnCreation', ...
                                         computeTimestampsOnCreation );
                                     
                % Perform actions such as caching the next frame after the
                % MIVR object has been created.
                postInit(obj, currentTime);
            catch exception
                VideoReader.handleImplException( exception );
            end
        end
        
        function createEmptyFrame(obj)
            % Create an empty cached frame. As this is the MATLAB
            % implementation, it is not necessary for the EmptyFrame.Data
            % to have the same dimensions as the actual video frame.
            obj.EmptyFrame.Data = [];
            obj.EmptyFrame.Timestamp = seconds(NaN);
            
            % Create an empty output. As this is the MATLAB implementation,
            % it is not necessary to have the same datatype as a valid
            % output.
            obj.EmptyOutput = [];
        end        
        
        % See audiovideo.internal.IVideoReader
        function cacheFrameTargetImpl(obj, timeInSecs)
            % Any exceptions generated upon reading ahead is no longer
            % valid and can be discarded.
            obj.ReadAheadException = [];
            
            try
                % Check if a valid time to seek was specified.
                if isnan(timeInSecs)
                    obj.StoredFrame = readNextFrame(obj.VidReader);
                    if isempty(obj.StoredFrame)
                        obj.StoredFrame = obj.EmptyFrame;
                    end
                else
                    obj.StoredFrame = readFrameAtPosition( obj.VidReader, ...
                                                    seconds(timeInSecs) );
                end
            catch ME
                % Keep track of the exception generated. This must be
                % thrown, as approprate, when the user attempts to read a
                % frame. 
                obj.ReadAheadException = ME;
            end
        end
        
        function outputformat = determineReadOutputFormat(~, callerFcn, outputformat)
            if nargin > 2
                outputformat = convertStringsToChars(outputformat);
                outputformat = VideoReader.validateOutputFormat( outputformat, callerFcn );
            end
            if nargin < 3
                outputformat = 'default';
            end
        end
        
        function checkIncompleteRead(obj, actNumFramesRead, frameRangeToRead)
            expNum = frameRangeToRead(2) - frameRangeToRead(1) + 1;
            if actNumFramesRead < expNum
                % Wait for a brief period to ensure that any errors that
                % might have occurred when reading the frames to be
                % processed. While not ideal, this code path is utilized
                % for an edge case condition i.e. reading a sequence of
                % frames from a file that encounters an error when decoding
                % frames. 
                pause(0.2);
                readNextFrame(obj.VidReader);
                warning(message('MATLAB:audiovideo:VideoReader:incompleteRead', ...
                    frameRangeToRead(1), frameRangeToRead(1)+actNumFramesRead-1));
            end
        end
        
        function flag = hasFrameLite(obj)
            % More frames are available for reading if:
            % a. Cached frame is non-empty AND
            % b. Any exception generated due to caching is not due to EOF
            flag = ~( isStoredFrameEmpty(obj) && ...
                      ( isempty(obj.ReadAheadException) || isEofException(obj) ) );
        end
    end
    
    %------------------------------------------------------------------
    % Helpers: Over-riding base-class methods
    %------------------------------------------------------------------
    methods (Access='protected', Sealed)
        function postReadFrameAction(obj)
            % If an error was generated when reading ahead, then throw that
            % exception. 
            throwNonEofException(obj);
        end
        
        function resetImpl(~)
            obj.ReadAheadException = [];
        end
        
        function videoFrames = readFramesUntilEnd(obj, startIndex)
            % This helper method reads video frames from the specified
            % index until the end of the file. Under normal conditions, the
            % output of this method would be an
            % H x W x P x (NUMFRAMES-STARTINDEX+1) numeric matrix.
            if nargin == 1
                startIndex = 1;
            end
            
            readOc = onCleanup( @() reset(obj) );
            try 
                videoFrames = readFramesUntilEnd@audiovideo.internal.IVideoReader(obj, startIndex);
            catch ME
                % If an exception was received, first check if it is
                % because the startIndex was out of bounds. This allows us
                % to avoid the penalty of frame counting under normal
                % conditions.
                checkIfIndexOutOfRange(obj, startIndex);
                
                % If not, handle the error.
                VideoReader.handleImplException(ME);
            end
        end
        
        function videoFrames = readFramesInIndexRange(obj, indexRange)
            % This helper method reads video frames in the specified
            % indexRange. Under normal conditions, the output of this
            % method would be an 
            % H x W x P x (INDEXRANGE(2) - INDEXRANGE(1) + 1) numeric
            % matrix. 
            try
                videoFrames = readFramesInIndexRange@audiovideo.internal.IVideoReader(obj, indexRange);
            catch ME
                % If an exception was received, first check if it is
                % because the startIndex was out of bounds. This allows us
                % to avoid the penalty of frame counting under normal
                % conditions.
                checkIfIndexOutOfRange(obj, indexRange);
                
                % If not, handle the error.
                VideoReader.handleImplException(ME);
            end
        end
        
        function videoFrame = readSingleFrame(obj, index)
            % This helper method reads a frame at the specified index.
            % Under normal conditions, the output of this method would be
            % an H x W x P numeric matrix.
            try
                videoFrame = readSingleFrame@audiovideo.internal.IVideoReader(obj, index);
            catch ME
                 % If an exception was received, first check if it is
                 % because the startIndex was out of bounds. This allows us
                 % to avoid the penalty of frame counting under normal
                 % conditions.
                 checkIfIndexOutOfRange(obj, index);
                 
                 % If not, throw the error.
                 throwAsCaller(ME);
            end
        end
        
        function videoFrame = readFrameAtIndex(obj, index)
            % Helper function that reads a frame at a specific index. This
            % helper does the actual reading of the frame and caching the
            % next one.
            
            % If an error was generated when reading ahead, then throw that
            % exception. 
            throwNonEofException(obj);

            try
               videoFrame = readFrameAtIndex@audiovideo.internal.IVideoReader(obj, index);
            catch ME
                obj.NextFrameIndexToRead = 0;
                rethrow(ME);
            end
            
            % This indicates that all frames have been read and EOF has been
            % reached. The NextFrameIndexToRead tracks the index of the frame
            % that has been cached. However, as no frames have been cached,
            % setting this value to 0.
            if isEofException(obj)
                obj.NextFrameIndexToRead = 0;
            end
        end
        
        function videoFrames = readFrameSequence(obj, indexRange)
            % Helper function that reads frames in the specified range.
            try
                videoFrames = readFrameSequence@audiovideo.internal.IVideoReader(obj, indexRange);
            catch ME
                if ~strcmp(ME.identifier, 'MATLAB:audiovideo:VideoReader:EndOfFile')
                    throwAsCaller(ME);
                end
            end
        end


    end
    
    %------------------------------------------------------------------
    % Helpers: Specific to this class
    %------------------------------------------------------------------
    methods (Access='private')
        function tf = isEofException(obj)
            % Check if the exception generated when reading ahead was due
            % to EOF or a genuine read failure.
            if isempty(obj.ReadAheadException)
                tf = false;
                return;
            end
            tf = strcmp(obj.ReadAheadException.identifier, 'multimedia:VideoReader:EndOfFile');
        end
        
        function throwNonEofException(obj)
            % Check if the cached exception is not an EOF exception and
            % throw it.
            if ~isempty(obj.ReadAheadException) && ~isEofException(obj)
                ME = obj.ReadAheadException;
                obj.ReadAheadException = [];
                VideoReader.handleImplException(ME);
            end
        end           
    end

end
