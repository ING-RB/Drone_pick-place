function set_file_space_page_size(fcpl_id,fsp_size)
%H5P.set_file_space_page_size  Set file space page size for a file.
%   H5P.set_file_space_page_size(fcpl_id,fsp_size) sets the file space
%   page size for file associated with file creation property list
%   identifier fcpl_id.  fsp_size is the file space page size used
%   in page aggregation and page buffering.  fsp_size has a minimum size
%   of 512.  Setting a value less than 512 will throw an error.  The
%   library default size for the file space page size is 4096.
%
%   Example:
%         fcplID = H5P.create('H5P_FILE_CREATE');        
%         page_size = H5P.get_file_space_page_size(fcplID)
%         H5P.set_file_space_page_size(fcplID,512);
%         page_size = H5P.get_file_space_page_size(fcplID)
%         H5P.close(fcplID);
%
%   See also H5P, H5P.get_file_space_page_size.

%   Copyright 2024 The MathWorks, Inc.

validateattributes(fcpl_id,{'H5ML.id'},{'nonempty','scalar'});
validateattributes(fsp_size,{'double'},{'scalar','finite','>=',512});
matlab.internal.sci.hdf5lib2('H5Pset_file_space_page_size',fcpl_id,fsp_size);
