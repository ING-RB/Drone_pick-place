function closeFile(fptr)
%closeFile Close FITS file.
%   closeFile(FPTR) closes an open FITS file.
%
%   This function corresponds to the "fits_close_file" (ffclos) function in 
%   the CFITSIO library C API.
%
%   Example:
%       import matlab.io.*
%       fptr = fits.openFile('tst0012.fits','READONLY');
%       fits.closeFile(fptr);
%
%   See also fits, createFile, openFile.

%   Copyright 2011-2020 The MathWorks, Inc.

validateattributes(fptr,{'uint64'},{'scalar'},'','FPTR');

matlab.internal.imagesci.fitsiolib('close_file',fptr);
