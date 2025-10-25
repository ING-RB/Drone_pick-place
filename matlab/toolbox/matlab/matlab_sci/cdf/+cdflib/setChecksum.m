function setChecksum(cdfId,mode)
%cdflib.setChecksum Specify checksum mode
%   cdflib.setChecksum(cdfId,mode) specifies the checksum mode of the CDF
%   identified by cdfId.  mode can be either 'MD5_CHECKSUM', 'NO_CHECKSUM',
%   or the equivalent enumerated numeric value defined by the library.
%
%   The checksum mode may also be controlled by setting the environment 
%   variable CDF_CHECKSUM.  Please consult the CDF User's Guide for 
%   details.
%
%   Example:
%       cdfid = cdflib.create('myfile.cdf');
%       cdflib.setChecksum(cdfid,'MD5_CHECKSUM');
%       cdflib.close(cdfid);
%
%   This function corresponds to the CDF library C API routine 
%   CDFsetChecksum.  
%
%   Please read the file cdfcopyright.txt for more information.
% 
%   See also cdflib, cdflib.getChecksum, cdflib.getConstantValue.

% Copyright 2009-2022 The MathWorks, Inc.

if nargin > 1
    mode = convertStringsToChars(mode);
end

if ischar(mode)
	mode = matlab.internal.imagesci.cdflib('getConstantValue',mode);
end
matlab.internal.imagesci.cdflib('setChecksum',cdfId,mode);
