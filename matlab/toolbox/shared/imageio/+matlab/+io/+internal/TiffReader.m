classdef TiffReader < matlab.io.internal.ITiffReader 
    %   matlab.io.internal.TiffReader Create an internal TIFF reader object
    %
    %   OBJ = matlab.io.internal.TiffReader(FILENAME) constructs an object that
    %   can read in image data and tags from the first image in the TIFF file.
    %   FILENAME is a character array or a string specifying the name of the
    %   TIFF file. By default, MATLAB looks for FILENAME on the MATLAB path.
    %
    %   OBJ = matlab.io.internal.TiffReader(FILENAME, "Name", "Value")
    %   constructs an object that can read image data and tags from an image in
    %   the TIFF file. The supported name-value pairs are:
    %       ImageIndex      - Index of the image in the TIFF file that is to be
    %                         read. This is a 1-based index.
    %       IFDOffset       - Byte offset from the beginning of the TIFF file
    %                         to that image that is to be read. This is a
    %                         0-based offset.
    %
    %   Methods:
    %       readImage               -   Read the image in the current
    %                                   directory. If "PixelRegion" is 
    %                                   specified, read the portion 
    %                                   specified by the region boundary, 
    %                                   otherwise, the entire image will be
    %                                   read.
    %       readSlice               -   Read image data in the slice specified
    %                                   by the slice number or coordinates from
    %                                   the image in the current directory
    %       readSliceList           -   Read image data in the slices specified
    %                                   by the list of slice numbers from the
    %                                   image in the current directory
    %       computeSliceNum         -   Compute the index of the slice that
    %                                   contains the image data for the
    %                                   specified location. This depends upon
    %                                   the height, width of the slice and the
    %                                   planar configuration of the image
    %       computeSliceOrigin      -   Compute the origin, in terms of image
    %                                   coordinates, for the specified slice
    %                                   number. This depends upon the height,
    %                                   width of the slice and the planar
    %                                   configuration of the image
    %
    %   Properties
    %       FileName                -   Name of the file to be read
    %       FilePath                -   Path to the directory containing the
    %                                   file
    %       NumImages               -   Total Number of Image Directories
    %                                   present in the file
    %       CurrentImageDirectory   -   Index of the image directory that is
    %                                   currently being read
    %       ImageLength             -   Height of the image in pixels
    %       ImageWidth              -   Width of the image in pixels
    %       ImageDataType           -   Type of the underlying image
    %       NumSlices               -   Total number of slices in the image.
    %                                   For stripped images, slice refers to a
    %                                   strip. For tiled images, slice refers
    %                                   to a tile.
    %       NumCompleteSlices       -   Total number of complete slices in the image.
    %                                   For stripped images, slice refers to a
    %                                   strip. For tiled images, slice refers
    %                                   to a tile.
    %       SliceLength             -   Height of the slice in pixels
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
    %   Example: Read entire first image from a TIFF file
    %       % Construct a Tiff reader to read the first image from a TIFF file
    %       t = matlab.io.internal.TiffReader("example.tif");
    %
    %       % Read the entire image and display it
    %       im = readImage(t);
    %       figure, imshow(im);
    %
    %   Example: Read a slice from the second image in a TIFF file
    %       % Construct a Tiff reader to read the second image from a TIFF file
    %       t = matlab.io.internal.TiffReader("example.tif", "ImageIndex", 2);
    %
    %       % Determine number of slices in the image
    %       numSlices = t.NumSlices;
    %
    %       % Read the 4th slice from the image and display
    %       im = readSlice(t, 4);
    %       figure, imshow(im);
    %
    %   Example: Read entire image located at a specified byte offset in a TIFF
    %   file
    %       % Construct a Tiff reader to read the third image from a TIFF file
    %       t = matlab.io.internal.TiffReader("example.tif", "IFDOffset",
    %       413718);
    %
    %       % Read the entire image and display it
    %       im = readImage(t);
    %       figure, imshow(im);
    %

    % Copyright 2018-2024 The MathWorks, Inc.
    
    %------------------------------------------------------------------
    % General properties
    %------------------------------------------------------------------ 
    properties(Access='private',Transient)
        ImageInfoListener       % Listener object for handling TIFF metadata information event.
    end
    
    properties (SetAccess = 'private', Transient)
        NumCompleteSlices       % Total number of complete slices( tile or strip) in the image.
        % This is a special property added for the bigimage usecase (Image Processing Toolbox).
        % For chunky image, NumCompleteSlices is equal to NumSlices. For separate image,
        % NumCompleteSlices =
        % NumSlices/SamplesPerPixel. For example:
        % An RGB Separate image with 300
        % will have a NumSlices = 300 for NumSlices and NumCompleteSlices = 100 (300/3).
    end

    %------------------------------------------------------------------
    %  Public Methods
    %------------------------------------------------------------------
    methods
        %------------------------------------------------------------------
        %  Constructor
        %------------------------------------------------------------------
        function obj = TiffReader(filename,varargin)
            %Call the super class constructor.
            obj = obj@matlab.io.internal.ITiffReader(filename,varargin{:});
            
            try
                % Create an asyncIO channel
                initializeChannel(obj);
                % Create a weak reference to the object to prevent increasing its reference count.
                % This allows the object to be garbage collected if there are no other strong references.
                objWeakRef = matlab.lang.WeakReference(obj);
                % Register custom event for mandatory tags
                obj.ImageInfoListener = event.listener(obj.Channel, 'Custom', @(src,event)(objWeakRef.Handle.onCustomEvent(event)));
                
                % obj.OpenOptions is a dependent property. This will call
                % get.OpenOptions that returns a struct with the correct read
                % options.
                obj.openChannel();
                
                % Wait for the mandatory tag to be generated.
                while isempty(obj.MandatoryTags)
                    continue;
                end
            catch ME
                % If for some reason the channel is not created
                % successfully or the slices are not buffered, error
                % out. The internal Tiffreader will not be constructed.
                throwAsCaller(ME);
            end
        end
        
        %------------------------------------------------------------------
        %  Setter Methods for each of the dependent properties
        %------------------------------------------------------------------

        % Set the total number of complete slices in the image
        % This is a special function for bigimage usecase.
        function set.NumCompleteSlices(obj,value)
            obj.NumCompleteSlices = value;
        end

        %------------------------------------------------------------------
        %  Public Methods - READ* APIs of matlab.io.internal.TiffReader.
        %------------------------------------------------------------------
        function varargout = readImage(obj, varargin)
            % READIMAGE  Read entire image in the current directory
            %   IM = READIMAGE(TIFFOBJ) reads the entire image in the current
            %   directory. The output is in the image's native colorspace. The
            %   output IM is an N-D numeric matrix. The datatype and number of
            %   channels in IM depend upon the image's native colorspace.
            %   For YCbCr image, the data is returned in RGB colorspace.
            %
            %   Example:
            %       % Read an image from a TIFF file.
            %       t = matlab.io.internal.TiffReader("example.tif");
            %       im = readImage(t);
            %
            %   Example:
            %       % Read an image from a TIFF file, from row 10 to 50 and
            %       every other column from 5 to 100.
            %       t = matlab.io.internal.TiffReader("example.tif");
            %       im2 = readImage(t, "PixelRegion", {[10, 50], [5, 2,
            %       100]});
            %       For non-integer pixel region inputs, the floor of the
            %       value is used. If the function receives pixel region 
            %       input values that are outside of the range of the
            %       image, readImage will accept the values and return up
            %       to the bounds of the image. This design was chosen to
            %       maintain parity with legacy implementation of imread(). 

            try
                % Validate the outputs
                nargoutchk(0, 2);
                
                % If the color space of the image is YCbCr, then
                % readImage returns the data as an RGB image. Otherwise, it
                % returns the data in the color space that is specified in the
                % image. This is special case for the Bigimage usecase.
                if obj.Photometric == "YCbCr"
                    % Read the RGBA image from the channel.
                    [varargout{1}, varargout{2}] = obj.readRGBAImage(varargin{:});
                else
                    % Validate inputs:
                    % Setup the Inputparser to validate the input arguments.
                    parser = inputParser;
                    parser.FunctionName = "readImage";
                    
                    % Add name-value pair PixelRegion to the input parser. The
                    % default value is {}, which is an invalid input.
                    validatePixelRegion = @(x)validateattributes(x,{'cell'},{'numel',2}, '', 'PixelRegion');
                    addParameter(parser,"PixelRegion",{},validatePixelRegion);
                    
                    parse(parser, varargin{:});
                    
                    if ~isempty(parser.Results.PixelRegion)
                        % If the PixelRegion name-value pair is used, read
                        % the slices that contain the pixel region
                        im = readFullColorPixelRegion(obj, varargin{2});
                    else
                        % Read the slices from the channel and compose the final
                        % image
                        im = readFullColorImage(obj);
                    end
                    
                    % Post-processing of image based on Photometric configuration
                    % This is to be consistent with IMREAD.
                    
                    % Invert the image
                    if obj.Photometric == "MinIsWhite"
                        % TIFF image is logical
                        if(obj.BitsPerSample == 1)
                            im = ~im;
                            %TIFF image is not more than one byte
                        elseif obj.BitsPerSample <= 8
                            im = 2^(obj.BitsPerSample)-1-im;
                        end
                        
                        % TIFF image is in CIELAB format.  Issue a warning that we're
                        % converting the data to ICCLAB format, and correct the a* and b*
                        % values.
                    elseif obj.Photometric == "CIELab"
                        % Check to make sure we have the expected number of samples per pixel.
                        if (size(im,3) ~= 1) && (size(im,3) ~= 3)
                            error(message('imageio:tiffreader:unexpectedCIELabSamplesPerPixel',1,3));
                        end
                        
                        % Check that we have uint8 or uint16 data.
                        if ~ (isa(im,'uint8') || isa(im,'uint16'))
                            error(message('imageio:tiffreader:wrongCieLabDatatype'));
                        end
                        warning(message('imageio:tiffreader:CielabConversion'));
                        im = matlab.io.internal.cielab2icclab(im);
                    end
                    
                    % Store the image
                    varargout{1} = im;
                    
                    % Get the map
                    obj.Channel.execute("readColorMap");
                    varargout{2} = double(obj.Channel.ColorMap)/65535;
                end
            catch ME
                throwAsCaller(ME);
            end
        end
        
        function im = readSlice(obj,varargin)
            %READSLICE  Read data from a specific slice in the image
            %   IM = READSLICE(TIFFOBJ, SLICENUM) reads data from the slice
            %   specified in SLICENUM from the image in the current directory.
            %   The data is read in the image's native colorspace.
            %   For YCbCr image, the data is returned in RGB colorspace.
            %
            %   The output IM is an N-D numeric matrix. The datatype and number
            %   of channels in IM depend upon the image's native colorspace.
            %   For a image with chunky planar configuration, the dimension of
            %   IM is  H x W x P where H is the Height of image, W is Width of
            %   the image and P is the number of color channels.
            %   For image with separate planar configuration, IM is H x W.
            %
            %   IM = READSLICE(TIFFOBJ, [ROW, COL]) reads data
            %   from the slice specified by [ROW, COL] from a chunky image from the
            %   current directory.
            %
            %   IM = READSLICE(TIFFOBJ, [ROW, COL], plane) reads data from the slice
            %   specified by [ROW, COL] from a separate image from the
            %   current directory at the specified plane.
            %
            %   Example:
            %       % Read the 4th slice from an image in a TIFF file.
            %       t = matlab.io.internal.TiffReader("example.tif");
            %       im = readSlice(t, 4);
            %
            %       % Read the slice at (row,col) from a chunky image in a TIFF file.
            %       t = matlab.io.internal.TiffReader("example.tif");
            %       im = readSlice(t, [2,10]);
            
            % Validate the inputs.
            % If varargin has 1 element, then varargin is a sliceNumber or
            % [ROW, COL] pair. If varargin has 2 elements, then
            % varargin{1} is a [ROW,COL] pair and varargin{2} is the plane.
            % Otherwise error out.
            try
                narginchk(2,3);
                % Only slice number is provided
                if isscalar(varargin{1})
                    % Validate the input.
                    validateattributes(varargin{1},{'double'},{'integer','positive','<=', obj.NumSlices});
                    sliceNumber = varargin{1};
                else
                    % [row,col] is provided instead of slice number
                    validateattributes(varargin{1},{'double'},{'integer','row','positive','size',[1,2]});
                    % plane is provided as the third argument.
                    if nargin > 2
                        validateattributes(varargin{2},{'double'},{'integer','scalar','positive'});
                        sliceNumber = computeSliceNum(obj,varargin{1},varargin{2});
                    else
                        sliceNumber = computeSliceNum(obj,varargin{1});
                    end
                end
                
                % If the colorspace is YCbCr, then read the slice in RGB mode
                % This is a special case for bigimage usecase.
                if obj.Photometric == "YCbCr"
                    im = obj.readRGBASlice(sliceNumber);
                else
                    % Read the slice
                    im = obj.readFullColorSlice(sliceNumber,"Normal");
                end
            catch ME
                obj.SliceIndex = 1;
                throwAsCaller(ME);
            end
        end
        
        function imlist = readSliceList(obj,sliceNumbers)
            % READSLICELIST  Read data from the specific list of slices in the
            % image
            %   IMLIST = READSLICELIST(TIFFOBJ, SLICENUMBERS) reads data from
            %   all the slices specified in SLICENUMBERS from the image in the
            %   current directory. The data is read in the image's native
            %   colorspace.
            %
            %   The output IMLIST is an Mx1 cell array of N-D numeric matrices,
            %   where M is the number of slices specified. The datatype and
            %   number of channels of each element of IMLIST depend upon the
            %   image's native colorspace.
            %
            %   For YCbCr image, the data is returned in RGB colorspace.
            %   Example:
            %       % Read the 2nd, 4th, and 1st slicess from the second image
            %       in a TIFF file.
            %       t = matlab.io.internal.TiffReader("example.tif", "ImageIndex", 2);
            %       im = readSliceList(t, [2 4 1]);
            try
                %Validate the number of output
                nargoutchk(0, 1);
                
                % Validate the inputs
                validateattributes(sliceNumbers,{'double'},{'integer','vector','positive','row',"<=" ,obj.NumSlices});
                
                % Allocate a cell array that contains the output data.
                imlist = cell(1,numel(sliceNumbers));
                
                % SliceIndex contains a list of slice numbers.
                obj.SliceList = sliceNumbers;
                
                % If the image color space is YCbCr, then read the slice in RGB
                % color space. Otherwise, read the slice in the native
                % colorspace.
                if obj.Photometric == "YCbCr"
                    % ReadInterface is RGBA
                    obj.ReadInterface = "RGBA";
                    
                    % In case of readSliceList method,do not check the last state
                    % of the channel. Simply restart the channel with the list
                    % of slices that are to be read. The channel returns data only
                    % for the selected slice numbers.
                    restartChannel(obj);
                    
                    % Read the data from the channel for each slice number.
                    for index = 1:numel(sliceNumbers)
                        % Since the RGB image is returned as an inverted image
                        % from device plugin, use flipud to invert it back.
                        data = flipud(obj.readRawData());
                        rgb = data(:, :, 1:3);
                        imlist{index} = rgb;
                    end
                else
                    % ReadInterface is Normal
                    obj.ReadInterface = "Normal";
                    
                    % In case of readSliceList method, do not check the last state
                    % of the channel. Simply restart the channel with the list
                    % of slices that are to be read. The channel returns data only
                    % for the selected slice numbers.
                    restartChannel(obj);
                    
                    % Read the data from the channel for each slice number
                    for index = 1: numel(sliceNumbers)
                        imlist{index} = obj.readRawData();
                    end
                end
                % Reset the slice list to empty so that in the next
                % read* call, the correct options are passed to device plugin
                obj.SliceList = [];
            catch ME
                obj.SliceList = [];
                throwAsCaller(ME);
            end
        end
        
        function im = readCompleteSlice(obj, slicePosition)
            % READCOMPLETESLICE  Read data from all planes from a specific slice in the
            % image.
            %   IM = READCOMPLETESLICE(TIFFOBJ, SLICEPOSITION) reads data from
            %   the slice specified by SLICEPOSITION from the image in the
            %   current directory. SLICEPOSITION is either a SLICENUMBER or
            %   [ROW,COL]. If SLICEPOSITION is [ROW,COL], then for separate
            %   planar configuration images, READCOMPLETESLICE returns slice
            %   data for all the planes in the image.
            %
            %   The data is read in the image's native colorspace.
            %   For YCbCr image, the data is returned in RGB colorspace.
            %
            %   The output IM is an N-D numeric matrix. The datatype and number
            %   of channels in IM depend upon the image's native colorspace.
            %
            %   Example:
            %       % Read the 4th slice from an image in a TIFF file.
            %       t = matlab.io.internal.TiffReader("example.tif");
            %       im = readcCompleteSlice(t, 4);
            %
            %       % Read the slice at (row,col) from an image in a TIFF file.
            %       t = matlab.io.internal.TiffReader("example.tif");
            %       im = readCompleteSlice(t, [2,10]);
            %
            try
                % Validate the number of inputs.
                narginchk(2,2);
                
                % readCompleteSlice falls back to readSlice if the image
                % is Chunky or has YCbCr color space. If the image is separate
                % and in native colorspace, then it requires special handling.
                % This function is specifically written for bigimage workflow.
                if obj.PlanarConfiguration == "Chunky" || obj.Photometric == "YCbCr"
                    % Simply call readSlice()
                    im = readSlice(obj,slicePosition);
                else
                    % If data is a sliceNumber, check that it is a valid slice
                    % number. After that compute the corresponding slice number
                    % for each of the planes.
                    
                    % For example, for an RGB separate image, if the slice number
                    % for R plane is 45 and the total number of slice is 450, then
                    % corresponding slice in G plane is 45 + (450/3) = 195 amd
                    % corresponding slice in B plane is 45 + 2*(450/3) = 345.
                    % Hence the slices to be retrieved are [45 , 195 , 345 ].
                    
                    if isscalar(slicePosition)
                        % Validate the input.
                        validateattributes(slicePosition,{'double'},{'integer','positive','<=', obj.NumSlices});
                        if slicePosition > obj.NumCompleteSlices
                            firstSlice = mod(slicePosition,obj.NumCompleteSlices);
                            if(firstSlice == 0)
                                firstSlice = obj.NumCompleteSlices;
                            end
                        else
                            firstSlice = slicePosition;
                        end
                        
                        for i=1:obj.SamplesPerPixel
                            sliceList(i) = firstSlice + (i-1) * obj.NumCompleteSlices;
                        end
                    else
                        % If the input is in form of [ROW,COL], then compute
                        % the slice number corresponding to [ROW, COL] for each
                        % plane. The slice list is already sorted in this case.
                        for i=1:obj.SamplesPerPixel
                            sliceList(i) = obj.computeSliceNum(slicePosition,i);
                        end
                    end
                    % Once the sliceList is ready, initalize the channel
                    % options. The channel contains only the requrested slice
                    % numbers
                    obj.SliceList = sliceList;
                    obj.ReadInterface = "Normal";
                    restartChannel(obj);
                    
                    % Read the data from the channel and compose the final
                    % slice.
                    for index = 1: numel(sliceList)
                        im(:,:,index) = obj.readRawData();
                    end
                    % Reset the slice list to empty so that in the next
                    % read* call, the correct options are passed to device plugin
                    obj.SliceList = [] ;
                end
            catch ME
                obj.SliceIndex = -1;
                obj.SliceList = [];
                throwAsCaller(ME);
            end
        end
        
        function imlist = readCompleteSliceList(obj,sliceNumbers)
            % READCOMPLETESLICELIST  Reads the data from all planes from the
            % specific list of slices in the image.
            %   IMLIST = READCOMPLETESLICELIST(TIFFOBJ, SLICENUMBERS) reads data from
            %   all the slices specified in SLICENUMBERS from the image in the
            %   current directory. The data is read in the image's native
            %   colorspace. The output IMLIST is an Mx1 cell array of N-D
            %   numeric matrices, where M is the number of slices specified.
            %   The datatype and number of channels of each element of IMLIST
            %   depend upon the image's native colorspace.
            %   For YCbCr image, the data is returned in RGB colorspace.
            %
            %   Example:
            %       % Read the 2nd, 4th, and 1st slicess from the second image
            %       in a TIFF file.
            %       t = matlab.io.internal.TiffReader("example.tif", "ImageIndex", 2);
            %       im = readCompleteSliceList(t, [2 4 1]);
            
            try
                % Allocate a cell array that contains the output data for each
                % slice number
                imlist = cell(1,numel(sliceNumbers));
                % readCompleteSliceList() falls back to readSliceList() if the image
                % is Chunky or has YCbCr color space. If the image is separate
                % and in native colorspace, then it requires special handling.
                % This function is specifically written for bigimage workflow.
                if obj.PlanarConfiguration == "Chunky" || obj.Photometric == "YCbCr"
                    imlist = obj.readSliceList(sliceNumbers);
                else
                    % Validate the inputs
                    validateattributes(sliceNumbers,{'double'},{'integer','vector','positive','row',"<=" ,obj.NumSlices});
                    
                    % For separate image, readCompletSliceList fall back to readCompleteSlice for
                    % each individual slice number.
                    for i = 1: numel(sliceNumbers)
                        imlist{i} = obj.readCompleteSlice(sliceNumbers(i));
                    end
                end
            catch ME
                throwAsCaller(ME);
            end
        end
        
        function varargout = readRGBAImage(obj, varargin)
            % READRGBAIMAGE  Read image using RGBA interface
            %   [IM, aplha] = READIRGBAMAGE(TIFFOBJ, varargin) reads the image and
            %   the alpha matting data from the current directory in RGB
            %   Format.
            %   Example:
            %       % Read an image from a TIFF file.
            %       t = matlab.io.internal.TiffReader("example.tif");
            %       im = readRGBAImage(t);
            try
                % Validate the outputs
                nargoutchk(0, 2);
                
                % Validate inputs:
                % Setup the Inputparser to validate the input arguments.
                parser = inputParser;
                parser.FunctionName = "readRGBAImage";
                
                % Add name-value pair PixelRegion to the input parser. The
                % default value is {}, which is an invalid input.
                validatePixelRegion = @(x)validateattributes(x,{'cell'},{'numel',2}, '', 'PixelRegion');
                addParameter(parser,"PixelRegion",{},validatePixelRegion);
                
                parse(parser, varargin{:});
                
                % if PixelRegion name-value pair is used
                if ~isempty(parser.Results.PixelRegion)
                     % If the PixelRegion name-value pair is used, read
                     % the slices that contain the pixel region and crop to
                     % return the specified pixel region
                    [varargout{1}, varargout{2}] = readRGBAPixelRegion(obj, varargin{2});
                    return;
                end
                
                % Restart the channel if the channel is not ready
                % to return RGBA slices from 1 to total number of slices.
                if obj.ReadInterface ~= "RGBA" || ...
                        obj.SliceIndex ~= 1
                    
                    obj.ReadInterface = "RGBA";
                    obj.SliceIndex = 1 ;
                    restartChannel(obj);
                end
                
                % Acquire the image and alpha from the asyncIO channel and 
                % stitch together
                [im, alpha] = composeRGBAImage(obj, [1, 1], ...
                    [obj.ImageHeight, obj.ImageWidth]);
                
                % Retrieve the image channel from data.
                varargout{1} = im(:, :, 1:3);
                
                % Retrieve the alpha channel from data
                varargout{2} = alpha;
                
                %Reset the slice number to an invalid value since the
                % entire image is done reading.
                obj.SliceIndex = -1;
            catch ME
                obj.SliceIndex = -1;
                throwAsCaller(ME);
            end
        end
        
        function varargout = readRGBASlice(obj,sliceNumber)
            % READRGBASLICE  Read data from a specific slice in RGB colorspace
            %   [IM,ALPHA] = READRGBASLICE(TIFFOBJ, SLICENUMBER) reads data and
            %   alpha matting data from the slice specified in SLICENUMBER from
            %   the image in the current directory. The data is read in the
            %   image's RGB colorspace.
            %
            %   Example:
            %       % Read the 4th slice from an image in a TIFF file.
            %       t = matlab.io.internal.TiffReader("example.tif");
            %       im = readRGBASlice(t, 4);
            try
                %Validate the number of output
                nargoutchk(0, 2);
                
                % Validate input
                validateattributes(sliceNumber,{'double'},{'integer','scalar','positive','row','<=', obj.NumSlices});
                
                % Read the data from the channel.
                data = flipud(obj.readFullColorSlice(sliceNumber,"RGBA"));
                
                % Retrieve the RGB part of the data
                varargout{1} = data(:, :, 1:3);
                
                % Retrieve the alpha channel o981-15f the data
                varargout{2} = data(:, :, 4);
            catch ME
                obj.SliceIndex = 1;
                throwAsCaller(ME);
            end
        end
        
        function varargout= readRGBASliceList(obj,sliceNumbers)
            % READRGBASLICELIST  Read data from specific slices in RGB
            % colorspace
            %   IMLIST = READRGBASLICELIST(TIFFOBJ, SLICENUMBERS) reads data
            %   and alpha matting data from the slices specified in
            %   SLICENUMBERS from the image in the current directory.
            %   The data is read in the image's RGB colorspace.
            %
            %   The output IMLIST is an Mx1 cell array where each slice data is
            %   of dimension H x W x 3 where H is the height of the image, W
            %   is the width of the image and 3 is the color channel for
            %   R, G and B respectively.
            %
            %   Example:
            %       % Read the 2nd, 4th and 1ST slice from an image in a TIFF file.
            %       t = matlab.io.internal.TiffReader("example.tif", "ImageIndex", 2);
            %       [im,alpha] = readRGBASliceList(t, [2 4 1]);
            
            try
                %Validate the number of output
                nargoutchk(0, 2);
                
                % Validate the inputs
                validateattributes(sliceNumbers,{'double'},{'integer','vector','positive','row',"<=" ,obj.NumSlices});
                
                % Allocate a cell array for all the RGB data for each slice
                varargout{1} = cell(1,numel(sliceNumbers));
                
                % Allocae a cell array for all the Alpha channel for each
                % slice.
                varargout{2} = cell(1,numel(sliceNumbers));
                
                % In case of readSliceList method, do not check the last state
                % of the channel. Simply restart the channel with the list
                % of slices that are to be read. The channel returns data only
                % for the selected slice numbers.
                obj.SliceList = sliceNumbers;
                obj.ReadInterface = "RGBA";
                % Flush the old data in channel and buffer the specifed slices
                restartChannel(obj);
                
                % Read the data from the channel
                for index = 1:numel(sliceNumbers)
                    %flipud is used because the device plugin returns a flipped
                    %image
                    data = flipud(obj.readRawData());
                    varargout{1}{index} = data(:, :, 1:3);
                    varargout{2}{index} = data(:, :, 4);
                end
                % Reset the slice list to empty so that in the next
                % read call, the correct options are passed to device plugin
                obj.SliceList = [];
            catch ME
                obj.SliceList = [];
                throwAsCaller(ME);
            end
        end
              
        function [y, cb, cr] = readYCbCrImage(obj)
            % READYCBCRIMAGE  Read YCBCR image
            %   [Y, Cb, Cr] = READYCBCRIMAGE(TIFFOBJ) reads the image and
            %   returns the Y, Cb, Cr component of the image data.
            %   For non-YCbCr image, readYCbCrImage errors out.
            %   Example:
            %       % Read an image from a TIFF file.
            %       tiff = matlab.io.internal.TiffReader("example.tif");
            %       [Y, Cb, Cr] = readYCbCrImage(t);
            
            try
                %Validate the number of output
                nargoutchk(0, 3);
                
                %Validate the input
                % Error out if the color space is not YCbCr.
                if obj.Photometric ~= "YCbCr"
                    error(message('imageio:tiffreader:notYCbCrImage'));
                end
                if obj.PlanarConfiguration == "Separate" || obj.SamplesPerPixel ~= 3
                    error(message('imageio:tiffreader:unsupportedYCbCrConfiguration'));
                end
                % Check to see if the options are correct
                % in order to ensure that the channel provides
                % the data in the expected format.
                
                % For example for a YCbCr image, the data is
                % read slice-by-slice starting from the first slice
                % and in YCbCr colorspace. Therfore SliceIndex is
                % 1, ReadMode is 'Slice' and ReadInterface is 'Normal'.
                
                % If any one of this parameters do not match, then
                %  flush out the existing data from the channel first.
                
                if  obj.SliceIndex ~= 1 || ...
                        obj.ReadInterface ~= "Normal"
                    obj.SliceIndex = 1;
                    obj.ReadInterface = "Normal";
                    % Flush the channel and read new data into the
                    % channel in the expected format.
                    restartChannel(obj);
                end
                % Total number of slices
                remainingSlices = obj.NumSlices ;
                
                % Read the data from the channel.
                imageLength = obj.ImageHeight;
                imageWidth = obj.ImageWidth;
                bitsPerSample = obj.BitsPerSample;
                sampleFormat = obj.MandatoryTags.SampleFormat';
                subsampling = obj.MandatoryTags.YCbCrSubSampling';
                sliceWidth = obj.SliceWidth;
                sliceLength = obj.SliceHeight;
                
                y = obj.constructBlankOutputImage( [imageLength imageWidth], bitsPerSample, sampleFormat );
                
                chromaDims = ceil([imageLength / subsampling(2) imageWidth / subsampling(1)]);
                cb = obj.constructBlankOutputImage(chromaDims, bitsPerSample, sampleFormat );
                cr = obj.constructBlankOutputImage(chromaDims, bitsPerSample, sampleFormat );
                
                yidx = 1;
                while yidx < imageLength
                    numRowsLuma = min(sliceLength, imageLength - yidx + 1);
                    if numRowsLuma == 0
                        numRowsLuma = sliceLength;
                    end
                    numRowsChroma = numRowsLuma / subsampling(2);
                    
                    xidx = 1;
                    while xidx < imageWidth
                        numColsLuma = min(sliceWidth, imageWidth - xidx + 1);
                        if numColsLuma == 0
                            numColsLuma = sliceWidth;
                        end
                        numColsChroma = ceil(numColsLuma / subsampling(1));
                        
                        [y1, cb1, cr1] = obj.readYCbCrSliceHelper();
                        remainingSlices = remainingSlices - 1;
                        
                        if remainingSlices == 0 % If all slices are read
                            % Check if the last slice is all NaN
                            % The last slice is NaN only when all the
                            % previous slices were also corrupted. This
                            % is done to reliably communicate from the
                            % asyncIO thread that all the slices are
                            % corrupted. The alternative is to return an
                            % error event from asyncIO but that is not
                            % a reliable solution.
                            if  all(isnan(y1(:)) == 1 ) ||  all(isnan(cb1(:)) == 1 ) ||  all(isnan(cr1(:)) == 1 )
                                handleCorruptImage(obj);
                            end
                        end
                        y(yidx:yidx+numRowsLuma-1, xidx:xidx+numColsLuma-1) = y1;
                        
                        yidxChroma = (yidx - 1)/subsampling(2) + 1;
                        xidxChroma = (xidx - 1)/subsampling(1) + 1;
                        
                        cb(yidxChroma:yidxChroma+numRowsChroma-1, xidxChroma:xidxChroma+numColsChroma-1) = cb1;
                        cr(yidxChroma:yidxChroma+numRowsChroma-1, xidxChroma:xidxChroma+numColsChroma-1) = cr1;
                        
                        xidx = xidx + numColsLuma;
                    end
                    
                    yidx = yidx + numRowsLuma;
                end
                
                % Keep the channel ready for the next operation
                restartChannel(obj);
            catch ME
                throwAsCaller(ME);
            end
        end
        
        function [y, cb, cr] = readYCbCrSlice(obj,varargin)
            % READYCBCRSLICE  Read YCBCR slice
            %   [O1, O2, O3] = READYCBCRSLICE(TIFFOBJ, SLICENUM) reads the
            %   Y, Cb and Cr components from the slice specified in SLICENUM
            %   from the image in the current directory.
            %   For true color image, readYCbCrSlice will error out
            %
            %   [O1, O2, O3] = READYCBCRSLICE(TIFFOBJ, [row, col]) reads
            %   the Y, Cb and Cr components from the slice specified by [row,col]
            %   from an image in the current directory.
            %
            %   [O1, O2, O3] = READYCBCRSLICE(TIFFOBJ, [row, col], plane)
            %   reads the Y, Cb and Cr components from the slice specified
            %   by [row,col] from an image in the current directory.
            %
            %   Example:
            %       % Read an image from a TIFF file.
            %       tiff = matlab.io.internal.TiffReader("example.tif");
            %       [Y, Cb, Cr] = readYCbCrSlice(t);
            try
                % Validate the number of output
                nargoutchk(0, 3);
                
                % Validate the inputs
                if obj.Photometric ~= "YCbCr"
                    error(message('imageio:tiffreader:notYCbCrImage'));
                end
                if obj.PlanarConfiguration == "Separate" || obj.SamplesPerPixel ~= 3
                    error(message('imageio:tiffreader:unsupportedYCbCrConfiguration'));
                end
                
                % Validate the inputs.
                % If varargin has 1 element, then varargin is a sliceNumber or
                % [ROW, COL] pair. If varargin has 2 elements, then
                % varargin{1} is a [ROW,COL] pair and varargin{2} is the plane.
                % Otherwise error out.
                if numel(varargin)  == 1
                    % if varargin is [ROW,COL], compute the slice number.
                    if ~isscalar(varargin{1})
                        sliceNumber = computeSliceNum(obj,varargin{1});
                    else
                        validateattributes(varargin{1},{'double'},{'integer','vector','positive','<=', obj.NumSlices});
                        sliceNumber = varargin{1};
                    end
                elseif numel(varargin) == 2
                    % varargin{1} is [ROW,COL] and varargin{2} is plane.
                    validateattributes(varargin{1},{'double'},{'integer','vector','positive'});
                    validateattributes(varargin{2},{'double'},{'integer','scalar','positive'});
                    % Compute the slice number
                    sliceNumber = computeSliceNum(obj,varargin{1},varargin{2});
                else
                    error(message('imageio:tiffreader:BadInputArguments'));
                end
                
                % Check to see if the options are correct
                % in order to ensure that the channel provides
                % the data in the expected format.
                
                % For example for a YCbCr slice, the data is
                % read as a slice in YCbCr colorspace.
                % SliceIndex represent the next slice available in the
                % channel to be read. If SliceIndex is equal to the
                % requested sliceNumber, it means the slice is already
                % available in the channel to be read.
                
                % If any one of this parameters do not match, then
                % flush out the existing data from the channel and then
                % start buffering the data in the channel starting from the
                % the specified slice number.
                
                %  The channel buffers all the slices from sliceNumber upto
                %  the size limit of the channel. Reading one slice from
                %  the channel will push the next slice from the TIFF image
                %  into the channel. The process continues until there is
                %  no more slices left in the TIFF image.
                
                if  obj.SliceIndex ~= sliceNumber || ...
                        obj.ReadInterface ~= "Normal"
                    
                    obj.SliceIndex = sliceNumber;
                    obj.ReadInterface = "Normal";
                    % Flush the channel and read new data into the channel.
                    restartChannel(obj);
                end
                
                % Read the data from the channel
                [y,cb,cr]= readYCbCrSliceHelper(obj);
                
                % Increment the sliceIndex to the next slice Number in order
                % to represent the true next slice number that is
                % available to be read from the channel.
                if obj.SliceIndex < obj.NumSlices
                    obj.SliceIndex = sliceNumber + 1;
                else
                    % If  slice read was the last slice, then set the slice index
                    % to 1 again and buffer the slices in the channel for the next
                    % call to readSlice.
                    obj.SliceIndex = 1;
                    restartChannel(obj);
                end
            catch ME
                obj.SliceIndex = 1;
                throwAsCaller(ME);
            end
        end
        
        function [o1, o2, o3] = readYCbCrSliceList(obj,sliceNumbers)
            % READSLICELIST  Read data from the specific list of slices in the
            % image
            %   IMLIST = READYCBCRSLICELIST(TIFFOBJ, SLICENUMLIST) reads data from
            %   all the slices specified in SLICENUMLIST from the image in the
            %   current directory. The data is read in YCBCR format.
            %   Example:
            %       % Read the 2nd, 4th, and 1st slices from the second image
            %       in a TIFF file.
            %       t = matlab.io.internal.TiffReader("example.tif", "ImageIndex", 2);
            %       im = readYCbCrSliceList(t, [2 4 1]);
            
            try
                % Validate the number of output
                nargoutchk(0, 3);
                
                %Validate the input
                if obj.Photometric ~= "YCbCr"
                    error(message('imageio:tiffreader:notYCbCrImage'));
                end
                if obj.PlanarConfiguration == "Separate" || obj.SamplesPerPixel ~= 3
                    error(message('imageio:tiffreader:unsupportedYCbCrConfiguration'));
                end
                
                % Validate the sliceNumbers
                validateattributes(sliceNumbers,{'double'},{'integer','vector','positive', '<=',obj.NumSlices});
                
                %Allocate a cell array for Y , Cb and Cr
                o1 = cell(1,numel(sliceNumbers));
                o2 = cell(1,numel(sliceNumbers));
                o3 = cell(1,numel(sliceNumbers));
                
                % In case of readYCbCrSliceList method, do not check the last state
                % of the channel. Simply restart the channel with the list
                % of slices that are to be read. The channel returns data only
                % for the selected slice numbers.
                obj.SliceList = sliceNumbers ;
                obj.ReadInterface = "Normal";
                % Flush the channel and buffer new data in the channel
                restartChannel(obj);
                
                % Read the data from the channel
                for index =  1:numel(sliceNumbers)
                    [o1{index},o2{index},o3{index}] = readYCbCrSliceHelper(obj);
                end
                
                % Reset the slice list to empty so that in the next
                % read call, the correct options are passed to device plugin
                obj.SliceList = [];
            catch ME
                obj.SliceList = [];
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
                obj = matlab.io.internal.TiffReader(fullName, "ImageIndex", infoLoaded.CurrentImageDirectory);
            elseif infoLoaded.CurrentImageDirectory == -1
                obj = matlab.io.internal.TiffReader(fullName, "IFDOffset", infoLoaded.IFDOffset);
            else
                assert(false, "Indicates the MAT file is corrupt");
            end
        end
    end

    %------------------------------------------------------------------
    % Private methods -Helper methods to support the public interfaces
    %------------------------------------------------------------------
    methods(Access='private')
        % Get Tiff metadata tags as a custom event
        function onCustomEvent(obj, event)
            if strcmp(event.Type,'MandatoryTags')
                obj.MandatoryTags = event.Data;
                setProperties(obj);
                % TODO: Remove setting numCompleteSlices once tests are
                % updated
                % Set the number of complete slices
                if obj.MandatoryTags.PlanarConfiguration == "Separate"
                    obj.NumCompleteSlices = obj.NumSlices/obj.MandatoryTags.SamplesPerPixel;
                else
                    obj.NumCompleteSlices = obj.NumSlices;
                end
            end
        end
        
        % Restart the AsyncIO channel with new Slice number
        function restartChannel(obj)
            obj.closeChannel();
            % obj.OpenOptions is a dependent property
            % This will call get.OpenOptions to get the correct options for
            % read.
            obj.openChannel();
        end
        
        % Read the full complete image from the Tiff file.
        function im = readFullColorImage(obj)
            % Check to see if the options are correct
            % in order to ensure that the channel provides
            % the data in the expected format.
            
            % For example for a grayscale image, the data is
            % read slice-by-slice starting from the first slice
            % and in grayscale colorspace. Therfore SliceIndex is
            % 1, ReadMode is 'Slice' and ReadInterface is 'Normal'.
            
            % If any one of this parameters do not match, then
            % flush out the existing data from the channel first.
            
            % The channel contains all the slices from slice number 1
            % till the InputStreamLimit of the channel. Reading one slice
            % from the channel, pushes the next available slice from
            % the TIFF image into the channel.
            try
                if  obj.SliceIndex ~= 1 || ...
                        obj.ReadInterface ~= "Normal"
                    
                    obj.SliceIndex = 1;
                    obj.ReadInterface = "Normal";
                    
                    % Flush the channel and read new data into the
                    % channel in the expected format.
                    restartChannel(obj);
                end
                
                % Read the slices from the asyncIO channel and compose the
                % image
                im = composeFullColorImage(obj, [1, 1], ...
                    [obj.ImageHeight, obj.ImageWidth], obj.NumSlices);
                
                % Invalidate the slice index so that next call to readImage
                % for the same image, restarts the channel.
                obj.SliceIndex = -1;
            catch ME
                obj.SliceIndex = -1;
                throwAsCaller(ME);
            end
        end
        
        % Read the specified pixel region from the Tiff file.
        function im = readFullColorPixelRegion(obj, pixelRegion)
            try
                sliceWidth = obj.SliceWidth;
                sliceHeight = obj.SliceHeight;
