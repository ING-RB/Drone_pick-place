function fsp_size = get_file_space_page_size(fcpl_id)
%H5P.get_file_space_page_size  Get file space page size.
%   fsp_size = H5P.get_file_space_page_size(fcpl_id) retrieves the file
%   space page size for file creation property list identifier fcpl_id.
%   fsp_size is the file space page size for paged aggregation.  The
%   library default is 4KB (4096) if fsp_size is not previously
%   set via a call to H5P.set_file_space_page_size.
%   Example:
%       fcplID = H5P.create('H5P_FILE_CREATE');
%       fsp_size = H5P.get_file_space_page_size(fcplID)
%       H5P.set_file_space_page_size(fcplID,512);
%       fsp_size = H5P.get_file_space_page_size(fcplID)
%       H5P.close(fcplID);
%
%   See also H5P, H5P.set_file_space_page_size.

%   Copyright 2024 The MathWorks, Inc.

validateattributes(fcpl_id,{'H5ML.id'},{'nonempty','scalar'});
fsp_size = matlab.internal.sci.hdf5lib2('H5Pget_file_space_page_size',fcpl_id);
