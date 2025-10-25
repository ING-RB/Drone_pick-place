function set_virtual_view(dapl_id, view)
%H5P.set_virtual_view sets the view of the virtual dataset to include or
%exclude missing mapped elements
%   H5P.set_virtual_view(dapl_id, view) sets the VDS view of the virtual
%   dataset with acess property list identifier (dapl_id) to the value set
%   by 'view'
%
%   dapl_id = Identifier of the virtual dataset access property list
%
%   view = Flag specifying the extent of the data to be included in the
%   view. Valid values are
%       H5D_VDS_FIRST_MISSING = View includes all the data before the first
%       missing mapped data.
%       H5D_VDS_LAST_AVAILABLE = View includes all available mapped data
%
%   See also H5ML.get_constant_value, H5P.get_virtual_view

%   Copyright 2021-2024 The MathWorks, Inc.

validateattributes(dapl_id, {'H5ML.id'}, {'nonempty'});
if ~isnumeric(view)
    validateattributes(view, {'char', 'string'}, {'nonempty', 'scalartext'});
    view = convertStringsToChars(view);
else
    validateattributes(view, {'double'}, ...
        {'nonempty','scalar', 'finite','integer'});
end

matlab.internal.sci.hdf5lib2('H5Pset_virtual_view', dapl_id, view);
