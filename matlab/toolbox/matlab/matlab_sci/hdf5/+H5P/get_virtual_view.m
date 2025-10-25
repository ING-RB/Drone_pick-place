function view = get_virtual_view(dapl_id)
%H5P.get_virtual_view  Get view of a virtual dataset.
%   view = H5P.get_virtual_view(dapl_id) retrieves the view of the virtual
%   dataset associated with the dataset access property list identifier (dapl_id)
%
%   dapl_id = dataset access property list identifier
%
%   view = Numeric equivalent of the following valid values
%       H5D_VDS_FIRST_MISSING
%       H5D_VDS_LAST_AVAILABLE
%   The numeric equivalents for the flags above can be checked by using the
%   function H5ML.get_constant_value
%
%   See also H5ML.get_constant_value, H5P.set_virtual_view

%   Copyright 2021-2024 The MathWorks, Inc.

validateattributes(dapl_id,{'H5ML.id'},{'nonempty','scalar'});
view = matlab.internal.sci.hdf5lib2('H5Pget_virtual_view',dapl_id);
