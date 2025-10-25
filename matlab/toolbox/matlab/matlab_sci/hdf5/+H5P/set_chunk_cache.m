function set_chunk_cache(dapl_id, rdcc_nslots, rdcc_nbytes, rdcc_w0)
%H5P.set_chunk_cache  Set raw data chunk cache parameters.  
%   H5P.set_chunk_cache(dapl_id, rdcc_nslots, rdcc_nbytes, rdcc_w0) sets
%   the number of elements (rdcc_nslots), the total number of bytes
%   (rdcc_nbytes), and the preemption policy value (rdcc_w0) in the raw
%   data chunk cache. 
%   For rdcc_nslots, if the value passed is H5D_CHUNK_CACHE_NSLOTS_DEFAULT,
%   then the property will not be set on dapl_id and the parameter will
%   come from the file access property list used to open the file.
%   For rdcc_nbytes, if the value passed is H5D_CHUNK_CACHE_NBYTES_DEFAULT,
%   then the property will not be set on dapl_id and the parameter will
%   come from the file access property list.
%   For rdcc_w0, if the value passed is H5D_CHUNK_CACHE_W0_DEFAULT, then
%   the property will not be set on dapl_id and the parameter will come
%   from the file access property list.
%
%   Example:
%       fid = H5F.open('example.h5');
%       dset_id = H5D.open(fid,'/g3/vlen3D');
%       dapl = H5D.get_access_plist(dset_id);
%       H5P.set_chunk_cache(dapl,500,1e6,0.7);
%       H5P.close(dapl);
%       H5D.close(dset_id);
%       H5F.close(fid);
%
%   See also H5P, H5P.get_chunk_cache.

%   Copyright 2009-2024 The MathWorks, Inc.

validateattributes(dapl_id,{'H5ML.id'},{'nonempty','scalar'});
rdcc_nslots = validateRdccValue(rdcc_nslots, 'rdcc_nslots');
rdcc_nbytes = validateRdccValue(rdcc_nbytes, 'rdcc_nbytes');
rdcc_w0 = validateRdccValue(rdcc_w0, 'rdcc_w0');

matlab.internal.sci.hdf5lib2('H5Pset_chunk_cache', dapl_id, rdcc_nslots, rdcc_nbytes, rdcc_w0 );

% Function to validate rdcc_nslots and rdcc_bytes and convert to numeric
% equivalent if a valid constant string or char array is passed.
function out = validateRdccValue(value, varName)
    value = convertStringsToChars(value);
    if isnumeric(value)
        validateattributes(value,{'numeric'},{'scalar','finite','nonnan'}, '', varName);
        out = value;
    elseif (ischar(value) || isstring(value))
        validateattributes(value, {'char'}, {'nonempty'}, '', varName);
        out = H5ML.get_constant_value(value);
    else
        error(message('MATLAB:imagesci:hdf5lib:badEnumInputType'));
    end
end

end
