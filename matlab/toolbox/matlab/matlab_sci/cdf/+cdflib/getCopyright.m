function copyright = getCopyright(cdfId)
%cdflib.getCopyright Return copyright notice in CDF file 
%   copyright = cdflib.getCopyright(cdfId) returns the copyright notice in 
%   a CDF file identified by cdfId.  
%
%   This function corresponds to the CDF library C API routine 
%   CDFgetCopyright.  
%
%   Please read the file cdfcopyright.txt for more information.
%
%   See also cdflib, cdflib.getLibraryCopyright.

% Copyright 2009-2022 The MathWorks, Inc.

copyright = matlab.internal.imagesci.cdflib('getCopyright',cdfId);
