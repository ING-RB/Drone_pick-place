function create_external(varargin)
%H5L.create_external  Create soft link to external object.
%   H5L.create_external(filename,objname,link_loc_id,link_name,lcpl_id,lapl_id)
%   creates a soft link to an object in a different file.  filename
%   identifies the target file containing the target object.  obj_name
%   specifies the path to the target object within that file.  obj_name
%   must start at the target file's root group but is not interpreted
%   until lookup time.
%
%   H5L.create_external(URL,objname,link_loc_id,link_name,lcpl_id,lapl_id)
%   creates a soft link to an object in a different file.  URL identifies
%   the target file in a remote location containing the target object.When
%   reading data from remote locations, you must specify the full path
%   using a uniform resource locator (URL). For example, to
%   read a dataset in an HDF5 file from Amazon S3 cloud specify the full
%   URL for the file:
%       s3://bucketname/path_to_file/example.h5
%   For more information on accessing remote data, see "Work with Remote Data"
%   in the documentation.
%
%   link_loc_id and link_name specify the location and name, respectively,
%   of the new link. link_name is interpreted relative to link_loc_id.
% 
%   lcpl_id and lapl_id are the link creation and access property lists
%   associated with the new link.
%
%   Example:
%       plist_id = 'H5P_DEFAULT';
%       fid1 = H5F.create('myfile1.h5');
%       g1 = H5G.create(fid1,'g1',plist_id,plist_id,plist_id);
%       H5G.close(g1);
%       H5F.close(fid1);
%       fid2 = H5F.create('myfile2.h5');
%       H5L.create_external('myfile1.h5','g1',fid2,'g2',plist_id,plist_id);
%
%
%   See also H5L.

%   Copyright 2009-2024 The MathWorks, Inc.


if nargin > 0
    [varargin{:}] = convertStringsToChars(varargin{:});
end

if matlab.io.internal.vfs.validators.hasIriPrefix(varargin{1})
    error(message('MATLAB:imagesci:hdf5io:unsupportedOperation'));
end
matlab.internal.sci.hdf5lib2('H5Lcreate_external', varargin{:});            
