function info = imjpginfo(filename, baseline_only ,options)
%IMJPGINFO Information about a JPEG file.
%   INFO = IMJPGINFO(FILENAME) returns a structure containing
%   information about the JPEG file specified by the string
%   FILENAME.  
%
%   INFO = IMJPGINFO(FILENAME,BASELINE_ONLY=true) returns a structure with
%   only metadata as provided directly by the JPEG file.  Any Exif
%   or directory metadata is omitted.
%
%   INFO = IMJPGINFO(FILENAME,"readXmpData",true) returns a structure with 
%   xmp data as provided directly by the JPEG file
%
%   See also IMREAD, IMWRITE, IMFINFO.

%   Copyright 1984-2024 The MathWorks, Inc.

arguments
    filename (1, :) char
    baseline_only (1, 1) logical = false
    options.readXmpData  (1, 1) logical = true
end

info = matlab.io.internal.imagesci.imjpginfo(filename, baseline_only, "readXmpData",options.readXmpData);

