function start_swmr_write(file_id)
%H5F.start_swmr_write(file_id)  Enable SWMR writing mode on a file.
%   H5F.start_swmr_write(file_id) activates the SWMR writing mode for
%   the file associated with the identifier file_id.
%
%   Example:
%       fapl_id = H5P.create('H5P_FILE_ACCESS');
%       H5P.set_libver_bounds(fapl_id,'H5F_LIBVER_LATEST','H5F_LIBVER_LATEST'); 
%       file_id = H5F.create('my_example.h5','H5F_ACC_TRUNC','H5P_DEFAULT',fapl_id); 
%       % Enable SWMR write process
%       H5F.start_swmr_write(file_id);
%       %% Perform SWMR write operations
%       % Close the file identifier
%       H5F.close(file_id)
%
%   See also H5F.open, H5F.create, H5F.close.

%   Copyright 2021-2024 The MathWorks, Inc.

validateattributes(file_id,{'H5ML.id'},{'nonempty','scalar'});

% Checking if the library version is >= 1.10
% If not, throw an error
fapl_id = H5F.get_access_plist(file_id);
[low, high]= H5P.get_libver_bounds(fapl_id);
if ((low<2) || (high<2))
    ME = MException('MATLAB:imagesci:hdf5lib:SWMRincorrectlibverbounds', ...
        getString(message('MATLAB:imagesci:hdf5lib:SWMRincorrectlibverbounds')));
    throw(ME)
end

matlab.internal.sci.hdf5lib2('H5Fstart_swmr_write',file_id);
