function [buf_size,min_meta_perc,min_raw_perc] = get_page_buffer_size(fapl_id)
%H5P.get_page_buffer_size  Get information about the page buffer size.
%   [buf_size,min_meta_perc,min_raw_perc] = H5P.get_page_buffer_size(fapl_id) 
%   retrieves the maximum size for the page buffer and the minimum percentage
%   for metadata and raw data pages for file access property list identifier
%   fapl_id.  buf_size is the maximum size in bytes of the page buffer.
%   min_meta_perc is the minimum metadata percentage to keep in the page
%   buffer before allowing pages containing metadata to be evicted.
%   min_raw_perc is the minimum raw data percentage to keep in the page buffer
%   before allowing pages containing raw data to be evicted.
%
%   Example:
%       % Create file access property list
%       faplID = H5P.create('H5P_FILE_ACCESS');
%       % Query the default page buffer size
%       [actSize,actMetaPerc,actRawPerc] = H5P.get_page_buffer_size(faplID);
%       % Set page buffer size with custom values
%       H5P.set_page_buffer_size(faplID,512,50,50);
%       [actSize,actMetaPerc,actRawPerc] = H5P.get_page_buffer_size(faplID);
%       H5P.close(faplID);
%
%   See also H5P.set_file_space_strategy, H5P.set_file_space_page_size,
%   H5P.set_page_buffer_size

%   Copyright 2024 The MathWorks, Inc.

validateattributes(fapl_id,{'H5ML.id'},{'nonempty','scalar'});
[buf_size,min_meta_perc,min_raw_perc] = matlab.internal.sci.hdf5lib2('H5Pget_page_buffer_size',fapl_id);
