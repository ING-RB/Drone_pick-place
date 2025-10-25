function set_link_creation_order(gcpl_id,crt_order_flags)
%H5P.set_link_creation_order  Set creation order tracking and indexing.
%   H5P.set_link_creation_order(gcplId,crt_order_flags) sets creation 
%   order tracking and indexing for links in the group with group 
%   creation property list gcpl_id.
%
%   The creation order flags should be chosen from among these constant
%   values:
%       H5P_CRT_ORDER_TRACKED
%       H5P_CRT_ORDER_INDEXED (requires H5P_CRT_ORDER_TRACKED)
%
%   If only H5P_CRT_ORDER_TRACKED is set, HDF5 will track link creation 
%   order in any group created with the group creation property list 
%   gcpl_id. If both H5P_CRT_ORDER_TRACKED and H5P_CRT_ORDER_INDEXED are 
%   set, HDF5 will track link creation order in the group and index 
%   links on that property.  
%
%   Example:
%       tracked = H5ML.get_constant_value('H5P_CRT_ORDER_TRACKED');
%       indexed = H5ML.get_constant_value('H5P_CRT_ORDER_INDEXED');
%       order = bitor(tracked,indexed);
%       gcpl = H5P.create('H5P_GROUP_CREATE');
%       H5P.set_link_creation_order(gcpl,order);
% 
%   See also H5P, H5P.get_link_creation_order, H5ML.get_constant_value.

%   Copyright 2009-2024 The MathWorks, Inc.

crt_order_flags = convertStringsToChars(crt_order_flags);
if ~isnumeric(crt_order_flags)
    crt_order_flags = strrep(crt_order_flags,' ',''); % Replace space with null.
    if strcmp(crt_order_flags,'H5P_CRT_ORDER_TRACKED|H5P_CRT_ORDER_INDEXED')
      tracked = H5ML.get_constant_value('H5P_CRT_ORDER_TRACKED');
      indexed = H5ML.get_constant_value('H5P_CRT_ORDER_INDEXED');
      crt_order_flags = bitor(tracked,indexed);
    else
      crt_order_flags = H5ML.get_constant_value(crt_order_flags);
    end
end

matlab.internal.sci.hdf5lib2('H5Pset_link_creation_order',...
    gcpl_id, crt_order_flags);            

