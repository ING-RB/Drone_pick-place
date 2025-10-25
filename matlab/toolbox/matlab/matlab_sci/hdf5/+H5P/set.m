function set(plist_id, name, value)
%H5P.set  Set property list value.
%   H5P.set(plist_id, name, value) sets the value of the property specified
%   by the text string name in the property list specified by plist_id to
%   the value specified in value. The value datatype must be uint8. 
%
%   Example:
%       plist = H5P.create('H5P_FILE_ACCESS');
%       H5P.set(plist, 'rdcc_w0', typecast(0.8, 'uint8'));
%   
%   It is recommended to use alternative functions like H5P.set_chunk, 
%   H5P.set_layout, H5P.set_size etc., where available, to set values for the 
%   common property names.
% 
%   See also H5P, TYPECAST.

%   Copyright 2006-2024 The MathWorks, Inc.

if nargin > 1
    name = convertStringsToChars(name);
end

matlab.internal.sci.hdf5lib2('H5Pset',...
    plist_id, name, value);
