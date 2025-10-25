function info = imfinfo(source, format)
%IMFINFO Information about graphics file.
%   INFO = IMFINFO(FILENAME,FMT) returns a structure whose fields contain
%   information about an image in a graphics file.  FILENAME is a character
%   vector or string scalar that specifies the name of the graphics file,
%   and FMT is a character vector or string scalar that specifies the
%   format of the file.  FILENAME must be in the current directory, in a
%   directory on the MATLAB path, or include a full or relative path to a
%   file.  If IMFINFO cannot find a file named FILENAME, it looks for a
%   file named FILENAME.FMT.
%   
%   The possible values for FMT are contained in the file format
%   registry, which is accessed via the IMFORMATS command.
%
%   If FILENAME is a TIFF, DNG, HDF, ICO, GIF, or CUR file containing more
%   than one image, INFO is a structure array with one element for
%   each image in the file.  For example, INFO(3) would contain
%   information about the third image in the file.  
%
%   INFO = IMFINFO(FILENAME) attempts to infer the format of the
%   file from its content.
%
%   INFO = IMFINFO(URL,...) returns information on an image from an
%   Internet URL or stored at a remote location.  When reading data from
%   remote locations, you must specify the full path using a uniform
%   resource locator (URL). For example, to read information from an image
%   from Amazon S3 cloud specify the full URL:
%       s3://bucketname/path_to_file/my_image.jpg
%   For more information on accessing remote data, see "Work with Remote
%   Data" in the documentation.
%
%   The set of fields in INFO depends on the individual file and
%   its format.  However, the first nine fields are always the
%   same.  These common fields are:
%
%   Filename       A character vector or string scalar containing the name
%                  of the file or the Internet URL given                  
%
%   FileModDate    A character vector or string scalar containing the
%                  modification date of the file or the date when the image
%                  was downloaded from an URL
%
%   FileSize       An integer indicating the size of the file in
%                  bytes
%
%   Format         A character vector or string scalar containing the file
%                  format, as specified by FMT; for formats with more than one
%                  possible extension (e.g., JPEG and TIFF files),
%                  the first variant in the registry is returned
%
%   FormatVersion  A character vector or string scalar or number specifying the file format
%                  version 
%
%   Width          An integer indicating the width of the image
%                  in pixels
%
%   Height         An integer indicating the height of the image
%                  in pixels
%
%   BitDepth       An integer indicating the number of bits per
%                  pixel 
%
%   ColorType      A character vector or string scalar indicating the type of image; this could
%                  include, but is not limited to, 'truecolor' for a 
%                  truecolor (RGB) image, 'grayscale', for a grayscale 
%                  intensity image, or 'indexed' for an indexed image.
%
%   If FILENAME contains Exif tags (JPEG, TIFF and DNG only), then the INFO 
%   struct may also contain 'DigitalCamera' or 'GPSInfo' (global 
%   positioning system information) fields.
%
%   The value of the GIF format's 'DelayTime' field is given in hundredths
%   of seconds.
%
%   Example:
%     
%      % Read image information from a local file
%      info = imfinfo('ngc6543a.jpg');
%
%      % Read image information from an HTTP server
%      info = imfinfo('http:://hostname/path_to_file/my_image.jpg');
%
%      % Read image information from an Amazon S3 bucket location
%      info = imfinfo('s3://bucketname/path_to_file/my_image.jpg');
%
%   See also IMREAD, IMWRITE, IMFORMATS.

%   Copyright 1984-2024 The MathWorks, Inc.

if nargin > 0
    source = convertStringsToChars(source);
end

if nargin > 1
    format = convertStringsToChars(format);
end

narginchk(1, 2);

info = [];

validateattributes(source,{'char' ,'string'},{'nonempty','scalartext'},'','FILENAME');

% Download remote file.
try
    fileNameObj = getFileFromURL(source);
catch ME
    errorID = ME.identifier;    
    errorID = replace(errorID, 'getFileFromURL', 'imfinfo');
    throw(MException(errorID, ME.message));
end

% If fileNameObj is an object, extract the filename
if ~ischar(fileNameObj)
    filename = fileNameObj.LocalFileName;
else
    filename = fileNameObj;
end 

% Flag to indicate that the user file is on a remote location (for example:
% HTTP, HTTPS, S3, Azure...)
isUrl = ~ischar(fileNameObj);

