function name = getName(cdfId)
%cdflib.getName Return file name of specified CDF
%   name = cdflib.getName(cdfId) returns the file name of the specified CDF.
%
%   This function corresponds to the CDF library C API routine 
%   CDFgetName.
%
%   Please read the file cdfcopyright.txt for more information.
%
%   See also cdflib, cdflib.inquire.

% Copyright 2009-2022 The MathWorks, Inc.

name = matlab.internal.imagesci.cdflib('getName',cdfId);
