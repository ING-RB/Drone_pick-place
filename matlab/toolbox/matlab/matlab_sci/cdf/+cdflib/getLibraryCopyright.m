function copyright = getLibraryCopyright()
%cdflib.getLibraryCopyright Return copyright notice
%   copyright = cdflib.getLibraryCopyright() returns the copyright notice of
%   the CDF library being used.
%
%   This function corresponds to the CDF library C API routine 
%   CDFgetLibraryCopyright.  
%
%   Please read the file cdfcopyright.txt for more information.
%
%   See also cdflib, cdflib.getCopyright.

% Copyright 2009-2022 The MathWorks, Inc.

copyright = matlab.internal.imagesci.cdflib('getLibraryCopyright');
