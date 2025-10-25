function select_all(space_id)
%H5S.select_all  Select entire extent of dataspace.
%   H5S.select_all(space_id) selects the entire extent of the dataspace 
%   specified by space_id.
%
%   Example:
%       fid = H5F.open('example.h5');
%       dset_id = H5D.open(fid,'/g3/integer');
%       space_id = H5D.get_space(dset_id);
%       num_points1 = H5S.get_select_npoints(space_id);
%       H5S.select_none(space_id);
%       num_points2 = H5S.get_select_npoints(space_id);
%       H5S.select_all(space_id);
%       num_points3 = H5S.get_select_npoints(space_id);
% 
%   See also H5S.

%   Copyright 2006-2024 The MathWorks, Inc.

matlab.internal.sci.hdf5lib2('H5Sselect_all', space_id);            
