function config_struct = get_mdc_config(plist_id)
%H5P.get_mdc_config  Get metadata cache configuration.
%   config_struct = H5P.get_mdc_config(plist_id) returns the current 
%   metadata cache configuration from the indicated file access property 
%   list.
%
%   Example:
%       fid = H5F.open('example.h5');
%       fapl = H5F.get_access_plist(fid);
%       config = H5P.get_mdc_config(fapl);
%       H5P.close(fapl);
%       H5F.close(fid);
%
%   See also H5P, H5P.set_mdc_config.
%

%   Copyright 2009-2024 The MathWorks, Inc.

config_struct = matlab.internal.sci.hdf5lib2('H5Pget_mdc_config', plist_id);            
