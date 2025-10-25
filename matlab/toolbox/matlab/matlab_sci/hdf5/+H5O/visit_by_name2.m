function [status,opdata_out] = visit_by_name2(loc_id,obj_name,index_type,order,cbFunc,opdata_in,fields,lapl_id)
%H5O.visit_by_name2  Visit objects accessible from specified object.
%   [status,opdata_out] = H5O.visit_by_name2(loc_id,obj_name,index_type,order,iter_func,opdata_in,fields,lapl_id) 
%   specifies the object by the pairing of the location identifier and  
%   object name. loc_id specifies a file or an object in a file and
%   obj_name specifies an object in the file with either an absolute name
%   or relative to loc_id. A link access property list may affect the
%   outcome if links are involved.
%
%   Two parameters are used to establish the iteration: index_type
%   and order.  index_type specifies the index to be used. If the links
%   in a group have not been indexed by the index type, they will first
%   be sorted by that index then the iteration will begin; if the links
%   have been so indexed, the sorting step will be unnecessary, so the
%   iteration may begin more quickly. Valid values include the following:
%
%      'H5_INDEX_NAME'       Alpha-numeric index on name 
%      'H5_INDEX_CRT_ORDER'  Index on creation order   
%
%   Note that the index type passed in index_type is a best effort
%   setting. If the application passes in a value indicating iteration
%   in creation order and a group is encountered that was not tracked in
%   creation order, that group will be iterated over in alpha-numeric
%   order by name, or name order. (Name order is the native order used
%   by the HDF5 Library and is always available.) order specifies the
%   order in which objects are to be inspected along the index specified
%   in index_type. Valid values include the following:
%
%      'H5_ITER_INC'     Increasing order 
%      'H5_ITER_DEC'     Decreasing order 
%      'H5_ITER_NATIVE'  Fastest available order   
%
%   The callback function iter_func must have the following signature: 
%
%      function [status opdata_out] = iter_func(group_id,name,opdata_in)
%
%   opdata_in is a user-defined value or structure and is passed to the 
%   first step of the iteration in the iter_func opdata_in parameter. The 
%   opdata_out of an iteration step forms the opdata_in for the next 
%   iteration step. The final opdata_out at the end of the iteration is  
%   then returned to the caller as opdata_out.
%
%   fields contains flags to determine which fields will be retrieved
%   by the 'cbFunc' callback function.  Valid values are:
%      'H5O_INFO_BASIC'	     Fill in fileno, addr, type, and rc fields
%      'H5O_INFO_TIME'	     Fill in atime, mtime, ctime, and btime fields
%      'H5O_INFO_NUM_ATTRS'  Fill in num_attrs field
%      'H5O_INFO_HDR'	     Fill in hdr field
%      'H5O_INFO_META_SIZE'  Fill in meta_size field
%      'H5O_INFO_ALL'        Fill in all fields	
%
%   lapl_id is a link access property list. When default link access
%   properties are acceptable, 'H5P_DEFAULT' can be used.
%
%   status value returned by iter_func is interpreted as follows:
%
%      zero     - Continues with the iteration or returns zero status value
%                 to the caller if all members have been processed.   
%      positive - Stops the iteration and returns the positive status value
%                 to the caller.
%      negative - Stops the iteration and throws an error indicating
%                 failure.
%
%   See also H5O, H5O.visit2, H5O.visit, H5O.visit_by_name.
   
%   Copyright 2021-2024 The MathWorks, Inc.

arguments
    loc_id
    obj_name
    index_type
    order
    cbFunc (1,1) function_handle
    opdata_in
    fields
    lapl_id
end

obj_name = convertStringsToChars(obj_name);
index_type = convertStringsToChars(index_type);
order = convertStringsToChars(order);
fields = convertStringsToChars(fields);
lapl_id = convertStringsToChars(lapl_id);

f = functions(cbFunc);
if isempty(f.file)
    error(message('MATLAB:imagesci:H5:badIterateFunction'));
end
if (nargin(cbFunc) ~= 3) || (nargout(cbFunc) ~= 2)
    error(message('MATLAB:imagesci:H5:invalidIterationFunctionSignature'));  
end

if isa(fields, 'numeric')
    validateattributes(fields, {'numeric'}, {'nonempty','scalar','finite'});
% check if the flag is a char vector or a string
else
    validateattributes(fields, {'string', 'char'}, {'scalartext'});
end
[status, opdata_out] = matlab.internal.sci.hdf5lib2('H5Ovisit_by_name2',...
    loc_id,obj_name,index_type,order,cbFunc,opdata_in,fields,lapl_id);
