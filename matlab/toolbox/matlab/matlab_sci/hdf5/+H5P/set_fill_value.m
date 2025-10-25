function set_fill_value(plist_id, type_id, value)
%H5P.set_fill_value  Set fill value for dataset creation property list.
%   H5P.set_fill_value(plist_id, type_id, value) sets the fill value for
%   the dataset creation property list specified by plist_id. The value
%   argument specifies the fill value. The type_id argument specifies the
%   datatype of the fill value. Setting value to an empty array indicates
%   that the fill value is undefined.
%
%   Example:  create a double precision dataset with a fill value of -999.
%       fid = H5F.create('myfile.h5');
%       type_id = H5T.copy('H5T_NATIVE_DOUBLE');
%       dims = [100 50];
%       h5_dims = fliplr(dims);
%       h5_maxdims = h5_dims;
%       space_id = H5S.create_simple(2,h5_dims,h5_maxdims);
%       dcpl = H5P.create('H5P_DATASET_CREATE');
%       fill_time = H5ML.get_constant_value('H5D_FILL_TIME_ALLOC');
%       H5P.set_fill_time(dcpl,fill_time);
%       H5P.set_fill_value(dcpl,type_id,-999);
%       dset_id = H5D.create(fid,'DS',type_id,space_id,dcpl);
%       H5D.close(dset_id);
%       H5F.close(fid);
%
%   See also H5P.

%   Copyright 2006-2024 The MathWorks, Inc.

type_id = convertStringsToChars(type_id);

% The fill-value represents one element have the format of the dataset. So,
% the values supported by the fill-value can have arbitrary type. So, this
% check has to be done.

% If fixed or variable length string values are being written, then they
% must be a cellstr or a string array
if isstring(value) || iscellstr(value)
    value = cellstr(value);
elseif iscell(value)
    matlab.io.internal.imagesci.validateTextInCell(value, 'hdf5lib');

    % Navigate the cell array to convert all strings into character vectors
    value = matlab.io.internal.imagesci.convertStringsInCell(value);
elseif isstruct(value)
    % Navigate all the fields of the struct array to convert strings into
    % character vectord
    value = matlab.io.internal.imagesci.convertStringsInStruct(value);
else
    value = convertStringsToChars(value);
end


matlab.internal.sci.hdf5lib2('H5Pset_fill_value', plist_id, type_id, value);            
