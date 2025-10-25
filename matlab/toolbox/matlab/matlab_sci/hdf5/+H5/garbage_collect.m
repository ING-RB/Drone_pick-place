function garbage_collect
%H5.garbage_collect  Free unused memory in HDF5 library.
%   H5.garbage_collect() frees unused memory in the HDF5 library.
%
%   See also H5.

%   Copyright 2006-2024 The MathWorks, Inc.

matlab.internal.sci.hdf5lib2('H5garbage_collect');            