%                 numSlicesInXDir = ceil(obj.ImageWidth / sliceWidth);
%                 numSlicesInYDir = ceil(obj.ImageHeight / sliceHeight);
%                 numSlicesInPlane = numSlicesInXDir * numSlicesInYDir;
                
                % Save the pixel region values to a struct
                regionStruct = obj.processPixelRegion(pixelRegion, ...
                    [obj.ImageHeight, obj.ImageWidth]);
%                 
%                 % Compute the bounds of the pixel region in terms of slice
%                 % number
%                 topLSlice = computeSliceNum(obj, [regionStruct(1).startIdx, ...
%                     regionStruct(2).startIdx]);
%                 
%                 botRSlice = computeSliceNum(obj, [regionStruct(1).stopIdx, ...
%                     regionStruct(2).stopIdx]);
%                 
%                 % Compute the slice subscript bounds
%                 rowsToRead = ceil(topLSlice/numSlicesInXDir): ...
%                              ceil(botRSlice/numSlicesInXDir);
%                 colsToRead = (mod(topLSlice - 1, numSlicesInXDir) + 1: ...
%                               mod(botRSlice - 1, numSlicesInXDir) + 1)';
%                 slicesToReadFirstPlane = (rowsToRead - 1) * numSlicesInXDir + colsToRead;
%                 slicesToReadFirstPlane = slicesToReadFirstPlane(:);
%                 % Orgin of top left slice
%                 topLSliceOrigin = computeSliceOrigin(obj, topLSlice);
%                 
%                 % End coordinate of bottom right slice
%                 botRSliceEnd = min(computeSliceOrigin(obj, botRSlice) + ...
%                     [sliceHeight - 1, sliceWidth - 1], ...
%                     [obj.ImageHeight, obj.ImageWidth]);
                
