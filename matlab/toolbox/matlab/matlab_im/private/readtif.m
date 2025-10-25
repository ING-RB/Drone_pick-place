function [X,map] = readtif(filename, varargin)
%READTIF Read an image from a TIFF file.
%   [X,MAP] = READTIF(FILENAME) reads the first image from the
%   TIFF file specified by the string variable FILENAME.  X will
%   be a 2-D uint8 array if the specified data set contains an
%   8-bit image.  It will be an M-by-N-by-3 uint8 array if the
%   specified data set contains a 24-bit image.  MAP contains the
%   colormap if present; otherwise it is empty. 
%
%   [X,MAP] = READTIF(FILENAME, N, ...) reads the Nth image from the
%   file.
%
%   READTIF accepts trailing parameter-value pairs.  The parameter names and
%   corresponding values are:
%
%       Parameter Name        Value
%       --------------        -----
%       Index                 Scalar; same as input parameter N above
%
%       Info                  Struct; same as input parameter INFO above
%
%       PixelRegion           {ROWS, COLS}
%                             reads a region of pixels from the file. ROWS
%                             and COLS are two- or three-element vectors,
%                             where the first value is the start location,
%                             and the last value is the ending location. In
%                             the three-value syntax, the second value is the
%                             increment.
%
%       AutoOrient            A logical value. If true, the returned image 
%                             is transformed (rotated and/or mirrored) to be 
%                             displayed correctly according to the camera 
%                             orientation as indicated in the image metadata. 
%                             If false, the image is returned "as is" and may 
%                             appear to have unexpected orientation when 
%                             displayed. The default value is false.
%
%   See also IMREAD, IMWRITE, IMFINFO.

%   Copyright 1984-2024 The MathWorks, Inc.

args = parse_args(varargin{:});
args.filename = filename;

if ~isempty(args.info) && isfield(args.info, 'Offset')
    % If INFO input is provided, use the Offset field to determine where the
    % specified image is located in the file.
    
    if args.index > numel(args.info)
        error(message('MATLAB:imagesci:readtif:indexInfoMismatch'));
    end

    args.offset = args.info(args.index).Offset;
end


try 
    [X, map, details] = matlab.internal.imagesci.rtifc(args);
catch ME  
    if istif(filename) && strcmp(ME.identifier,'imageio:tiffutils:libtiffError')
        % If file is a valid TIFF file and error is coming from the library, 
        % check for proper TIFF tags. 
        % If there is some issue with reading TIFF tags, tifftagsread()
        % will throw its own error/warning messages.
        matlab.io.internal.tifftagsread(filename,0,0,0);
    end
    %If no error is thrown by tifftagsread(), rethrow the original error.
    rethrow(ME);
end 

map = double(map)/65535;

% apply Exif Orientation value to the image data
if args.autoorient
    % make sure we have the metadata to know the orientation
    if ~isempty(args.info)
        info = args.info(args.index);
    else
        % turn off warnings for call to imfinfo and make sure to restore
        % them afterwards
        origWarnState = warning('off');
        restoreWarnings = onCleanup(@()warning(origWarnState));
        info = imfinfo(filename);
        clear("restoreWarnings")
        info = info(args.index); % only need info for requested index
    end
    if isfield(info, "Orientation")
        X = applyExifOrientation(X, info.Orientation);
    end
end

if (details.Photo == 8)
    % TIFF image is in CIELAB format.  Issue a warning that we're
    % converting the data to ICCLAB format, and correct the a* and b*
    % values.
    
    % First, though, check to make sure we have the expected number of
    % samples per pixel.
    if (size(X,3) ~= 1) && (size(X,3) ~= 3)
        error(message('MATLAB:imagesci:readtif:unexpectedCIELabSamplesPerPixel'));
    end
    
    % Now check that we have uint8 or uint16 data.
    if ~ (isa(X,'uint8') || isa(X,'uint16'))
        error(message('MATLAB:imagesci:readtif:wrongCieLabDatatype', class( X )));
    end
    
    warning(message('MATLAB:imagesci:readtif:CielabConversion'));
    
    X = cielab2icclab(X);
