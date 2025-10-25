function [start,stride,count,block] = get_regular_hyperslab(space_id)
%H5S.get_regular_hyperslab(space_id) retrieves a regular hyperslab
%selection
%   H5S.get_regular_hyperslab retrieves the value of start, stride, count
%   and block for the regular hyperslab selection for the dataspace
%   associated with the file identifier space_id. A regular hyperslab
%   selection is a hyperslab selection described by setting the offset,
%   stride, count, and block parameters to the H5S_SELECT_HYPERSLAB call.
%   If several calls to H5S_SELECT_HYPERSLAB are needed, the hyperslab
%   selection is irregular.
%
%   Note:  The HDF5 C library uses C-style ordering for multidimensional 
%   arrays, while MATLAB uses FORTRAN-style ordering. The start, stride,
%   count and block parameters assume C-style ordering.  Please consult
%   the "Report Data Set Dimensions" section in the MATLAB "Exporting to
%   HDF5 Files" topic page for more information.
%
%   Example: 
%         % Select a regular hyperslab and retrieve the selection
%         % Create a simple dataspace
%         space_id = H5S.create_simple(2,[10 10],[]);
%         % Select a hyperslab
%         H5S.select_hyperslab(space_id,'H5S_SELECT_SET',[0 0],[2 2],[4 4],[2 2]); 
%         % Retrieve the hyperslab parameters
%         [start,stride,count,block] = H5S.get_regular_hyperslab(space_id)
%   
%   See also H5S.is_regular_hyperslab, H5S.select_hyperslab

%   Copyright 2021-2024 The MathWorks, Inc.

validateattributes(space_id,{'H5ML.id'},{'nonempty'});
[start,stride,count,block] = matlab.internal.sci.hdf5lib2(...
    'H5Sget_regular_hyperslab',space_id);