%                 % Compute slice num in each plane
%                 numPlanes = (1:obj.SamplesPerPixel);
%                 slicesToRead = slicesToReadFirstPlane + ...
%                     ((numPlanes - 1) * numSlicesInPlane);
%                 
%                 slicesToRead = slicesToRead(:);

                [topLSliceOrigin, botRSliceEnd, slicesToRead, rowsToRead, colsToRead] = ...
                    computePixelRegionSlices(obj, regionStruct);

                % Set up channel properties
                obj.SliceList = slicesToRead;
                obj.ReadInterface = "Normal";
                
                % Flush the channel and read new data into the
                % channel in the expected format.
                restartChannel(obj);
                
                % Read the slices from the asyncIO channel and compose the
                % image
                im = composeFullColorImage(obj, topLSliceOrigin, ...
                    botRSliceEnd, numel(slicesToRead));

                % Compute the shifted indices for cropping the ROI,
                % RegionStruct is already 0-based, add 1 to shift to
                % 1-based
                cropRowStart = mod(regionStruct(1).startIdx - 1, sliceHeight) + 1;
                cropRowStop = (mod(regionStruct(1).stopIdx - 1, sliceHeight) + 1) + (length(rowsToRead) - 1) * sliceHeight;
                cropColStart = mod(regionStruct(2).startIdx - 1, sliceWidth) + 1;
                cropColStop = (mod(regionStruct(2).stopIdx - 1, sliceWidth) + 1) + (length(colsToRead) - 1) * sliceWidth;
                
                im = im(cropRowStart:regionStruct(1).incr:cropRowStop, ...
                    cropColStart:regionStruct(2).incr:cropColStop, :);
                
                % Invalidate the slice index so that next call to readImage
                % for the same image, restarts the channel.
                obj.SliceList = [];
                
            catch ME
                obj.SliceList = [];
                throwAsCaller(ME);
            end
        end
        
        % Read the specified pixel region using RGBA interface.
        function varargout = readRGBAPixelRegion(obj, pixelRegion)
            try
                sliceWidth = obj.SliceWidth;
                sliceHeight = obj.SliceHeight;

                % save the pixel region values to a struct
                regionStruct = obj.processPixelRegion(pixelRegion, ...
                    [obj.ImageHeight, obj.ImageWidth]);
                
                [topLSliceOrigin, botRSliceEnd, slicesToRead, rowsToRead, colsToRead] = ...
                    computePixelRegionSlices(obj, regionStruct);
                
                % Set up channel properties
                obj.SliceList = slicesToRead;
                obj.ReadInterface = "RGBA";
                
                % Flush the channel and read new data into the
                % channel in the expected format.
                restartChannel(obj);
                
                % Read the slices from the asyncIO channel and compose the
                % image
                [im, alpha] = composeRGBAImage(obj, topLSliceOrigin, ...
                    botRSliceEnd);

                % compute the shifted indices for cropping the ROI
                cropRowStart = mod(regionStruct(1).startIdx - 1, sliceHeight) + 1;
                cropRowStop = (mod(regionStruct(1).stopIdx - 1, sliceHeight) + 1) + (length(rowsToRead) - 1) * sliceHeight;
                cropColStart = mod(regionStruct(2).startIdx - 1, sliceWidth) + 1;
                cropColStop = (mod(regionStruct(2).stopIdx - 1, sliceWidth) + 1) + (length(colsToRead) - 1) * sliceWidth;
                
                varargout{1} = im(cropRowStart:regionStruct(1).incr:cropRowStop, ...
                    cropColStart:regionStruct(2).incr:cropColStop, :);
                
                varargout{2} = alpha(cropRowStart:regionStruct(1).incr:cropRowStop, ...
                    cropColStart:regionStruct(2).incr:cropColStop, :);
                
                % Invalidate the slice index so that next call to readImage
                % for the same image, restarts the channel.
                obj.SliceList = [];
                
            catch ME
                obj.SliceList = [];
                throwAsCaller(ME);
            end
        end
        
        function [y, cb, cr] = readYCbCrSliceHelper(obj)
            tempData = obj.readRawData();
            assert( isstruct(tempData), 'Separate YCbCr is not currently supported' );
            
            cb = tempData.Cb';
            cr = tempData.Cr';
            
            subsampling = obj.MandatoryTags.YCbCrSubSampling;
            if subsampling == [1 1]
                y = tempData.Y';
                return;
            end
            
            y = zeros(size(tempData.Y, 2), size(tempData.Y, 1), class(tempData.Y));
            
            localSliceWidth = size(tempData.Y, 1);
            localSliceHeight = size(tempData.Y, 2);
            
            % Using a loop to populate the values. This can be sped-up
            % later.
            srcCnt = 1;
            for r = 1:subsampling(2):localSliceHeight
                for c = 1:subsampling(1):localSliceWidth
                    numSamplesToCopy = subsampling(1);
                    if c + numSamplesToCopy - 1 > localSliceWidth
                        numSamplesToCopy = localSliceWidth - c + 1;
                    end
                    
                    for r1 = 0:subsampling(2)-1
                        y(r+r1, c:c+numSamplesToCopy-1) = tempData.Y(srcCnt:srcCnt+numSamplesToCopy-1);
                        srcCnt = srcCnt + numSamplesToCopy;
                    end
                end
            end
        end
        
        % Helper function read a full slice.
        function slice = readFullColorSlice(obj, sliceNumber, readInterface)
            % Check to see if the options are correct
            % in order to ensure that the channel provides
            % the data in the expected format.
            
            % For example for a grayscale image, the data is
            % read as a slice in grayscale colorspace.
            % SliceIndex represent the next slice available in the
            % channel to be read. If SliceIndex is equal to the
            % requested sliceNumber, it means the slice is already
            % available in the channel to be read.
            
            % If any one of this parameters do not match, then
            % flush out the existing data from the channel and then
            % start buffering the data in the channel starting from the
            % the specified slice number.
            
            %  The channel buffers all the slices from sliceNumber upto
            %  the size limit of the channel. Reading one slice from
            %  the channel will push the next slice from the TIFF image
            %  into the channel. The process continues until there is
            %  no more slices left in the TIFF image.
            if obj.ReadInterface ~= readInterface || ...
                    obj.SliceIndex ~= sliceNumber
                
                obj.ReadInterface = readInterface;
                obj.SliceIndex = sliceNumber ;
                restartChannel(obj);
            end
            % Read the slice and permute it
            slice = obj.readRawData();
            
            % Increment the sliceIndex to the next slice Number in order
            % to represent the true next slice number that is
            % available to be read from the channel.
            if obj.SliceIndex < obj.NumSlices
                obj.SliceIndex = sliceNumber + 1;
            else
                % If  slice read was the last slice, then set the slice index
                % to 1 again and buffer the slices in the channel for the next
                % call to readSlice.
                obj.SliceIndex = 1;
                restartChannel(obj);
            end
        end
        
        % Helper function to read a slice from the channel
        function data = readRawData(obj)
            data=[];
            while isempty(data)
                data = obj.Channel.InputStream.read(1);
            end
        end
        
        % Construct the blank output image
        function imageData = constructBlankOutputImage(~,imageSize,bitsPerSample,sampleFormat)
            if (sampleFormat == matlab.io.internal.SampleFormat.ComplexInt) || ...
                    (sampleFormat == matlab.io.internal.SampleFormat.ComplexIEEEFP)
                error(message('imageio:tiffreader:complexSampleFormat'));
            end
            
            if bitsPerSample == 1
                imageData = false(imageSize);
                
            elseif bitsPerSample <= 8
                switch sampleFormat
                    case matlab.io.internal.SampleFormat.Int
                        imageData = zeros(imageSize,'int8');
                    case {matlab.io.internal.SampleFormat.UInt, matlab.io.internal.SampleFormat.Void}
                        imageData = zeros(imageSize,'uint8');
                    otherwise
                        error(message('imageio:tiffreader:badSampleFormatBitsPerSampleCombination',...
                            sampleFormat,bitsPerSample));
                end
                
            elseif bitsPerSample <= 16
                switch sampleFormat
                    case matlab.io.internal.SampleFormat.Int
                        imageData = zeros(imageSize,'int16');
                    case {matlab.io.internal.SampleFormat.UInt, matlab.io.internal.SampleFormat.Void}
                        imageData = zeros(imageSize,'uint16');
                    otherwise
                        error(message('imageio:tiffreader:badSampleFormatBitsPerSampleCombination',...
                            sampleFormat,bitsPerSample));
                        
                end
                
            elseif bitsPerSample <= 32
                switch sampleFormat
                    case matlab.io.internal.SampleFormat.IEEEFP
                        imageData = zeros(imageSize,'single');
                    case matlab.io.internal.SampleFormat.Int
                        imageData = zeros(imageSize,'int32');
                    case {matlab.io.internal.SampleFormat.UInt,matlab.io.internal.SampleFormat.Void}
                        imageData = zeros(imageSize,'uint32');
                    otherwise
                        error(message('imageio:tiffreader:unknownSampleFormat',sampleFormat));
                end
                
            elseif bitsPerSample == 64
                if sampleFormat ~= matlab.io.internal.SampleFormat.IEEEFP
                    error(message('imageio:tiffreader:badBpsSampleFormatCombinationFor64bps'));
                end
                imageData = zeros(imageSize,'double');
                
            else
                error(message('imageio:tiffreader:badBitsPerSample', bitsPerSample));
            end
        end
        
        % Helper function to compose the requested slices acquired from the
        % asyncIO channel for full color complete images
        function im = composeFullColorImage(obj, topLSliceOrigin, botRSliceEnd, numSlicesToRead)
            % A variable channel which is used to track
            % the number to channels that are to be read.
            % For chunky, all the channels are read at one shot.
            % For separate, one channel is read at a time.
            colorChannel = 1;
            
            % Set the number of samples to read based on the planar
            % configuration of the image.
            if obj.PlanarConfiguration == "Separate"
                numSamplesPerPixel = 1;
            else
                numSamplesPerPixel = obj.SamplesPerPixel;
            end
            
            % Initialize the count of slices already read from the channel
            % to 0.
            countRead = 0;
            
            % Update how many slices are left to be read.
            remainingSlices = numSlicesToRead;
            
            % Variable to index in the cell array of slices that were
            % read from the channel
            packetCt = 1;
            
            % Allocate a large array of zeros equivalent to the size
            % of the requested slices.
            im = zeros(botRSliceEnd(1) - topLSliceOrigin(1) + 1,...
                botRSliceEnd(2) - topLSliceOrigin(2) + 1, ...
                obj.SamplesPerPixel,...
                obj.MLType );
            
            while colorChannel <= obj.SamplesPerPixel % For chunky, this loop runs exactly once.
                % starting row to read from in terms of slice
                % coordinates
                currRow = topLSliceOrigin(1);
                while currRow <= botRSliceEnd(1)
                    % numRows should be sliceHeight or remaining rows to
                    % read
                    numRows = min(obj.SliceHeight, obj.ImageHeight - currRow + 1);
                    
                    currCol = topLSliceOrigin(2);
                    while currCol <= botRSliceEnd(2)
                        % numCols should be sliceWidth or remaining columns
                        % to read
                        numCols = min(obj.SliceWidth, obj.ImageWidth - currCol + 1);
                        
                        % Read the total number of slices in the image from the asyncIO
                        % Channel. If the channel has not buffered that many slices, it
                        % will return whatever is available at that point.
                        % For example if there are 100 slices to read, and the asyncIO
                        % buffer has only 60 slices when the readPackets function is
                        % called, it will return 60 slices to MATLAB. The channel
                        % does not error if user request more slices than the channel
                        % can provide.
                        if packetCt > countRead
                            temp = [];
                            packetCt = 1;
                            if remainingSlices ~=0
                                countRead = 0;
                                while countRead == 0
                                    % Store the slices in temp. countRead
                                    % is less than slicesToRead here
                                    % always.
                                    [temp,countRead] = obj.Channel.InputStream.readPackets(numSlicesToRead);
                                end
                                % Update the remaningSlices to reflect the
                                % number of slices that are still left to be
                                % read.
                                remainingSlices = remainingSlices - countRead;
                            end
                        end
                        % If all slices are read, check if the last slice
                        % is all NaN. The last slice is NaN only when all the
                        % previous slices were also corrupted. This is done
                        % to reliably communicate from the asyncIO thread
                        % that all the slices are corrupted. The alternative
                        % is to return an error event from asyncIO but that is not
                        % a reliable solution.
                        if remainingSlices == 0 && packetCt == countRead
                            if  isnan(temp{countRead})
                                handleCorruptImage(obj);
                            end
                        end
                        
                        % Iterate over the cell array of slices,
                        % and store the slice in the final output image.
                        storeRow = currRow - topLSliceOrigin(1) + 1;
                        storeCol = currCol - topLSliceOrigin(2) + 1;
                        im( storeRow:(storeRow + numRows - 1),...
                            storeCol:(storeCol + numCols - 1),...
                            colorChannel:(colorChannel + numSamplesPerPixel - 1)) = ...
                            temp{packetCt};
                        
                        packetCt = packetCt + 1;
                        currCol = currCol + numCols;
                    end
                    currRow = currRow + numRows;
                end
                colorChannel = colorChannel + numSamplesPerPixel;
            end
        end
        
        % Helper function to compose the requested slices acquired from the
        % asyncIO channel for RGBAI images
        function [im, alpha] = composeRGBAImage(obj, topLSliceOrigin, botRSliceEnd)            
            % Allocate a large array of zeros equivalent to the size
            % of the requested slices.
            im = zeros(botRSliceEnd(1) - topLSliceOrigin(1) + 1,...
                botRSliceEnd(2) - topLSliceOrigin(2) + 1, ...
                3,...
                obj.MLType );
            alpha = zeros(botRSliceEnd(1) - topLSliceOrigin(1) + 1,...
                botRSliceEnd(2) - topLSliceOrigin(2) + 1, ...
                obj.MLType );
            
            currRow = topLSliceOrigin(1);
            while currRow <= botRSliceEnd(1)
                % numRows should be sliceHeight or remaining rows to
                % read
                numRows = min(obj.SliceHeight, obj.ImageHeight - currRow + 1);
                
                currCol = topLSliceOrigin(2);
                while currCol <= botRSliceEnd(2)
                    % numCols should be sliceWidth or remaining columns
                    % to read
                    numCols = min(obj.SliceWidth, obj.ImageWidth - currCol + 1);
                    
                    % Iterate over the cell array of slices, 
                    % and store the slice in the final output image.
                    data = obj.readRawData();
                    
                    %  If all slices are read, then the last slice will
                    % return NaN. Check and throw appropiate error
                    if isnan(data)
                        handleCorruptImage(obj);
                    end
                    
                    data = flipud(data);
                    
                    % Iterate over the cell array of slices,
                    % and store the slice in the final output image.
                    storeRow = currRow - topLSliceOrigin(1) + 1;
                    storeCol = currCol - topLSliceOrigin(2) + 1;
                    im( storeRow:(storeRow + numRows - 1),...
                        storeCol:(storeCol + numCols - 1), 1:3) = ...
                        data(:, :, 1:3);
                    
                    alpha( storeRow:(storeRow + numRows - 1),...
                        storeCol:(storeCol + numCols - 1), 1) = ...
                        data(:, :, 4);
                    
                    currCol = currCol + numCols;
                end
                currRow = currRow + numRows;
            end
        end
        
        function [topLSliceOrigin, botRSliceEnd, slicesToRead, rowsToRead, colsToRead] = ...
                computePixelRegionSlices(obj, regionStruct)
            
                sliceWidth = obj.SliceWidth;
                sliceHeight = obj.SliceHeight;
                numSlicesInXDir = ceil(obj.ImageWidth / sliceWidth);
                numSlicesInYDir = ceil(obj.ImageHeight / sliceHeight);
                numSlicesInPlane = numSlicesInXDir * numSlicesInYDir;
                
                % Compute the bounds of the pixel region in terms of slice
                % number
                topLSlice = computeSliceNum(obj, [regionStruct(1).startIdx, ...
                    regionStruct(2).startIdx]);
                
                botRSlice = computeSliceNum(obj, [regionStruct(1).stopIdx, ...
                    regionStruct(2).stopIdx]);
                
                % Compute the slice subscript bounds
                rowsToRead = ceil(topLSlice/numSlicesInXDir): ...
                             ceil(botRSlice/numSlicesInXDir);
                colsToRead = (mod(topLSlice - 1, numSlicesInXDir) + 1: ...
                              mod(botRSlice - 1, numSlicesInXDir) + 1)';
                slicesToReadFirstPlane = (rowsToRead - 1) * numSlicesInXDir + colsToRead;
                slicesToReadFirstPlane = slicesToReadFirstPlane(:);
                % Orgin of top left slice
                topLSliceOrigin = computeSliceOrigin(obj, topLSlice);
                
                % End coordinate of bottom right slice
                botRSliceEnd = min(computeSliceOrigin(obj, botRSlice) + ...
                    [sliceHeight - 1, sliceWidth - 1], ...
                    [obj.ImageHeight, obj.ImageWidth]);
                
                % Compute slice num in each plane
                numPlanes = (1:obj.SamplesPerPixel);
                slicesToRead = slicesToReadFirstPlane + ...
                    ((numPlanes - 1) * numSlicesInPlane);
                
                slicesToRead = slicesToRead(:);
        end
    end
    
    methods(Static, Access='private')
        % Helper function to convert the PixelRegion cell array to a struct
        % and save to obj.RegionStruct
        % The struct contains fields: startIdx, incr, stopIdx
        function regionStruct = processPixelRegion(regionInput, imageSize)
            
            % Iterate through row and then column properties, correctly formatted
            % PixelRegion input should have two elements
            for p = 1:2
                
                validateattributes(regionInput{p},{'numeric'},{},'','PixelRegion');
                start = max(1, regionInput{p}(1));
                
                % If only start and stop values are set, set increment to 1
                if (numel(regionInput{p}) == 2)
                    incr = 1;
                    stop = min(regionInput{p}(2), imageSize(p));
                    
                elseif (numel(regionInput{p}) == 3)
                    validateattributes(regionInput{p}(2),{'numeric'}, ...
                        {'finite','positive'},'','increment');
                    incr = regionInput{p}(2);
                    
                    stop = min(regionInput{p}(3), imageSize(p));
                    
                else
                    error(message('imageio:tiffreader:incorrectPixelRegion'));
                end
                
                % Verify that the stop value is greater than the start value
                if (start > stop)
                    error(message('imageio:tiffreader:incorrectPixelRegion'));
                end
                
                % For the row or column, 1-based start index of the pixel region
                regionStruct(p).startIdx = floor(start);
                
                % positive integer value that represents the downsampling increment
                regionStruct(p).incr = floor(incr);
                
                % For the row or column, 1-based stop index of the pixel region
                regionStruct(p).stopIdx = floor(stop);
                
            end
        end
    end
end
