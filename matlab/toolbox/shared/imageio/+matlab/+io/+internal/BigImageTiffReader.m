classdef BigImageTiffReader < matlab.io.internal.ITiffReader
    %   matlab.io.internal.BigImageTiffReader Create an internal TIFF
    %   reader object for IPT's Bigimage use case.
    %   OBJ = matlab.io.internal.BigImageTiffReader(FILENAME) constructs an
    %         object that can read in image data and tags from the first
    %         image in the TIFF file.
    %   FILENAME is a character array or a string specifying the name of the
    %   TIFF file. By default, MATLAB looks for FILENAME on the MATLAB path.
    %
    %   OBJ = matlab.io.internal.BigImageTiffReader(FILENAME, "Name", "Value")
    %         constructs an object that can read image data and tags from
    %         an image in the TIFF file.
    %         The supported name-value pairs are:
    %         ImageIndex      - Index of the image in the TIFF file that is
    %                           to be read. This is a 1-based index.
    %
    %         IFDOffset       - Byte offset from the beginning of the TIFF
    %                           file to the image that is to be read. This
    %                           is a 0-based offset.
    %
    %   Methods:
    %       setInputStreamLimit     - Size of the internal buffer to store
    %                                 slices which are read asynchronously
    %       enqueueSlices           - Enqueue the slice numbers that need to
    %                                 be read from the image
    %       readCompleteSlice       - Read slices from all planes from the
    %                                 specified slice in the image.
    %       computeSliceNum         - Compute the index of the slice that
    %                                 contains the image data for the
    %                                 specified location. This depends upon
    %                                 the height, width of the slice and the
    %                                 planar configuration of the image
    %       computeSliceOrigin      - Compute the origin, in terms of image
    %                                 coordinates, for the specified slice
    %                                 number. This depends upon the height,
    %                                 width of the slice and the planar
    %                                 configuration of the image
    %   Properties
    %       FileName                -   Name of the file to be read
    %       FilePath                -   Path to the directory containing the
    %                                   file
    %       NumImages               -   Total Number of Image Directories
    %                                   present in the file
    %       CurrentImageDirectory   -   Index of the image directory that is
    %                                   currently being read
    %       ImageHeight             -   Height of the image in pixels
    %       ImageWidth              -   Width of the image in pixels
    %       ImageDataType           -   Type of the underlying image
    %       NumCompleteSlices       -   Total number of complete slices in
    %                                   the image.
    %                                   For stripped images, slice refers to a
    %                                   strip. For tiled images, slice refers
    %                                   to a tile.
    %       SliceHeight             -   Height of the slice in pixels
    %       SliceWidth              -   Width of the slice in pixels
    %       Organization            -   Layout of the image
    %       Photometric             -   Colorspace of the image
    %       SamplesPerPixel         -   Number of channels per pixel of the
    %                                   image
    %       BitsPerSample           -   Number of bits per channel of the
    %                                   image
    %       PlanarConfiguration     -   Storage scheme for each channel of the
    %                                   image
    %       Compression             -   Compression scheme used to compress
    %                                   image data
    %       ImageTags               -   TIFF tags present in the current
    %                                   directory
    %
    %   Example: Read a slice from the first image in a TIFF file
    %       % Construct a Tiff reader to read the first image from a TIFF file
    %       t = matlab.io.internal.BigImageTiffReader("example.tif");
    %
    %       % Set the total number of slices to read asynchronously.
    %       t.setInputStreamLimit(4);
    %
    %       % Buffer a list of slices asynchronously
    %       enqueueSlices(t, [4, 6, 7, 8]);
    %
    %       % Read the slices
    %       readCompleteSlice(t,4);
    %       readCompleteSlice(t,6);
    %       readCompleteSlice(t,7);
    %
    %   Example: Read the specified slices from the second image of the
    %   TIFF file
    %       % Construct a Bigimage Tiff reader to read the second image from a TIFF file
    %       t = matlab.io.internal.BigImageTiffReader("example.tif", "ImageIndex", 2);
    %
    %       % Buffer a list of slices asynchronusly
    %       enqueueSlices(t, 1:10)
    %
    %       % Read the first slice
    %       readCompleteSlice(t,1);
    
    % Copyright 2019-2023 The MathWorks, Inc.
    
    %------------------------------------------------------------------
    % General properties
    %------------------------------------------------------------------
    properties(GetAccess = 'protected', SetAccess='private',Transient)
        nonStreamingChannel % Instance of a asyncIO channel for
                            % for synchronous I/O.
                            %
                            % BigImageITR operates in two modes; read
                            % slices synchronously and read slices
                            % asynchronously. Using the same channel for
                            % synchronous and asynchronous I/O can lead to
                            % race conditions. The shared resource is the
                            % the TIFF File pointer which would could
                            % potentially run into data races.
                            %
                            % For example, if the Device plugin is reading
                            % slices from an image of a TIFF file
                            % in the background thread and during that time
                            % MATLAB requests to read a new slice, both
                            % MATLAB and the background thread will
                            % share the same file pointer and the device
                            % plugin would completely rely on the
                            % implementation of 3p/libTIFF to avoid data races.
                            %
                            % To avoid these unknowns and to avoid usage
                            % of lock or synchronization constructs which can
                            % potentially slow down the code, the idea is
                            % to separate the concerns into two channels;
                            % streaming channel and non-streaming channel.
                            % Each channel gets its own file pointer to
                            % work with thus avoiding any potential data races.
    end
    
    properties (SetAccess = 'private', Transient)
        NumCompleteSlices   % Total number of complete slices( tile or strip)
                            % in the image.
                            % This is a special property added for the
                            % bigimage usecase (Image Processing Toolbox).
                            % For chunky image, NumCompleteSlices is equal
                            % to NumSlices.
                            % For separate image,
                            % NumCompleteSlices =
                            % NumSlices/SamplesPerPixel. For example:
                            % An RGB Separate image with 300 slices
                            % will have a NumSlices = 300 for NumSlices and
                            % NumCompleteSlices = 100 (300/3).
    end
    
    
    properties(Access='private')
        requestedSlice = -1;    % A variable that acts like a lock to
                                % manage interrupts from timer functions
                                % generated by client code during reading
                                % slices inside readCompleteSlice method.
                                % This variable is set right before entering
                                % the section where a slice is to be read
                                % in the  streaming mode. The variable is
                                % unset when reading the slice is complete and
                                % all other necessary state changes are
                                % completed before exiting the streaming mode.
        
        NextSliceIndex = 1       % Specifies the next slice index in the buffer.
                                 % This is only required for error handling
        
        OrigSliceList =[]       % Slice List provided by user. This is required
                                % in order to handle the separate image use
                                % case. For separate image,
                                % readCompleteSlice needs to return data
                                % from all the planes for each requested
                                % slice. obj.OrigSliceList maintains the
                                % original list of slices provided by the
                                % user. obj.SliceList maintains the
                                % modified slice list to be read. The
                                % modified slice list contains the slice
                                % number corresponding to each plane for
                                % the requested slice.
    end
    
    properties(Access = 'private',Dependent)
        TagOptions          %  A struct containing the filename and image index or offset to get the mandatory tags
                            %    FileName
                            %    ImageIndex : Indicates the image to be read
                            %      OR
                            %    IDOffset - Indicates the byte offset from which to read the file
    end
    
    %------------------------------------------------------------------
    %  Public Methods
    %------------------------------------------------------------------
    methods
        %------------------------------------------------------------------
        %  Constructor
        %------------------------------------------------------------------
        function obj = BigImageTiffReader(filename, varargin)
            % Call the super class constructor
            obj = obj@matlab.io.internal.ITiffReader(filename,varargin{:});
            try
                % Get mandatory tags
                obj.MandatoryTags = matlab.io.internal.getMandatoryImageInfo(obj.TagOptions);
                
                % Set the properties
                setProperties(obj);
                
                % Set the number of complete slices
                if obj.MandatoryTags.PlanarConfiguration == "Separate"
                    obj.NumCompleteSlices = obj.NumSlices/obj.MandatoryTags.SamplesPerPixel;
                else
                    obj.NumCompleteSlices = obj.NumSlices;
                end
            catch ME
                throwAsCaller(ME);
            end
        end
        
        % Set the total number of complete slices in the image
        % This is a special function for bigimage usecase.
        function set.NumCompleteSlices(obj,value)
            obj.NumCompleteSlices = value;
        end
        
        % SETINPUTSTREAMLIMIT  Set the maximum number of slices available
        %                      for read at a time
        %   SETINPUTSTREAMLIMIT(TIFFOBJ, STREAMLIMIT) set the
        %   InputStreamLimit to the specified value. The value is between
        %   1 and Inf. If the specified limit is greater than the total
        %   number of slices in the image, then the channel will buffer
        %   upto the specified limit. If the stream limit is unset, then
        %   it will be set as Inf
        %   Example:
        %       % Set inputStreamLimit to 100
        %       t = matlab.io.internal.BigImageTiffReader("example.tif");
        %       setInputStreamLimit(t, 100);
        function setInputStreamLimit(obj,streamLimit)
            %Validate the number of output
            nargoutchk(0, 0);
            
            %Validate the input
            validateattributes(streamLimit,{'numeric'},{'scalar','positive','row', '<=', Inf});
            if ~isinf(streamLimit) && mod(streamLimit,1)~=0
                error('MATLAB:expectedInteger', 'Expected input to be integer-valued.');
            end
            
            % Set the stream limit
            obj.InputStreamLimit = streamLimit;
            
            % If the channel was opened previously, close the channel
            if ~isempty(obj.Channel)
                closeChannel(obj);
            end
            
            % Initialize the channel for reading
            initializeChannel(obj);
        end
        
        function enqueueSlices(obj,sliceNumbers)
            % ENQUEUESLICES  Asynchronously buffers slices from the TIFF
            % image
            %   IM = ENQUEUESLICES(TIFFOBJ, SLICENUMBERS) buffers slices
            %   specified by SLICENUMBERs from the image in the
            %   current directory asynchronously. If the InputStreamLimit
            %   is not already set, then InputStreamLimit is set to the
            %   default value which is Inf.
            %
            %   Example:
            %       % Enqueue slices 1, 3 , 5 and 8
            %       t = matlab.io.internal.BigImageTiffReader("example.tif");
            %       enqueueSlices(t, [1,3,5,8]);
            try
                %Validate the number of output
                nargoutchk(0, 0);
                
                %Validate the sliceList
                validateattributes(sliceNumbers,{'double'},{'integer','vector','positive','row',"<=" ,obj.NumSlices});
                
                % Set readInterface to RGB if image is YCbCr
                if obj.Photometric == "YCbCr"
                    obj.ReadInterface = "RGBA";
                end
                
                % Set the original slice list to the slices that the user
                % provided.
                obj.OrigSliceList = sliceNumbers;
                
                % If the image is separate, then update the
                % property SliceList with the slices from each plane
                % obj.SliceList is the one that goes to asyncIO and
                % fetches the data.
                if obj.PlanarConfiguration == "Separate"
                    obj.SliceList = [];
                    for i = 1:length(sliceNumbers)
                        if sliceNumbers(i) > obj.NumCompleteSlices
                            firstSlice = mod(sliceNumbers(i), obj.NumCompleteSlices);
                            if(firstSlice == 0)
                                firstSlice = obj.NumCompleteSlices;
                            end
                        else
                            firstSlice = sliceNumbers(i);
                        end
                        for j = 1:obj.SamplesPerPixel
                            newSliceList(j) = firstSlice + (j-1)* obj.NumCompleteSlices;
                        end
                        obj.SliceList = [obj.SliceList newSliceList];
                    end
                else
                    % Set the sliceList from the original slice list for
                    % chunky image
                    obj.SliceList = obj.OrigSliceList;
                end
                
                if isempty(obj.Channel)
                    % If the channel was not created then create
                    % the channel for asynchronous reading
                    initializeChannel(obj);
                    openChannel(obj);
                else
                    % A previous enqueue opened the channel.
                    % Close the channel to flush any old data
                    if(obj.Channel.isOpen)
                        closeChannel(obj);
                    end
                    openChannel(obj);
                end
                obj.NextSliceIndex = 1;
                
            catch ME
                throwAsCaller(ME);
            end
        end
        
        
        
        function data = readCompleteSlice(obj, sliceNumber)
            % READCOMPLETESLICE  Read data from all planes from a specific slice in the
            % image.
            %   IM = READCOMPLETESLICE(TIFFOBJ, SLICENUMBER) reads data from
            %   the slice specified by SLICENUMBER from the image in the
            %   current directory. READCOMPLETESLICE returns slice
            %   data for all the planes in the image.
            %
            %   The data is read in the image's native colorspace.
            %   For YCbCr image, the data is returned in RGB colorspace.
            %
            %   The output slice is an N-D numeric matrix. The datatype and number
            %   of channels in IM depend upon the image's native colorspace.
            %
            %   Example:
            %       % Read the 4th slice from an image in a TIFF file.
            %       t = matlab.io.internal.TiffReader("example.tif");
            %       enqueue(t,4);
            %       slice = readCompleteSlice(t, 4);
            try
                %Validate the number of output
                nargoutchk(0, 1);
                
                %Validate the slice number
                validateattributes(sliceNumber,{'double'},{'integer','scalar','positive',"<=" ,obj.NumSlices});
                
                % readCompleteSlice uses nonstreaming channel .i.e
                % reads the slice directly from disk if any of following
                % cases are true:
                % 1. asyncIO streaming channel is empty .i.e. client did
                %    not call enqueueSlices method to buffer slices for
                %    streaming mode OR
                %
                % 2. asyncIO streaming channel is open but reached end of
                %    stream .i.e. client is done reading all the buffered
                %    slices OR
                %
                % 3. The next slice in streaming channel is not the
                %    requested slice OR
                %
                % 4. The slice to read was in the process of reading in
                %    streaming channel when an interrupt from client code
                %    callbacked into this (readCompleteSlice) method again.
                if isempty(obj.Channel) ...
                        || obj.Channel.InputStream.isEndOfStream ...
                        || sliceNumber ~= obj.OrigSliceList(obj.NextSliceIndex)...
                        || isequal(obj.requestedSlice,sliceNumber)
                    % Check if the non streaming channel is created
                    if isempty(obj.nonStreamingChannel)
                        % Initializing the non-streaming channel assures
                        % that a new instance of device plugin is created
                        % which manages and its own Tiff file handle
                        initializeNonStreamingChannel(obj);
                        
                        % CurrentImageDirectory is set to -1 if IFDOffset is provided
                        if obj.CurrentImageDirectory ~= -1
                            option.ImageDirectory = obj.CurrentImageDirectory -1 ;
                        else
                            option.ImageDirOffset = obj.IFDOffset ;
                        end
                        
                        % ReadInterface is either 'Normal' or 'RGB'.
                        % g2155956 Set readInterface to RGB if image is YCbCr
                        if obj.Photometric == "YCbCr"
                            obj.ReadInterface = "RGBA";
                        end
                        
                        option.ReadInterface = obj.ReadInterface;
                        
                        % Set slices to empty
                        option.Slices = [];
                        
                        % Open the channel
                        obj.nonStreamingChannel.open(option);
                    end
                    
                    if obj.PlanarConfiguration == "Separate"
                        if sliceNumber > obj.NumCompleteSlices
                            firstSlice = mod(sliceNumber, obj.NumCompleteSlices);
                            if(firstSlice == 0)
                                firstSlice = obj.NumCompleteSlices;
                            end
                        else
                            firstSlice = sliceNumber;
                        end
                        
                        %Read the slices
                        for j = 1:obj.SamplesPerPixel
                            option.Slices = (firstSlice + (j-1)* obj.NumCompleteSlices)-1;
                            obj.nonStreamingChannel.execute("executeReadSlice",option);
                            data(j,:,:) = obj.nonStreamingChannel.Slice;
                        end
                    else % Chunky image
                        option.Slices = sliceNumber - 1;
                        obj.nonStreamingChannel.execute("executeReadSlice",option);
                        data = obj.nonStreamingChannel.Slice;
                    end
                    % A scalar NaN indicates that the reading failed. Throw
                    % an error
                    if isscalar(data) && isnan(data)
                        handleCorruptImage(obj);
                    end
                    % Transpose or permute
                    if obj.SamplesPerPixel == 1
                        data = transpose(data);
                    else
                        data = permute(data,[3 2 1]);
                    end
                    
                    % g2155956: If YCbCr image, then RGBA interface is used to read the
                    % the slice and hence the flipud is required. 3p/LibTIFF
                    % returns flipped data for RGBA Interface
                    if obj.Photometric == "YCbCr"
                        data = flipud(data(:,:,1:3));
                    end
                    return;% Done with nonstreaming channel. return
                else
                    % Section to read slice from asyncIO streaming channel.
                    obj.requestedSlice = sliceNumber; % Initialize the lock
                    
                    % Read the slice
                    % For separate, read slices for each plane in one shot.
                    if obj.PlanarConfiguration == "Separate"
                        samplesRead = 0;
                        countRequested = obj.SamplesPerPixel - samplesRead;
                        while countRequested > 0
                            [t, countRead] = obj.Channel.InputStream.read(countRequested);
                            if(countRead == 0)
                                % If there is a logic error and the code comes
                                % here .i.e. read from an empty channel
                                % then throw an error to user indicating the
                                % data could not be read due to some internal
                                % error. This is better than a stall
                                if(obj.Channel.InputStream.isEndOfStream)
                                    error(message('imageio:tiffreader:internalReadFailure'));
                                end
                                continue;
                            end
                            data(:, :, samplesRead+1:samplesRead+countRead) = t;
                            samplesRead = samplesRead + countRead;
                            countRequested = countRequested - countRead;
                        end
                    else
                        % For chunky image, read one slice which contains data
                        % for all planes
                        while true
                            [t, countRead] = obj.Channel.InputStream.read(1);
                            if(countRead == 0)
                                % If there is a logic error and the code comes
                                % here .i.e. read from an empty channel
                                % then throw an error to user indicating the
                                % data could not be read due to some internal
                                % error. This is better than a stall
                                if(obj.Channel.InputStream.isEndOfStream)
                                    error(message('imageio:tiffreader:internalReadFailure'));
                                end
                                continue;
                            end
                            data = t;
                            break;
                        end
                    end
                    
                    % If YCbCr image, then RGBA interface is used to read the
                    % the slice and hence the flipud is required. 3p/LibTIFF
                    % returns flipped data for RGBA Interface
                    if obj.Photometric == "YCbCr"
                        data = flipud(data(:,:,1:3));
                    end
                    
                    % Update NextSliceIndex. This is only required for
                    % handling error scenarios.
                    if obj.NextSliceIndex < numel(obj.OrigSliceList)
                        obj.NextSliceIndex = obj.NextSliceIndex + 1;
                    else
                        obj.NextSliceIndex = -1;
                    end
                    obj.requestedSlice = -1; % Release the lock
                end
            catch ME
                throwAsCaller(ME);
            end
        end
        
        % Close all channels and flush the input stream
        function closeChannel(obj)
            try
                % Call super class closeChannel first
                if ~isempty(obj.Channel) && obj.Channel.isOpen
                    closeChannel@matlab.io.internal.ITiffReader(obj);
                end
                if ~isempty(obj.nonStreamingChannel) && obj.nonStreamingChannel.isOpen
                    close(obj.nonStreamingChannel);
                end
            catch ME
                throwAsCaller(ME);
            end
        end
    end
    %------------------------------------------------------------------
    % Customize the save-load operation of the object
    %------------------------------------------------------------------
    methods(Static, Hidden)
        function obj = loadobj(infoLoaded)
            % LOADOBJ Loads the object from the MAT file into the MATLAB
            %   workspace
            fullName = fullfile(infoLoaded.FilePath, infoLoaded.FileName);
            if infoLoaded.IFDOffset == -1
                obj = matlab.io.internal.BigImageTiffReader(fullName, "ImageIndex", infoLoaded.CurrentImageDirectory);
            elseif infoLoaded.CurrentImageDirectory == -1
                obj = matlab.io.internal.BigImageTiffReader(fullName, "IFDOffset", infoLoaded.IFDOffset);
            else
                assert(false, "Indicates the MAT file is corrupt");
            end
        end
    end
    
    methods(Access='private')
        %Initialize a non-streaming channel.
        function initializeNonStreamingChannel(obj)
            import matlab.io.internal.ITiffReader;
            options = obj.TagOptions;
            pluginPath = toolboxdir(fullfile('shared','imageio','bin',computer('arch'),'tiff'));
            % Get path to tiff device plugin shared library
            devicePlugin = fullfile(pluginPath,'devicePlugin');
            % Get path to tiff device plugin shared library
            convPlugin = fullfile(pluginPath,'converterPlugin');
            % Register a message handler with the channel object
            errorMsgHandler = matlab.io.internal.TiffReaderMessageHandler;
            % Set the this object as the error handler
            errorMsgHandler.ErrorHandler = obj;
            % Create the channel with inputstreamlimit and outputstreamlimit
            % set to 0 to indicate that the channel is unbuffered
            obj.nonStreamingChannel = matlabshared.asyncio.internal.Channel( devicePlugin, ...
                convPlugin, ...
                Options = options,...
                StreamLimits = [0,0],...
                MessageHandler = errorMsgHandler);
        end
    end
    
    methods
        % Get the options to retireve mandatory tags
        function option = get.TagOptions(obj)
            option.FileName = convertStringsToChars(fullfile(obj.FilePath,obj.FileName));
            
            if obj.IFDOffset == -1
                % A -1 is substracted because 3p/libTIFF expects the image
                % directory in 0-based order.
                option.ImageDirectory = obj.CurrentImageDirectory-1;
            else
                % Otherwise the IFDOffset is valid.
                option.IFDOffset = uint64(obj.IFDOffset);
            end
        end
    end
end
