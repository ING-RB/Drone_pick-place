function output = dereference(varargin)
%H5R.dereference  Open object specified by reference.
%   output = H5R.dereference(dataset,ref_type,ref) returns an identifier
%   to the object specified by ref in the dataset specified by dataset.
%   This syntax corresponds to the H5Rdereference interface in version 
%   1.8 of the HDF5 C library.
%
%   output = H5R.dereference(dataset,plist,ref_type,ref) returns an identifier
%   to the object specified by ref in the dataset specified by dataset.
%   plist is a valid object access property list identifier for a
%   property list to be used with the referenced object.  This syntax
%   corresponds to the H5Rdereference interface in version 1.10 of the
%   HDF5 C library.
%
%   Example:  
%       plist = 'H5P_DEFAULT';
%       space = 'H5S_ALL';
%       fid = H5F.open('example.h5');
%       dset_id = H5D.open(fid,'/g3/reference');
%       ref_data = H5D.read(dset_id,'H5T_STD_REF_OBJ',space,space,plist);
%       deref_dset_id = H5R.dereference(dset_id,'H5R_OBJECT',ref_data(:,1));
%       H5D.close(dset_id);
%       H5D.close(deref_dset_id);
%       H5F.close(fid);
%
%   Example:  
%       plist = 'H5P_DEFAULT';
%       space = 'H5S_ALL';
%       fid = H5F.open('example.h5');
%       dset_id = H5D.open(fid,'/g3/reference');
%       ref_data = H5D.read(dset_id,'H5T_STD_REF_OBJ',space,space,plist);
%       deref_dset_id = H5R.dereference(dset_id,plist,'H5R_OBJECT',ref_data(:,1));
%       H5D.close(dset_id);
%       H5D.close(deref_dset_id);
%       H5F.close(fid);
%
%   See also H5R, H5R.create, H5I.get_name.

%   Copyright 2006-2024 The MathWorks, Inc.

if nargin == 3
    if isa(varargin{2},'numeric')
        validateattributes(varargin{2},{'numeric'},{'scalar','finite'});
    % check if the varargin{2} is a char vector or a string
    else
        validateattributes(varargin{2},{'string','char'},{'scalartext'});
        varargin{2} = convertStringsToChars(varargin{2});
    end
    
elseif nargin == 4
    if isa(varargin{3},'numeric')
        validateattributes(varargin{3},{'numeric'},{'scalar','finite'});
    % check if the varargin{3} is a char vector or a string
    else
        validateattributes(varargin{3},{'string','char'},{'scalartext'});
        varargin{3} = convertStringsToChars(varargin{3});
    end
end

output = matlab.internal.sci.hdf5lib2('H5Rdereference',varargin{:});
output = H5ML.id(output,'H5Oclose');
end
