function config_struct = get_mdc_config(file_id)
%H5F.get_mdc_config  Return metadata cache configuration.
%   config_struct = H5F.get_mdc_config(file_id) returns the current 
%   metadata cache configuration for the target file.
%
%   Example:
%       fid = H5F.open('example.h5');
%       config = H5F.get_mdc_config(fid);
%       H5F.close(fid);
%
%   See also H5F, H5F.set_mdc_config.

%   Copyright 2009-2024 The MathWorks, Inc.

config_struct = matlab.internal.sci.hdf5lib2('H5Fget_mdc_config', file_id);            
