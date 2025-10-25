function set_attr_creation_order(ocpl_id,crt_order_flags)
%H5P.set_attr_creation_order  Set tracking of attribute creation order.
%   H5P.set_attr_creation_order(gcplId,crt_order_flags) sets tracking and
%   indexing of attribute creation order.  The creation order flags should
%   be either H5P_CRT_ORDER_TRACKED or a bitwise-or of 
%   H5P_CRT_ORDER_TRACKED and H5P_CRT_ORDER_INDEXED.
%
%   The default behavior is that attribute creation order is neither
%   tracked nor indexed.
%
%   Example:
%       dcpl = H5P.create('H5P_DATASET_CREATE');
%       order = H5ML.get_constant_value('H5P_CRT_ORDER_TRACKED');
%       H5P.set_attr_creation_order(dcpl,order);
%
%   See also H5P, H5P.get_attr_creation_order, H5ML.get_constant_value,
%   bitor.

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

matlab.internal.sci.hdf5lib2('H5Pset_attr_creation_order',...
    ocpl_id, crt_order_flags);            
