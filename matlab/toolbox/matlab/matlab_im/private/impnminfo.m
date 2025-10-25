function info = impnminfo(filename)
%IMPNMINFO Get information about the image in a PPM/PGM/PBM file.
%
%   INFO = IMPNMINFO(FILENAME) returns information about the image
%   contained in a PPM, PGM or PBM file.  
%
%   PNM is not an image format by itself but means any of PPM, PGM, and PBM.
%
%   See also IMREAD, IMWRITE, IMFINFO.

%   The PNM formats PPM, PGM and PBM are described in the UNIX manual pages
%   ppm(5), pgm(5) and pbm(5) respectively.
%
% Author:	  Peter J. Acklam
% E-mail:	  pjacklam@online.no

%  Copyright 2001-2022 The MathWorks, Inc.

% Try to open the file for reading.  
% Note: We specify US-ASCII as the character encoding to avoid invoking
%       auto-charset detection on what could be a binary file. This code
%       uses fscanf('%c') and fgetl, both of which depend on the file
%       encoding for correct operation.
fid = matlab.internal.fopen(filename, 'r', 'n', 'US-ASCII');
assert(fid ~= -1, message('MATLAB:imagesci:validate:fileOpen', filename));

% There might be multiple images in the file. The exact number of images
% cannot be determined before hand.
info = [];

% Initialize universal structure fields to fix the order
while true
    
    currImageInfo = initializeMetadataStruct('pnm', fid);

    currImageInfo.FormatSignature = [];

    % Initialize PNM-specific structure fields to fix the order.

    currImageInfo.Encoding        = '';
    currImageInfo.MaxValue        = [];
    currImageInfo.ImageDataOffset = [];

    % Look for the magic number (i.e., format signature).
    [magicNumber, count] = fscanf(fid, '%c', 2);
    if (count < 2)
        fclose(fid);
        error(message('MATLAB:imagesci:impnminfo:emptyMagicNumber'));
    end
    currImageInfo.FormatSignature = magicNumber;
    currImageInfo.FormatVersion   = magicNumber;   

    % Get the image format and encoding ('ASCII' is ascii, 'rawbits' is binary).
    switch magicNumber
        case 'P1'
            currImageInfo.Format	    = 'PBM';
            currImageInfo.ColorType	= 'grayscale';	% black and white, actually
            currImageInfo.Encoding	= 'ASCII';
        case 'P2'
            currImageInfo.Format	    = 'PGM';
            currImageInfo.ColorType	= 'grayscale';	% black and white, actually
            currImageInfo.Encoding	= 'ASCII';
        case 'P3'
            currImageInfo.Format	    = 'PPM';
            currImageInfo.ColorType	= 'truecolor';
            currImageInfo.Encoding	= 'ASCII';
        case 'P4'
            currImageInfo.Format	    = 'PBM';
            currImageInfo.ColorType	= 'grayscale';
            currImageInfo.Encoding	= 'rawbits';
        case 'P5'
            currImageInfo.Format	    = 'PGM';
            currImageInfo.ColorType	= 'grayscale';
            currImageInfo.Encoding	= 'rawbits';
        case 'P6'
            currImageInfo.Format	    = 'PPM';
            currImageInfo.ColorType	= 'truecolor';
            currImageInfo.Encoding	= 'rawbits';
        otherwise
            fclose(fid);			% close file
            error(message('MATLAB:imagesci:impnminfo:invalidMagicNumber'));
    end

    % Read image size.
    [header_data, count] = pnmgeti(fid, 2);
    if count < 2
        fclose(fid);			% close file
        error(message('MATLAB:imagesci:impnminfo:unexpectedEOF'));
    end

    currImageInfo.Width  = header_data(1);	% image width
    currImageInfo.Height = header_data(2);	% image height

    % Read the maximum color-component value.  PBM images do not explicitly
    % contain this value because it has to be 1. The maximum color component
    % value of PGM and PPM images may be any positive integer so BitDepth
    % might not be an integer!
    if strcmp(currImageInfo.Format, 'PBM')
        currImageInfo.MaxValue = 1;
    else
        [header_data, count] = pnmgeti(fid, 1);
        if count < 1
            fclose(fid);			% close file
            error(message('MATLAB:imagesci:impnminfo:maxValueTruncated'));
        end
        currImageInfo.MaxValue = header_data(1);
    end

    currImageInfo.BitDepth = log2(currImageInfo.MaxValue + 1);
    % Because truecolor images have 3 channels
    if strcmp(currImageInfo.ColorType,'truecolor')
        currImageInfo.BitDepth = currImageInfo.BitDepth * 3;
    end

    % Raw PNM images should have a single byte of whitespace between the
    % image header and the pixel area.  Plain PNM images might have more
    % whitespace and even comments but the main point in the plain case is
    % that we are past the header.
    currImageInfo.ImageDataOffset = ftell(fid) + 1;

    if isempty(info)
        info = currImageInfo;
    else
        info(end+1) = currImageInfo;
    end
    
    % Plain PGM's which contain only 1 image per file.
    if currImageInfo.Encoding == "ASCII"
        break;
    end
    
    % The code below applies only for RAW PGM files which are most common.
    
    % The next image in the file (if present) is stored immediately after
    % the current one ends. Calculate the size in bytes of the current
    % image
    numBytesInCurrImage = computeNumBytesInImage(currImageInfo);
    
    % Seek the location in the file after the current image and verify if
    % the values are start with PNM "magic number"
    fseek(fid, numBytesInCurrImage+1, 'cof');
    
    % Store this position. If another image is found, then we have to parse
    % starting at this location
    nextImageStartPos = ftell(fid);
    
    % Read ahead 2 characters to determine if the magic number is present.
    imageCode = fscanf(fid, '%c', 2);
    if isempty(regexp(imageCode, 'P[1-6]', 'once'))
        break;
    end    
    
    % Reset to the start of the next image
    fseek(fid, nextImageStartPos, 'bof');
end

% We've got what we need, so close the file.
fclose(fid);

function numBytesInImage = computeNumBytesInImage(info)

numChannels = 1;
if info.Format == "PPM"
  numChannels = 3;
end
   
if info.Encoding == "rawbits"
    switch(info.Format)
        case 'PBM'
            % raw PBM files use a whole number of bytes for each scanline
            valWidth = ceil(info.Width/8);
            numElemsInImage = valWidth*info.Height;
        case {'PGM', 'PPM'}
            numElemsInImage = info.Height*info.Width*numChannels;
    end
    
    if info.MaxValue <= 255
        numBytesPerElem = 1;
    elseif info.MaxValue <= 65535
        numBytesPerElem = 2;
    else
        m = message('MATLAB:imagesci:readpnm:badMaxval', filename, info.MaxValue);
        newID = replace(m.Identifier, 'readpnm', 'impnminfo');
        error(newID, m.getString());
    end
    
    numBytesInImage = numElemsInImage*numBytesPerElem;
else
    error(message('MATLAB:imagesci:impnminfo:plainPNMASCIIContainsOneImage'));
end
