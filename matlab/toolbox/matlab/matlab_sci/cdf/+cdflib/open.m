function cdfId = open(filename)
%cdflib.open Open existing CDF
%   cdfId = cdflib.open(filename) opens an existing CDF file identified by
%   filename and returns a file ID.
% 
%   All CDFs opened via this method have the zMode set to zMODEon2.  Please
%   refer to the CDF User's Guide for a discussion of zModes.
%
%   This function corresponds to the CDF library C API routine 
%   CDFopenCDF.  
%
%   Example:
%       cdfid = cdflib.open('example.cdf');
%       cdflib.close(cdfid);
%
%   Please read the file cdfcopyright.txt for more information.
%
%   See also cdflib, cdflib.close, cdflib.create.

%   Copyright 2009-2022 The MathWorks, Inc.

% Get the full path name.
if nargin > 0
    filename = convertStringsToChars(filename);
end

fid = fopen(filename,'r');
if fid == -1
    error(message('MATLAB:imagesci:cdflib:fileOpenError'));
end
filename = fopen(fid);
fclose(fid);

cdfId = matlab.internal.imagesci.cdflib('open',filename);
