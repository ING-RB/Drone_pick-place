function setFormat(cdfId,fmt)
%cdflib.setFormat Specify file format of CDF
%   cdflib.setFormat(cdfId,fmt) specifies the file format.  The format can
%   be either one of the strings 'SINGLE_FILE' or 'MULTI_FILE', or the
%   numeric equivalent.
%
%   This function corresponds to the CDF library C API routine 
%   CDFsetFormat.  
%
%   Example:
%       cdfid = cdflib.create('myfile.cdf');
%       cdflib.setFormat(cdfid,'MULTI_FILE');
%       cdflib.close(cdfid);
%
%   Please read the file cdfcopyright.txt for more information.
%
%   See also cdflib, cdflib.getFormat, cdflib.getConstantValue.

% Copyright 2009-2022 The MathWorks, Inc.

if nargin > 1
    fmt = convertStringsToChars(fmt);
end

if ischar(fmt)
	fmt = cdflib.getConstantValue(fmt);
end
matlab.internal.imagesci.cdflib('setFormat',cdfId,fmt);
