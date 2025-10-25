function set_libver_bounds(fapl_id,low,high)
%H5P.set_libver_bounds  Set library version bounds for objects.
%   H5P.set_libver_bounds(fapl_id,low,high) sets bounds on library
%   versions, and indirectly format versions, to be used when creating
%   objects in the file with access property list fapl_id. Low must be set
%   to 'H5F_LIBVER_EARLIEST', 'H5F_LIBVER_V18', 'H5F_LIBVER_V110',
%   'H5F_LIBVER_V112', 'H5F_LIBVER_V114', or 'H5F_LIBVER_LATEST'. High must
%   be set to 'H5F_LIBVER_V18', 'H5F_LIBVER_V110', 'H5F_LIBVER_V112',
%   'H5F_LIBVER_V114', or 'H5F_LIBVER_LATEST'.
%   
%   Note 'H5F_LIBVER_LATEST' is mapped to the highest enumerated value
%   in the HDF5 C library struct H5F_libver_t, indicating this is 
%   the latest format available.  
%
%   Please consult the H5Pset_libver_bounds documentation in the HDF5
%   C library for more information about the different combinations of
%   low/high values and their effect on object creation and access.
%
%   Example:  Create an HDF5 file where objects are created using the 
%   latest available format for each object.
%      fcpl = H5P.create('H5P_FILE_CREATE');
%      fapl = H5P.create('H5P_FILE_ACCESS');
%      H5P.set_libver_bounds(fapl,'H5F_LIBVER_LATEST','H5F_LIBVER_LATEST');
%      fid = H5F.create('myfile.h5','H5F_ACC_TRUNC',fcpl,fapl);
%      H5F.close(fid);
%      H5P.close(fapl);
%      H5P.close(fcpl);
%
%   See also H5P, H5P.get_libver_bounds, H5ML.get_constant_value.

%   Copyright 2006-2024 The MathWorks, Inc.

if nargin > 1
    low = convertStringsToChars(low);
end

if nargin > 2
    high = convertStringsToChars(high);
end

matlab.internal.sci.hdf5lib2('H5Pset_libver_bounds',fapl_id,low,high);
