function obj_count = get_obj_count(file_id, types)
%H5F.get_obj_count  Return number of open objects in HDF5 file.
%   obj_count = H5F.get_obj_count(file_id, types) returns the number of 
%   open object identifiers for the file specified by file_id for the
%   specified type.  types may be given as one of the following strings:
%
%       'H5F_OBJ_FILE'     
%       'H5F_OBJ_DATASET'  
%       'H5F_OBJ_GROUP'    
%       'H5F_OBJ_DATATYPE' 
%       'H5F_OBJ_ATTR'     
%       'H5F_OBJ_ALL'      
%       'H5F_OBJ_LOCAL'  
%
%   Note: 'H5_OBJ_LOCAL' must be used in combination with other object 
%   types using the logical OR operator (|).
%
%   Example:
%       fid = H5F.open('example.h5');
%       gid = H5G.open(fid,'/g2');
%       obj_count = H5F.get_obj_count(fid,'H5F_OBJ_GROUP');
%       H5G.close(gid);
%       H5F.close(fid);
%
%   See also H5F, H5F.get_obj_ids.

%   Copyright 2006-2024 The MathWorks, Inc.

if nargin > 1
    types = convertStringsToChars(types);
    % Verify if types is a numeric scalar or a char array
    isNumericScalar = isnumeric(types) && isscalar(types);
    isCharVector = ischar(types) && isvector(types);
    if ~(isNumericScalar || isCharVector)
        error(message('MATLAB:imagesci:hdf5lib:badEnumInputType'));
    end
end

if (isnumeric(types))
   % Verify if types is positive numeric because as per HDF5 documentation only 
   % unsigned values are allowed
   validateattributes(types,{'numeric'},{'positive'},'Types');
end

obj_count = matlab.internal.sci.hdf5lib2('H5Fget_obj_count', file_id, types);            
