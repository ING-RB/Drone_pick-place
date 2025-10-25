function refresh(dataset_id)
%H5D.refresh  Refresh the buffers associated with a dataset.
%   H5D.refresh(dataset_id) causes all the buffers for the dataset
%   associated with dataset_id to be cleared and immediately reloaded
%   with updated contents from disk.  This function essentially closes 
%   the dataset, evicts all metadata associated with it from the cache, 
%   and then reopens the dataset. The reopened dataset is automatically 
%   reregistered with the same identifier.
%
%   See also H5D, H5D.flush.

%   Copyright 2021-2024 The MathWorks, Inc.

validateattributes(dataset_id,{'H5ML.id'},{'nonempty','scalar'});
matlab.internal.sci.hdf5lib2('H5Drefresh',dataset_id);
