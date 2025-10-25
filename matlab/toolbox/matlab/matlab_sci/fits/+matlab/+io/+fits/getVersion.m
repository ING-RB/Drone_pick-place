function v = getVersion()
%getVersion return revision number of the CFITSIO library
%   V = getVersion() returns the revision number of the CFITSIO library.
%   
%   This function corresponds to the "fits_get_version" (ffvers) function
%   in the CFITSIO library C API.
%
%   Example:
%       import matlab.io.*
%       v = fits.getVersion();
%
%   See also fits.

%   Copyright 2011-2020 The MathWorks, Inc.

v = matlab.internal.imagesci.fitsiolib('get_version');