elseif (details.Photo == 0)
    if (details.BitsPerSample == 1)
        % TIFF image is MinIsWhite and logical.  Invert it.
        X = ~X;
    elseif (details.Photo == 0) && (details.BitsPerSample <= 8)
        % TIFF image is MinIsWhite and not more than one byte.  Invert it.
        X = 2^(details.BitsPerSample) - 1 - X;
    end
end




function args = parse_args(varargin)
%PARSE_ARGS  Convert input arguments to structure of arguments.

args.index = 1;
args.pixelregion = [];
args.info = [];
args.autoorient = false;

params = {'index', 'pixelregion', 'info', 'autoorient'};

p = 1;
while (p <= nargin)
    
    argp = varargin{p};
    validateattributes(argp,{'char','numeric', 'string'},{});
    if (isnumeric(argp))

        args.index = argp;
        p = p + 1;

    % No necessity to perform any specific checks for string as it would
    % have been converted into character vectors before this private helper
    % is called. 
    elseif (ischar(argp))
        
        idx = find(strncmpi(argp, params, numel(argp)));
        
        if (isempty(idx))
            error(message('MATLAB:imagesci:validate:unrecognizedParameterName', argp))
        elseif (numel(idx) > 1)
            error(message('MATLAB:imagesci:validate:ambiguousParameterName', argp))
        end
        
        if (p == nargin)
            error(message('MATLAB:imagesci:readtif:missingValue', argp))
        end
        
        args.(params{idx}) = varargin{p + 1};
        p = p + 2;
        
    end
            
end

validateattributes(args.index,{'numeric'}, ...
            {'positive','finite','integer','scalar'},'','INDEX');
validateattributes(args.autoorient, {'logical'}, {'scalar'}, '', 'AUTOORIENT');
check_info(args.info);

args.pixelregion = process_region(args.pixelregion);


%--------------------------------------------------------------------------
function check_info(info)
%CHECK_INFO Issue error message if user passed in invalid info struct.

if isempty(info)
    return
end

if ~all(isfield(info, {'Filename', 'FileModDate', 'FileSize', ...
                       'Format', 'FormatVersion', 'Width', ...
                       'Height', 'BitDepth', 'ColorType', ...
                       'FormatSignature'}))
    error(message('MATLAB:imagesci:readtif:invalidInfoStruct'));
end


%--------------------------------------------------------------------------
function region_struct = process_region(region_cell)
%PROCESS_PIXELREGION  Convert a cells of pixel region info to a struct.

region_struct = struct([]);
if isempty(region_cell)
    % Not specified in call to readtif.
    return;
end

validateattributes(region_cell,{'cell'},{'numel',2},'','PIXELREGION');

for p = 1:numel(region_cell)
    
    validateattributes(region_cell{p},{'numeric'},{},'','PIXELREGION');
    
    if (numel(region_cell{p}) == 2)
        
        start = max(0, region_cell{p}(1) - 1);
        incr = 1;
        stop = region_cell{p}(2) - 1;
        
    elseif (numel(region_cell{p}) == 3)
        
        start = max(0, region_cell{p}(1) - 1);
        
        validateattributes(region_cell{p}(2),{'numeric'},{'finite','positive'},'','INCREMENT');
        incr = region_cell{p}(2);
        
        stop = region_cell{p}(3) - 1;
       
    else
        
        error(message('MATLAB:imagesci:readtif:tooManyPixelRegionParts'));
        
    end
    
    % g2141497: Incremented start and stop by 1 to keep the error message
    % consistent with MATLAB's 1 based indexing instead of 0 based
    % indexing.
    validateattributes(start + 1 ,{'numeric'},{'<=',stop + 1},'','START');   

    region_struct(p).start = start;
    region_struct(p).incr = incr;
    region_struct(p).stop = stop;

end

