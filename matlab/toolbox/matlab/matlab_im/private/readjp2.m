function [A, map] = readjp2(filename, varargin)
%READJP2 Read image data from JPEG 2000 files.
%   A = READJP2(FILENAME) reads image data from a JPEG file.
%   A is a 2-D grayscale or 3-D RGB image whose type depends on the
%   bit-depth of the image (logical, uint8, uint16, int8, int16).
%
%   A = READJP2(FILENAME, 'Param1', value1, 'Param2', value2, ...) uses
%   parameter-value pairs to control the read operation.  
%
%       Parameter name   Value
%       --------------   -----
%       'ReductionLevel' A non-negative integer specifying the reduction in
%                        the resolution of the image. For a reduction 
%                        level 'L', the image resolution is reduced by a 
%                        factor of 2^L. The default value is 0 implying 
%                        no reduction. The reduction level is limited by 
%                        the total number of decomposition levels as  
%                        provided by 'WaveletDecompositionLevels' field  
%                        in the structure returned from IMFINFO function.   
%
%       'PixelRegion'    {ROWS, COLS}.  IMREAD returns the sub-image
%                        specified by the boundaries in ROWS and COLS.
%                        ROWS and COLS must both be two-element vectors
%                        that denote the 1-based indices [START STOP]. If
%                        'ReductionLevel' is greater than 0, then ROWS and
%                        COLS are coordinates in the reduced-sized image.   
%
%       'V79Compatible'  A logical value. If true, the image returned is 
%                        transformed to gray-scale or RGB as consistent with
%                        previous versions of IMREAD (MATLAB 7.9 [R2009b] 
%                        and earlier).  Use this option to transform YCC
%                        images into RGB.  The default is false.
%
%       'AutoOrient'     A logical value; is ignored for JP2 images. The
%                        default is false.
%
%   See also IMREAD.

%   Copyright 2008-2024 The MathWorks, Inc.

options = parse_args(varargin{:});


% Setup default options.
options.useResilientMode = false;  % default is fast mode

% Call the interface to the Kakadu library.
try
	A = matlab.internal.imagesci.readjp2c(filename,options);

catch firstException
	
	switch firstException.identifier
		case 'MATLAB:imagesci:jp2adapter:ephMarkerNotFollowingPacketHeader'

		    % Try resilient mode.  
			options.useResilientMode = true;
			try
				A = matlab.internal.imagesci.readjp2c(filename,options);

				% Ok we succeeded.  Issue a warning to the user that their
				% file might have some problems.  
				warning(message('MATLAB:imagesci:readjp2:ephMarkerNotFollowingPacketHeader', filename, firstException.message));

			catch secondException
				% Ok it's hopeless, just give up.
				rethrow(firstException);	
			end

		otherwise
			% We don't know what to try.  Give up.
			rethrow(firstException);	
	end


end
map = [];

function args = parse_args(varargin)
%PARSE_ARGS  Convert input arguments to structure of arguments.

args.reductionlevel = 0;
args.pixelregion = [];
args.v79compatible = false;
args.AutoOrient = false; 

params = {'reductionlevel', 'pixelregion', 'v79compatible', 'autoorient'};

% Process varargin into a form that we can use with the input parser.
for k = 1:2:length(varargin)
    if (~ischar(varargin{k}))
        error(message('MATLAB:imagesci:readjp2:paramType'));
    end
    
    prop = lower(varargin{k});
    idx = find(strncmp(prop, params, numel(prop)));
    if (numel(idx) > 1)
        error(message('MATLAB:imagesci:validate:ambiguousParameterName', prop));
    elseif isscalar(idx)
        varargin{k} = params{idx};
    end
    
end

p = inputParser;
p.addParameter('reductionlevel',0, ...
    @(x)validateattributes(x,{'numeric'},{'integer','finite','nonnegative','scalar'},'','REDUCTIONLEVEL'));
p.addParameter('v79compatible',false, ...
    @(x)validateattributes(x,{'logical'},{'scalar'},'','V79COMPATIBLE'));
p.addParameter('pixelregion',[], ...
    @(x)validateattributes(x,{'cell'},{'numel',2},'','PIXELREGION'));
p.addParameter('autoorient', false, ...
    @(x)validateattributes(x, {'logical'}, {'scalar'}, '', 'AUTOORIENT'));

p.parse(varargin{:});

args.reductionlevel = p.Results.reductionlevel;
args.v79compatible = p.Results.v79compatible;
args.pixelregion = process_region(p.Results.pixelregion);
args.autoorient = p.Results.autoorient; % AutoOrient is ignored for JP2 images



%--------------------------------------------------------------------------=
function region_struct = process_region(region_cell)
%PROCESS_PIXELREGION  Convert a cells of pixel region info to a struct.

region_struct = struct([]);
if isempty(region_cell)
    % Not specified in call to readjp2.
    return;
end

for p = 1:numel(region_cell)
    
    validateattributes(region_cell{p},{'numeric'},{'integer','finite','positive','numel',2},'','PIXELREGION');
    
    start = max(0, region_cell{p}(1) - 1);
    stop = region_cell{p}(2) - 1;
        
    if (start > stop)
        error(message('MATLAB:imagesci:readjp2:badPixelRegionStartStop'))
    end

    region_struct(p).start = start;
    region_struct(p).stop = stop;

end



