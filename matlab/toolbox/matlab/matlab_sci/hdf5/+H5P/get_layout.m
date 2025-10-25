function layout = get_layout(dcpl_id)
%H5P.get_layout  Determine layout of raw data for dataset.
%   layout = H5P.get_layout(dcpl_id) returns the layout of the raw
%   data for the dataset specified by the dataset creation property
%   list dcpl_id.
%   Possible values for layout of raw data: 
%       'H5D_COMPACT'    stored in object header
%       'H5D_CONTIGUOUS' stored in one contiguous chunk
%       'H5D_CHUNKED'    stored in chunks in separate locations
%       'H5D_VIRTUAL'    drawn from multiple datasets in different files
%
%   Example:
%       fid = H5F.open('example.h5');
%       dset_id = H5D.open(fid,'/g3/integer');
%       dcpl_id = H5D.get_create_plist(dset_id);
%       layout = H5P.get_layout(dcpl_id);
%       switch(layout)
%           case H5ML.get_constant_value('H5D_COMPACT')
%               fprintf('layout is compact\n');
%           case H5ML.get_constant_value('H5D_CONTIGUOUS')
%               fprintf('layout is contiguous\n');
%           case H5ML.get_constant_value('H5D_CHUNKED')
%               fprintf('layout is chunked\n');
%           case H5ML.get_constant_value('H5D_VIRTUAL')
%               fprintf('layout is chunked\n');
%       end
%
%   See also H5P, H5P.set_layout.

%   Copyright 2006-2024 The MathWorks, Inc.

validateattributes(dcpl_id,{'H5ML.id'},{'nonempty','scalar'});
layout = matlab.internal.sci.hdf5lib2('H5Pget_layout', dcpl_id);            
