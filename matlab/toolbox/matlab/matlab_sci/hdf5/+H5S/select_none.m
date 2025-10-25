function select_none(space_id)
%H5S.select_none  Reset selection region to include no elements.
%   H5S.select_none(space_id) resets the selection region for the dataspace 
%   space_id to include no elements.
%
%   Example:
%       fid = H5F.open('example.h5');
%       dset_id = H5D.open(fid,'/g3/integer');
%       space_id = H5D.get_space(dset_id);
%       num_points1 = H5S.get_select_npoints(space_id);
%       H5S.select_none(space_id);
%       num_points2 = H5S.get_select_npoints(space_id);
%
%   See also H5S.

%   Copyright 2006-2024 The MathWorks, Inc.

matlab.internal.sci.hdf5lib2('H5Sselect_none', space_id);            
