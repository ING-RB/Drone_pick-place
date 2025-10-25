function X = imencode(imageData, format, varargin)
    %MATLAB.INTERNAL.IMENCODE Write image to graphics buffer.
    %   X = MATLAB.INTERNAL.IMENCODE (IMAGEDATA,FORMAT) writes IMAGEDATA
    %   into an uint8 buffer X in the format specified by FORMAT.
    %
    %   IMAGEDATA can be an M-by-N (grayscale image) or M-by-N-by-3 (color
    %   image) array. IMAGEDATA cannot be an empty array.
    %
    %   FORMAT is a character vector or string scalar specifying the format
    %   of the encoded data. Supported formats are JPEG, JPG and PNG.
    %
    %   Class Support
    %   -------------
    %   The input array IMAGEDATA can be of class logical, uint8, uint16.
    %   Input values must be full (non-sparse).
    %
    %   The class of the image written to the buffer depends on the format
    %   specified.  For most formats, if the input array is of class uint8,
    %   IMENCODE outputs the data as 8-bit values.  If the input array is
    %   of class uint16 and the format supports 16-bit data (JPEG, and
    %   PNG), IMENCODE outputs the data as 16-bit values.  If the format
    %   does not support 16-bit values, IMENCODE issues an error.  Several
    %   formats, such as JPEG and PNG, support a parameter that lets you
    %   specify the bit depth of the output data. Currently, IMENCODE does
    %   not allow encoding of imagedata in PNG format by changing its bit
    %   depth.
    %
    %   If the input array is of class logical, IMENCODE assumes the data
    %   is binary image and writes it to the buffer with a bit depth of 1,
    %   if the format allows it.  IMENCODE accepts binary images as input
    %   arrays for PNG encoding.
    %
    %   JPEG-specific parameters
    %   ------------------------
    %   'Quality'      A number between 0 and 100; higher numbers
    %                  mean quality is better (less image degradation
    %                  due to compression), but the resulting buffer
    %                  size is larger
    %
    %   'Comment'      Comment must be a character vector or a string 
    %                  scalar. The input is written out as a comment in the
    %                  JPEG buffer.
    %
    %   'Mode'         Either 'lossy' (the default) or 'lossless'
    %
    %   'BitDepth'     A scalar value indicating desired bitdepth;
    %                  for grayscale images this can be 8, 12, or 16;
    %                  for truecolor images this can be 8 or 12.  Only
    %                  lossless mode is supported for 16-bit images.
    %
    %   PNG-specific parameters
    %   ----------------------
    %
    %   'BitDepth'     A scalar value indicating desired bitdepth;
    %                  It should be same as input datatype of image ie
    %                  1,8,16
    %

    %
    %   Table: summary of supported image types
    %   ---------------------------------------
    %   JPEG      8-bit, 12-bit, and 16-bit Baseline JPEG images
    %
    %   PNG       8-bit, and 16-bit grayscale, RGB images
    %             and logical images.

    %   Copyright 2021-2022 The MathWorks, Inc.

    arguments
        imageData {validateattributes(imageData,{'numeric','logical'},{'nonempty','nonsparse'},'','IMAGEDATA')}
        format char {mustBeTextScalar, validateFormat(format)}
    end

    arguments(Repeating)
        varargin
    end

    if nargin > 0
        [varargin{:}] = convertStringsToChars(varargin{:});
    end

    paramPairs = validateOptionalNVPairs(varargin{:});

    format = lower(format);
    % Signed data may cause unexpected results.
    switch (class(imageData))
        case {'int8', 'int16', 'int32', 'int64'}

            switch format
                case {'jpg', 'jpeg'}
                    error(message('image_io:imencode:signedJPEGNotSupported'));
                otherwise
                    warning(message('image_io:imencode:signedPixelData'))
            end
    end

    switch format
        case {'jpg', 'jpeg'}
            props = set_jpeg_props(imageData, paramPairs{:});
        case 'png'
            props = set_png_props(paramPairs{:});
    end

    % If parsing is successful, get the decoded image
    try
        X = matlab.internal.imageio.imencode(imageData, upper(format), props);
    catch ME
        throwAsCaller(ME);
    end

end

function validateFormat(format)
    allowedFormats = ["jpeg","jpg","png"];
    if ~contains(allowedFormats, format, 'IgnoreCase',true)
        error(message('image_io:imencode:invalidFormat',format));
    end
end


function paramPairs = validateOptionalNVPairs(varargin)

    paramPairs = varargin;

    if (nargin > 0)
        % Do some validity checking on param-value pairs
        if (rem(length(paramPairs), 2) ~= 0)
            error(message('image_io:imencode:invalidSyntax'));
        end
    end

    % Validate that first entry in each Name-Value pair is a char vector or
    % a scalar string
    for k = 1:2:length(paramPairs)
        validateattributes(paramPairs{k},{'char', 'string'},{'nonempty', 'scalartext'},'','PARAMETER NAME');
    end
end


function props = set_png_props(varargin)
    % SET_PNG_PROPS
    %
    % Parse input parameters to produce a properties structure.

    % Set the default properties.
    props.BitDepth = -1;

    % Process param/value pairs
    for k = 1:2:length(varargin)
        param = validatestring(varargin{k},{'bitdepth'});
        props = process_argument_value ( props, param, varargin{k+1} );
    end
end

function props = set_jpeg_props(data,varargin)
    % SET_JPEG_PROPS
    %
    % Parse input parameters to produce a properties structure.

    % Set the default properties.
    props.BitDepth = -1;

    % Process param/value pairs
    for k = 1:2:length(varargin)
        param = validatestring(varargin{k},{'quality','comment','bitdepth','mode'});
        props = process_argument_value ( props, param, varargin{k+1} );
    end

    if (props.BitDepth == -1)
        switch(class(data))
            case 'uint16'
                props.BitDepth = 16;
            otherwise
                props.BitDepth = 8;
        end
    end
    
    % Special case for UINT16 data.  If handed UINT16 data, then the bitdepth
    % has to be 12 or 16. 
    if ( isa(data,'uint16') && (~((props.BitDepth == 16) || (props.BitDepth ==12))) )
        error(message('image_io:imencode:bitdepthNotSpecifiedAt16'));
    end
end



% Process a parameter name/value pair, return the new property structure
function output_props = process_argument_value ( props, param_name, param_value )

    output_props = props;

    switch param_name
        case 'quality'
            quality = param_value;
            validateattributes(quality,{'numeric'},{'real','scalar','>=',0,'<=',100},'','QUALITY');
            output_props.Quality = quality;

        case 'comment'
            validateattributes(param_value, {'char', 'string'}, "scalartext", '', 'comment');
            comment = convertStringsToChars(param_value);
            output_props.Comment = comment;

        case 'bitdepth'
            bits = param_value;
            validateattributes(bits,{'numeric'},{'scalar','positive','integer'},'','BITDEPTH');
            output_props.BitDepth = double(bits);

        case 'mode'
            mode = validatestring(param_value,{'lossy','lossless'});
            output_props.Mode = mode;
    end
end
