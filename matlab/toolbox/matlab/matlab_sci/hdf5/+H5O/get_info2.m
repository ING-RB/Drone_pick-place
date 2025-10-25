function info = get_info2(obj_id, fields)
%H5O.get_info2  Retrieve information for object.
%   info = H5O.get_info2(obj_id,fields) retrieves the metadata for an
%   object specified by obj_id.  fields contains flags to determine
%   which fields wil be filled in info.  For details about
%   the object metadata, please refer to the HDF5 documentation.
%
%   The valid values for fields are:
%      'H5O_INFO_BASIC'	     Fill in fileno, addr, type, and rc fields
%      'H5O_INFO_TIME'	     Fill in atime, mtime, ctime, and btime fields
%      'H5O_INFO_NUM_ATTRS'  Fill in num_attrs field
%      'H5O_INFO_HDR'	     Fill in hdr field
%      'H5O_INFO_META_SIZE'  Fill in meta_size field
%      'H5O_INFO_ALL'	     Fill in all fields 
%  
%   Example:  
%         % Retrieve the fileno, addr, type and rc fields.
%         % Create file access property list with latest library version
%         faplID = H5P.create('H5P_FILE_ACCESS');
%         H5P.set_libver_bounds(faplID,'H5F_LIBVER_LATEST','H5F_LIBVER_LATEST');
%         dtypeID = H5T.copy('H5T_NATIVE_DOUBLE');      
%         % Create a file
%         dspaceID = H5S.create_simple(2,[4 4],[]);
%         fileID = H5F.create('myexample.h5','H5F_ACC_TRUNC','H5P_DEFAULT',faplID);         
%         % Create a group
%         grpID = H5G.create(fileID,'myGroup','H5P_DEFAULT','H5P_DEFAULT','H5P_DEFAULT');         
%         % Create a dataset and write data to it
%         dsetID = H5D.create(grpID,['dataset'],dtypeID,dspaceID,'H5P_DEFAULT');         
%         info = H5O.get_info2(dsetID, 'H5O_INFO_BASIC');
%         info.num_attrs         
%         H5D.close(dsetID);
%         H5G.close(grpID);
%         H5F.close(fileID);
%         H5S.close(dspaceID);
%         H5T.close(dtypeID);
%         H5P.close(faplID);
%
%   See also H5O, H5O.get_info H5F.open, H5G.open, H5D.open, H5T.open.
   
%   Copyright 2021-2024 The MathWorks, Inc.

validateattributes(obj_id,{'H5ML.id'},{'nonempty','scalar'});
fields = convertStringsToChars(fields);
if isa(fields, 'numeric')
    validateattributes(fields, {'numeric'}, {'nonempty','scalar','finite'});
% check if the flag is a char vector or a string
else
    validateattributes(fields, {'string', 'char'}, {'scalartext'});
end
info = matlab.internal.sci.hdf5lib2('H5Oget_info2',obj_id,fields);            
