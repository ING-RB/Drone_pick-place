function set_page_buffer_size(fapl_id, buf_size, min_meta_perc, min_raw_perc)
%H5P.set_page_buffer_size Sets the information about the page buffer size.
%   H5P.set_page_buffer_size(fapl_id, buf_size, min_meta_perc,
%   min_raw_perc) sets buf_size, the maximum size in bytes of the page
%   buffer. The default value is zero, meaning that page buffering is
%   disabled. 
%
%   When a non-zero page buffer size is set, the library will
%   enable page buffering  only if the following conditions are true:
%   1. The file space strategy for the file is set to paged
%   (H5F_FSPACE_STRATEGY_PAGE) using H5Pset_file_space_strategy at the time
%   of file creation.
%   2. The page buffer size to be set is greater than or equal to the single page
%   size set by H5Pset_file_space_page_size
%
%   If either of the two conditions above are not true, the subsequent call
%   to H5F.create or H5F.open using the fapl_id will fail.
%   The function also allows setting the minimum percentage of pages for
%   metadata and raw data to prevent a certain type of data from evicting
%   data of the other type.
%
%   fapl_id is the file access property list identifier
%
%   buf_size is the maximum size, in bytes, of the page buffer
%
%   min_meta_perc is the minimum metadata percentage to keep in the page buffer
%   before allowing pages containing metadata to be evicted (Default is 0)
%
%   min_raw_perc is the minimum raw data percentage to keep in the page buffer
%   before allowing pages containing raw data to be evicted (Default is 0)
%
%   Example:
%       % Create file access property list
%       faplID = H5P.create('H5P_FILE_ACCESS');
%       % Query the default page buffer size
%       [actSize,actMetaPerc,actRawPerc] = H5P.get_page_buffer_size(faplID);
%       % Set page buffer size with custom values
%       H5P.set_page_buffer_size(faplID,512,50,50);
%       % Query again after setting our custom values
%       [actSize,actMetaPerc,actRawPerc] = H5P.get_page_buffer_size(faplID);
%       H5P.close(faplID);
%
%   See also H5P.set_file_space_strategy, H5P.set_file_space_page_size,
%   H5P.get_page_buffer_size.

%   Copyright 2024 The MathWorks, Inc.

validateattributes(fapl_id,{'H5ML.id'},{'nonempty','scalar'});
validateattributes(buf_size,{'double'},{'scalar','nonnegative','finite','nonnan'});
validateattributes(min_meta_perc,{'double'},{'scalar','nonnegative','finite','nonnan'});
validateattributes(min_raw_perc,{'double'},{'scalar','nonnegative','finite','nonnan'});

matlab.internal.sci.hdf5lib2('H5Pset_page_buffer_size',fapl_id,buf_size,min_meta_perc,min_raw_perc);