if (nargin < 2)
  
    % With 1 input argument, we must be able to open the file
    % exactly as given.  Try it.
    
    fid = matlab.internal.fopen(filename, 'r');
    
    if (fid == -1)
      
        error(message('MATLAB:imagesci:imfinfo:fileOpen', filename));
               
    end
      
    filename = matlab.internal.fopen(fid);  % Get the full pathname if not in pwd.
    fclose(fid);
  
    % Determine filetype from file.
    [format, fmt_s] = imftype(filename);
    
    if (isempty(format))
        if matlab.io.internal.vfs.validators.hasIriPrefix(source) && ...
                any(matlab.io.internal.vfs.validators.GetScheme(source) == ["http", "https"]) && ...
                contains(matlab.io.internal.filesystem.getContentType(source), "text/html", IgnoreCase=true)
            % If the file being read is from an HTTP link and its content type is HTML,
            % throw an error. This is because we are attempting to read the HTML content
            % as one of the supported formats. This scenario can occur when the HTTP link
            % requires authentication, and instead of the desired content, we receive a
            % login page.
            error(message('MATLAB:imagesci:imfinfo:readHTML', source));
        else
            % Couldn't determine filetype.
            error(message('MATLAB:imagesci:imfinfo:whatFormat'));
        end
    end
    
else
  
    % The format was passed in.
    % Look for the format in the registry.
    fmt_s = imformats(format);
    
    if (isempty(fmt_s))
      
        % Format was not in registry.
        error(message('MATLAB:imagesci:imfinfo:unknownFormat', format));
        
    end

    % Find the exact name of the file.
    fid = matlab.internal.fopen(filename, 'r');

    if (fid == -1)

        % Since the user explicitly specified the format, see if we can find
        % the file using an extension.
    
        found = 0;
        
        for p = 1:length(fmt_s.ext)
          
            fid = matlab.internal.fopen([filename '.' fmt_s.ext{p}], 'r');
            
            if (fid ~= -1)
              
                % File was found.  Update filename.
                found = 1;
                
                filename = matlab.internal.fopen(fid);
                fclose(fid);
                
                break;
                
            end
            
        end
        
        % Check that some filename+format combination was found.
        if (~found)
            
            error(message('MATLAB:imagesci:imfinfo:fileOpenWithExtension', filename));
            
        end

        
    else
      
        % The file exists as passed in.  Get full pathname from file.
        filename = matlab.internal.fopen(fid);
        fclose(fid);
        
    end
    
    try
        tf = feval(fmt_s.isa, filename);
    catch ME
        if isUrl
            msgtext = replace(ME.message, filename, source);
            newME = MException(ME.identifier, msgtext);
        else
            newME = ME;
        end
        throwAsCaller(newME);
    end 
    if ~tf
        if matlab.io.internal.vfs.validators.hasIriPrefix(source) && ...
                any(matlab.io.internal.vfs.validators.GetScheme(source) == ["http", "https"]) && ...
                contains(matlab.io.internal.filesystem.getContentType(source), "text/html", ...
                IgnoreCase=true)
            % If the file being read is from an HTTP link and its content type is HTML,
            % throw an error. This is because we are attempting to read the HTML content
            % as one of the supported image formats. This scenario can occur when the HTTP link
            % requires authentication, and instead of the image, we receive a
            % login page.
            error(message('MATLAB:imagesci:imfinfo:readHTML', source));
        else
            error(message('MATLAB:imagesci:imfinfo:badFormat', source, upper(format)));
        end
    end

end

% Call info function from IMFORMATS on filename
if (~isempty(fmt_s.info))
    
    try
        info = feval(fmt_s.info, filename);
    catch ME
        if isUrl
            msgtext = replace(ME.message, filename, source);
            newME = MException(ME.identifier, msgtext);
        else
            newME = ME;
        end
        throwAsCaller(newME);
    end        
    
else
  
     error(message('MATLAB:imagesci:imfinfo:noInfoFunction', format));
        
end

% add the "Auto-Oriented" width and height to the output struct 
% (based on Exif Orientation tag)
info = addExifOrientationWidthAndHeight(info);

if ~ischar(fileNameObj)

    % Replace the temporary file name with the URL.  Ensure handling
    % of multiframe files. The file is temporary if fileNameObj 
    % contains an object
    [info(:).Filename] = deal(source);

end
