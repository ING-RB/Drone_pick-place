function name = get_name_by_idx(loc_id, group_name, idx_type, order, n, lapl_id, varargin)
%H5L.get_name_by_idx  Retrieve information about link specified by index.
%   name = H5L.get_name_by_idx(loc_id,group_name,idx_type,order,n,lapl_id)
%   retrieves the name of the link at index n present in the group
%   group_name at location loc_id. lapl_id specifies the link access
%   property list for querying the group.
%
%   idx_type is the type of index and valid values include the following: 
%  
%      'H5_INDEX_NAME'      - alpha-numeric index on name
%      'H5_INDEX_CRT_ORDER' - index on creation order
% 
%   order specifies the index traversal order. Valid values include the
%   following: 
%  
%      'H5_ITER_INC'    - iteration is from beginning to end
%      'H5_ITER_DEC'    - iteration is from end to beginning
%      'H5_ITER_NATIVE' - iteration is in the fastest available order
%
%   name = H5L.get_name_by_idx(__, 'TextEncoding', 'UTF-8') retrieves the
%   name of the link at the specified index while ensuring that the name
%   is handled as UTF-8 encoded text.  This usage is unnecessary if the
%   HDF5 file accurately specifies the use of UTF-8 encoding for the
%   resulting name.
%
%   Example:
%       fid = H5F.open('example.h5');
%       idx_type = 'H5_INDEX_NAME';
%       order = 'H5_ITER_DEC';
%       lapl_id = 'H5P_DEFAULT';
%       name = H5L.get_name_by_idx(fid,'g3',idx_type,order,0,lapl_id);
%       H5F.close(fid);
%
%   See also H5L.

%   Copyright 2009-2024 The MathWorks, Inc.

if nargin > 1
    group_name = convertStringsToChars(group_name);
end

if nargin > 2
    idx_type = convertStringsToChars(idx_type);
end

if nargin > 3
    order = convertStringsToChars(order);
end

if nargin > 5
    lapl_id = convertStringsToChars(lapl_id);
end

if nargin > 6
    [varargin{:}] = convertStringsToChars(varargin{:});
end

useUtf8 = matlab.io.internal.imagesci.h5ParseEncoding(varargin);
name = matlab.internal.sci.hdf5lib2('H5Lget_name_by_idx', ...
    loc_id, group_name, idx_type, order, n, lapl_id, useUtf8);            
