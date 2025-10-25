classdef (Abstract) ITiffReader < matlab.mixin.SetGet & matlab.mixin.CustomDisplay
    %   matlab.io.internal.ITiffReader Abstract base class that provides
    %   the common functionality for matlab.io.internal.TiffReader and
    %   matlab.io.internal.BigImageReader
    
    %   Copyright 2019-2021 The MathWorks, Inc.
    
    %------------------------------------------------------------------
    % General properties
    %------------------------------------------------------------------
    properties(GetAccess = 'protected', SetAccess='private',Transient)
        Channel                 % Instance of an asyncIO communication channel that is a data source.
    end
    
    properties(SetAccess='private',Transient)
        NumSlices                 % Total number of slices (tile or stripe) in the image.
    end
    
    properties(SetAccess='private')
        FileName                  % FileName is the name of the TIFF File to be read.
        
        FilePath                  % FilePath is the location of the TIFF File.
    end
    
    properties(Access='protected')
        InputStreamLimit = Inf  % InputStreamLimit indicates the maximum number of slices present in a channel for read.
    end
    
    properties(Access='private', Constant)
        OutputStreamLimit = 0;  % OutputStreamLimit specified the maximum number of slices to be written into a channel.
        
        AccessMode = 'r';       % Specifies the mode in which the TIFF File is opened.
        
        SchemaVersion = 9.7;    % Specifies the version of MATLAB in which this schema was introduced. Helps with
                                % forward compatibility.
    end
    
    properties(Access = 'protected',Hidden)
        CurrentImageDirectory = -1;   % CurrentImageDirectory is the current image or IFD (Image File Directory) in the TIFF file.
        
        IFDOffset = -1 ;             % IFDOffset is the byte offset from which the TIFF File is to be read.
                                     % TIFF File is read using either IFDs or IFDOffset but not both.
    end
    
    properties(Access = 'protected', Hidden) 
        ReadInterface = 'Normal'; % ReadInterface specifies whether to read the TIFF File in the native format or as an RGB image.
        % Default is Normal.
        
        SliceIndex = 1;           % Represents a slice number.
        
        SliceList = [];           % Represents a list of slices to read
    end
    
    properties(Access = 'private',Dependent)
        OpenOptions         % A struct containing the options for read. Specifically it includes
                            %    -SliceIndex : The index of the start slice as available to be read in the channel.
                            %    -ReadInterface: Specifies whether to read the TIFF File in the native format or as an RGB image.
                            %                    Default is Normal.
                            %    -CurrentImageDirectory : Indicates the  image to be read
                            %    -SubIDOffset - Indicates the byte offset from which to read the file
    end
    
    properties (SetAccess = 'private', Transient)
        Organization            % Organization of the TIFF File .i.e Tile or Strip.
        
        MLType                  % MLType represents the type of the image data in MATLAB. For example, uint8, uint16, double etc.
        
        Photometric             % Photometric represents the color space of the image data. For example, RGB, YCbCr, Grayscale etc.
        
        ImageHeight             % Length of the image.
        
        ImageWidth              % Width of the image.
        
        SliceHeight             % Length of a slice in the image.
        
        SliceWidth              % Width of a slice in the image.
        
        BitsPerSample           % Number of bits per color component.
        
        Compression             % Compression scheme used with the image data.
        
        SamplesPerPixel         % Number of components per pixel. For example SamplesPerPixel is 3 for RGB image.
        
        PlanarConfiguration     % Specifies how the pixels are arranaged .i.e contiguous or separate. The expected values are chunky and separate.
        
        NumImages               % Total number of images in the TIFF File.
        
        ImageTags               % A struct containing all the tags of the TIFF File.
    end
    
    properties(Access = 'protected')
        MandatoryTags          % Set of essential tags of the TIFF file.
    end
    
    properties(Access='private', Transient)
        CachedImageTags = [];   % Cache dependent property ImageTags as it is computationally expensive
        CachedNumImages = [];   % Cache dependent property numImages as it is computationally expensive
    end
        
    %------------------------------------------------------------------
    %  Public Concrete Methods
    %------------------------------------------------------------------
    methods
        function obj = ITiffReader(filename,varargin)
            % Validate the number of outputs
            nargoutchk(0,1);
            
            % Setup the Inputparser to validate the input arguments.
            parser = inputParser;
            parser.FunctionName = "TiffReader";
            validateFilename = @(x)validateattributes(x,{'char','string'},{'nonempty','scalartext'});
            addRequired (parser,"Filename",validateFilename);
            
            % Add name-value pair ImageIndex to the input parser. The
            % default value is 1 .i.e the first image in the TIFF File.
            % libTIFF has the limitation of supporting only upto 2^16 = 65536 images.
            % Adding that check to the input parser.
            validateImageIndex = @(x)validateattributes(x,{'numeric'},{'integer','scalar','positive','<=', 65536});
            addParameter(parser,"ImageIndex",1,validateImageIndex);
            
            % Add name-value pair IFDOffset to the input parser. The default
            % value is -1; which is an invalid value.
            validateOffset = @(x)validateattributes(x,{'numeric'},{'integer','scalar','positive'});
            addParameter(parser,"IFDOffset",-1,validateOffset);
            
            try
                parse(parser,filename,varargin{:});
            catch ME
                % This logic is implemented to be in sync with IMREAD behavior
                if isequal(ME.identifier,'MATLAB:notLessEqual')
                    error(message('imageio:tiffreader:unableToChangeDir',65536));
                end
                throwAsCaller(ME);
            end
            
            if isempty(parser.UsingDefaults)
                error(message('imageio:tiffreader:cannotUseBothIndexAndOffset'));
            end
            
            % If parsing is successful, set the properties of internal TiffReader object.
            obj.FileName = string(filename);
            [filePath,fileName,ext] = fileparts(multimedia.internal.io.absolutePathForReading(filename, ....
                'imageio:tiffreader:FileNotFound',...
                'imageio:tiffreader:FilePermissionDenied'));
            obj.FileName = strcat(string(fileName),ext);
            obj.FilePath = string(filePath);   
            
            % If the name-value pair 'IFDOffset' is -1, then
            % it means that the user provided name-value pair
            % 'ImageIndex'. Set the CurrentImageDirectory property
            % of the internal Tiffreader object to value of 'ImageIndex'.
            if parser.Results.IFDOffset == -1
                obj.CurrentImageDirectory = parser.Results.ImageIndex;
            else
                % Otherwise the IFDOffset is valid.
                obj.IFDOffset = uint64(parser.Results.IFDOffset);
            end
        end
        %------------------------------------------------------------------
        %  Setter Methods for each of the dependent properties
        %------------------------------------------------------------------   
        
        % Set the total number of slices in the image
        function set.NumSlices(obj,value)
            obj.NumSlices = value;
        end
        
        % Set the image organization .i.e tiled or stripped.
        function set.Organization(obj,value)
            obj.Organization = value;
        end
        
        % Set the total number of complete slices in the image
        function set.MLType(obj,value)
            obj.MLType = string(value);
        end
        
        % Set the Photometric configuration of the image
        function set.Photometric(obj,value)
            obj.Photometric = value;
        end
        
        % Set planar configuration
        function set.PlanarConfiguration(obj,value)
            obj.PlanarConfiguration = value;
        end
        
        % Set the image Length
        function set.ImageHeight(obj,value)
            obj.ImageHeight = value;
        end
        
        % Set the image width
        function set.ImageWidth(obj,value)
            obj.ImageWidth = value;
        end
        
        % Set the slice height
        function set.SliceHeight(obj,value)
            obj.SliceHeight = value;
        end
        
        % Set the slice width
        function set.SliceWidth(obj,value)
            obj.SliceWidth = value;
        end
        
        % Set the BitsPerSample of the image
        function set.BitsPerSample(obj,value)
            obj.BitsPerSample = value;
        end
        
        % Set the compression of the image
        function set.Compression(obj,value)
            obj.Compression = value;
        end

        % Get samples per pixel of the image
        function set.SamplesPerPixel(obj,value)
            obj.SamplesPerPixel = value;
        end
        
        %Get the total number of images in the TIFF File
        function value = get.NumImages(obj)
            if isempty(obj.CachedNumImages)
                obj.CachedNumImages = matlab.io.internal.computeNumImages(fullfile(obj.FilePath,obj.FileName));
            end
            value = obj.CachedNumImages;
        end
        
        % Set all the image tags present in the TIFF File
        function value = get.ImageTags(obj)
            if isempty(obj.CachedImageTags)
                % Get image tags from the first image using the mex file
                % tifftagsread. The first argument is the filename, the second argument
                % is the TIFF header offset which is always 0 for TIFF files,
                % the third argument is the index of the first IFD, the
                % fourth argument is the number of IFDs to retrieve. A value of
                % zero means retrieve all IFDs
                raw_tags = matlab.io.internal.tifftagsread(fullfile(obj.FilePath,obj.FileName),0,0,0);
                
                % Process the raw tags into human-readable form
                obj.CachedImageTags =  matlab.io.internal.tifftagsprocess(raw_tags);
            end
            if(obj.CurrentImageDirectory ~= -1)
                value = obj.CachedImageTags(obj.CurrentImageDirectory);
            else
                %Find the correct IFD corresponding to the requested offset
                for i = 1:numel(obj.CachedImageTags)
                    if obj.CachedImageTags(i).Offset == obj.IFDOffset
                        value = obj.CachedImageTags(i);
                        break;
                    end
                end
            end
        end
        
        % Get the options required to open the channel
        function option = get.OpenOptions(obj)
            % Index of the start slice from which the data is buffered in the channel.
            if isempty(obj.SliceList)
                option.Slices = obj.SliceIndex - 1;
            else
                option.Slices = obj.SliceList - 1;
            end
            
            % CurrentImageDirectory is set to -1 if IFDOffset is provided
            if obj.CurrentImageDirectory ~= -1
                option.ImageDirectory = obj.CurrentImageDirectory -1 ;
            else
                option.ImageDirOffset = obj.IFDOffset ;
            end
            
            % ReadInterface is either 'Normal' or 'RGB'.
            option.ReadInterface = obj.ReadInterface;
        end
        
        function sliceNos = computeSliceNum(obj,coord,plane)
            % COMPUTESLICENUM  Compute the index of the slice that contains
            % the image data for the specified location.
            %   SLICENUMBER = COMPUTESLICENUM(OBJ, COORDS) computes the slice
            %   number SLICENUMBER that contains the image data for the specified
            %   location COORD in an image. COORD is a numeric matrix.
            %   This syntax requires the image to have a Chunky planar
            %   configuration.
            %
            %   SLICENUMBER = COMPUTESLICENUM(OBJ, COORDS, PLANE) computes the slice
            %   number SLICENUMBER that contains the image data for the specified
            %   location COORD and PLANE in an image. COORD is a numeric
            %   matrix.PLANE is a numeric scalar. This syntax requires the
            %   image to have a Separate planar configuration.
            %
            %   Example: Compute the slice number for a Tiled Image
            %       t = matlab.io.internal.TiffReader("example.tif");
            %       sliceNum = computeSliceNum(t, [200 400]);
            %
            try
                % Validate the inputs
                validateattributes(coord,{'double'},{'integer','vector','positive','size',[1,2]},'','coord');
                
                % If Planar Configuration is Separate, then PLANE must be provided
                if  obj.PlanarConfiguration == "Separate" && nargin < 3
                    plane = 1;
                end
                % If Planar Configuration is Chunky, then PLANE must not be provided
                if obj.PlanarConfiguration == "Chunky" && nargin > 2
                    error(message('imageio:tiffreader:sampleParameterNotAllowedInChunkyCase'));
                end
                
                % For chunky image, plane is always 1
                if obj.PlanarConfiguration == "Chunky"
                    plane = 1;
                end
                sliceNos = obj.computeSliceIndex(coord,plane);
            catch ME
                throwAsCaller(ME);
            end
        end
        
        function origin = computeSliceOrigin(obj, sliceNumber)
            % COMPUTESLICEORIGIN Computes the origin in image coordinates,
            % of a specified slice number
            %   ORIGIN = COMPUTESLICEORIGIN(OBJ, SLICENUMBER) computes the image
            %   coordinates that represent the origin of the slice specified by
            %   SLICENUMBER. SLICENUMBER is a numeric scalar. The output ORIGIN
            %   is a 1x2 numeric vector.
            %
            %   Example: Compute the origin of a slice for a Tiled Image
            %       % Compute the origin of the 4th slice
            %       t = matlab.io.internal.TiffReader("example.tif");
            %       origin = computeSliceOrigin(t, 4);
            %
            %   Example: Compute the origin of a slice for a Stripped Image
            %       % Compute the origin of the 3rd slice
            %       t = matlab.io.internal.TiffReader("example.tif",
            %       "ImageDir", 2);
            %       origin = computeSliceOrigin(t, 3);
            try
                %Validate the input
                validateattributes(sliceNumber,{'double'},{'integer','scalar','positive','row', '<=', obj.NumSlices},'','SliceNumber');
                if obj.PlanarConfiguration == "Separate"
                    numCompleteSlices = obj.NumSlices/obj.SamplesPerPixel;
                    % Update the slice number to the first plane for separate image
                    % because the slice origin in the first plane is equivalent to
                    % computing the slice origin for other planes.
                    if sliceNumber > numCompleteSlices
                        sliceNumber = mod(sliceNumber, numCompleteSlices);
                        if sliceNumber == 0
                            sliceNumber = numCompleteSlices;
                        end
                    end
                end
                
                % Compute number of slices in X direction
                numSliceInXDir = ceil( obj.ImageWidth / obj.SliceWidth);
                sliceRowNo = ceil(sliceNumber/numSliceInXDir);
                sliceColNo = mod(sliceNumber,numSliceInXDir);
                %Special case: Last column
                if (sliceColNo == 0)
                    sliceColNo = numSliceInXDir;
                end
                offsetX=(sliceRowNo-1) * obj.SliceHeight + 1;
                offsetY=(sliceColNo-1) * obj.SliceWidth + 1;
                origin = [offsetX, offsetY];
            catch ME
                throwAsCaller(ME);
            end
        end
        
        % Delete the channel object
        function delete(obj)
            obj.closeChannel();
        end
    end
    
     methods(Access='public', Hidden) 
         % Close the channel and flush the input stream
         function closeChannel(obj)
             try
                 close(obj.Channel);
                 if ~isempty(obj.Channel)
                     flush(obj.Channel.InputStream);
                 end
             catch ME
                 throwAsCaller(ME);
             end
         end
         
        % If there is not enough memory, throw the outofmemory exception
        function onError(obj, data)
            % Close and flush the channel
            % Channel can be empty if error happens at init call in device
            % plugin
            if ~isempty(obj.Channel)
                obj.closeChannel();
            end
            
            if isempty(data.Args)
                error(message(data.ID));
            else
                error(message(data.ID,data.Args{:}));
            end
        end

        function infoToSave = saveobj(obj)
            % SAVEOBJ  Save object into a MAT file
            %   Saves the relevant information from the object into a MAT
            %   file which allows the object to be recreated again upon
            %   loading
            infoToSave.FilePath = obj.FilePath;
            infoToSave.FileName = obj.FileName;
            infoToSave.CurrentImageDirectory = obj.CurrentImageDirectory;
            infoToSave.IFDOffset = obj.IFDOffset;
            % We will save the schema version into the MAT file. This will
            % allow suitable forward/backward compatibility when loading
            % saved objects across different MATLAB versions.
            infoToSave.SchemaVersionSavedIn = matlab.io.internal.ITiffReader.SchemaVersion;
        end
    end
    
    %------------------------------------------------------------------
    % Protected methods -Helper methods to support the public interfaces
    %------------------------------------------------------------------
    methods(Access='protected')
        % Return true if Tiff file is a tiled image.
        function res = isTiled(obj)
            if obj.MandatoryTags.Organization == "Tile"
                res = true;
            else
                res = false;
            end
        end
        
        % Return number of strips in image.
        function numStrips = numberOfStrips(obj)
            numStrips = ceil(obj.MandatoryTags.ImageHeight / obj.MandatoryTags.SliceHeight);
            if obj.MandatoryTags.PlanarConfiguration == "Separate"
                numStrips = numStrips*obj.MandatoryTags.SamplesPerPixel;
            end
        end
        
        % Return number of tiles in image.
        function numTiles = numberOfTiles(obj)
            numTilesInXDir = ceil( obj.MandatoryTags.ImageWidth / obj.MandatoryTags.SliceWidth);
            numTilesInYDir = ceil( obj.MandatoryTags.ImageHeight / obj.MandatoryTags.SliceHeight);
            
            numTiles = numTilesInXDir*numTilesInYDir;
            if obj.MandatoryTags.PlanarConfiguration == "Separate"
                numTiles = numTiles*obj.MandatoryTags.SamplesPerPixel;
            end
        end
        
        % Open the channel
        function openChannel(obj)
            try
                obj.Channel.open(obj.OpenOptions);
            catch ME
                throwAsCaller(ME);
            end
        end
        
        function handleCorruptImage(obj)
            if obj.isTiled
                value = "tiles";
            else
                value = "strips";
            end
            error(message('imageio:tiffreader:unableToReadFile',obj.FileName,value));
        end
        
        % Override the custom display in the derived class
        
        function propgrp = getPropertyGroups(~)
            proplist = {'FileName','FilePath','Organization','NumSlices','NumCompleteSlices'...
                'MLType','Photometric','ImageHeight','ImageWidth','SliceHeight','SliceWidth',...
                'BitsPerSample','Compression','SamplesPerPixel','PlanarConfiguration',...
                'NumImages', 'ImageTags'};
            propgrp = matlab.mixin.util.PropertyGroup(proplist);
        end
    end
    
    %------------------------------------------------------------------
    % Static methods
    %------------------------------------------------------------------
    methods(Static,Access='protected')
        % Set the data type of the pixels in the Tiff file
        function value = getMLImageDataType(bitsPerPixel, sampleFormat)
            switch(bitsPerPixel)
                case 1
                    value= 'logical';
                case {2,3,4,5,6,7,8}
                    switch(sampleFormat)
                        case { matlab.io.internal.SampleFormat.UInt,...
                                matlab.io.internal.SampleFormat.Void
                                }
                            value = 'uint8';
                        case matlab.io.internal.SampleFormat.Int
                            value = 'int8';
                    end
                    
                case {9,10,11,12,13,14,15,16}
                    switch(sampleFormat)
                        case { matlab.io.internal.SampleFormat.UInt,...
                                matlab.io.internal.SampleFormat.Void,...
                                }
                            value = 'uint16';
                        case matlab.io.internal.SampleFormat.IEEEFP
                            value = 'single';
                        case matlab.io.internal.SampleFormat.Int
                            value = 'int16';
                    end
                    
                case {17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32}
                    switch(sampleFormat)
                        case { matlab.io.internal.SampleFormat.UInt,...
                                matlab.io.internal.SampleFormat.Void
                                }
                            value = 'uint32';
                        case matlab.io.internal.SampleFormat.Int
                            value  = 'int32';
                        case matlab.io.internal.SampleFormat.IEEEFP
                            value = 'single';
                    end
                    
                case 64
                    switch(sampleFormat)
                        case {matlab.io.internal.SampleFormat.UInt, matlab.io.internal.SampleFormat.Void}
                            value = 'uint64';
                        case matlab.io.internal.SampleFormat.Int
                            value = 'int64';
                        case matlab.io.internal.SampleFormat.IEEEFP
                            value = 'double';
                    end
            end
        end
    end
    
    %------------------------------------------------------------------
    % Private methods -Helper methods to support the public interfaces
    %------------------------------------------------------------------
    methods(Access='protected')
        % Helper to set the properties which is used by both ITR and
        % BigImageITR
        function setProperties(obj)
            % Set the organization
            if isTiled(obj)
                obj.Organization = "Tile";
            else
                obj.Organization = "Strip";
            end
            
            % Set the number of slices
            if isTiled(obj)
                obj.NumSlices = numberOfTiles(obj);
            else
                obj.NumSlices = numberOfStrips(obj);
            end
   
            % Set the MATLAB image data type
            obj.MLType = matlab.io.internal.TiffReader.getMLImageDataType(obj.MandatoryTags.BitsPerSample, obj.MandatoryTags.SampleFormat);
            
            % Set the photometric configuration
            obj.Photometric = string(obj.MandatoryTags.Photometric);
            
            % Set the Planar Configuration
            obj.PlanarConfiguration = string(obj.MandatoryTags.PlanarConfiguration);
            
            % Set image height
            obj.ImageHeight = obj.MandatoryTags.ImageHeight;
            
            % Set image width
            obj. ImageWidth = obj.MandatoryTags.ImageWidth;
            obj.SliceWidth = obj.MandatoryTags.SliceWidth;
            obj.SliceHeight = obj.MandatoryTags.SliceHeight;
            
            % Set bitsPerSample
            obj.BitsPerSample = obj.MandatoryTags.BitsPerSample;
            
            % Set compression
            obj.Compression = string(obj.MandatoryTags.Compression);
            
            % Set Samples per pixel
            obj.SamplesPerPixel = obj.MandatoryTags.SamplesPerPixel;
        end
        
        function initializeChannel(obj)
            import matlab.io.internal.ITiffReader;
            % Set the inital options to create a channel
            initOptions.FileName = fullfile(obj.FilePath,obj.FileName);
            initOptions.FileAccessMode = obj.AccessMode;
            pluginPath = toolboxdir(fullfile('shared','imageio','bin',computer('arch'),'tiff'));
            % Get path to tiff device plugin shared library
            devicePlugin = fullfile(pluginPath,'devicePlugin');
            
            % Get path to tiff device plugin shared library
            convPlugin = fullfile(pluginPath,'converterPlugin');
              
            % Register a message handler with the channel object
            errorMsgHandler = matlab.io.internal.TiffReaderMessageHandler;
            
            % Set the this object as the error handler
            errorMsgHandler.ErrorHandler = obj;
            
            % Create the channel
            obj.Channel = matlabshared.asyncio.internal.Channel( devicePlugin, ...
                convPlugin, ...
                Options = initOptions, ...
                StreamLimits = [obj.InputStreamLimit obj.OutputStreamLimit],...
                MessageHandler = errorMsgHandler);
            
            % Get path to tiff filter plugin shared library
            filterPlugin = fullfile(pluginPath,'filterPlugin');
            obj.Channel.InputStream.addFilter(filterPlugin);
        end
        
        % Compute slice index
        function sliceIndex = computeSliceIndex(obj,pixel, plane)
            validateattributes(plane,{'double'},{'integer','scalar','positive','<=',65536},'','PLANE');
            
            if plane > obj.SamplesPerPixel
                error( message('imageio:tiffreader:invalidPlane',obj.SamplesPerPixel ));
            end
            
            if pixel(1) > obj.ImageHeight || pixel(2) > obj.ImageWidth
                error( message('imageio:tiffreader:InvalidImageLocation') );
            end
            
            sliceWidth = obj.SliceWidth;
            sliceLength = obj.SliceHeight;
            imageWidth = obj.ImageWidth;
            imageLength = obj.ImageHeight;
            numSlicesInXDir = ceil( imageWidth / sliceWidth );
            numSlicesInYDir = ceil( imageLength / sliceLength );

            sliceX = ceil( pixel(2) / sliceWidth );
            sliceY = ceil( pixel(1) / sliceLength );
            
            sliceIndex = (sliceY-1)*numSlicesInXDir + sliceX + ...
                (plane-1)*numSlicesInXDir*numSlicesInYDir;
        end
    end
end