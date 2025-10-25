function data = h5postprocessenums(datatype,space,raw_data)
% Enumerated data is numeric, but each value is attached to a tag string,
% the 'Value'.  The output will be a cell array where each numeric value is
% replaced with the tag.

%   Copyright 2010-2022 The MathWorks, Inc.

% find the dataspace type
dspace_type = H5S.get_simple_extent_type(space);

% Use the dataspace type to detect NULL dataspaces instead of the number of
% dimensions. The latter can be '0' despite the dataspace not being NULL
% like in the case of scalar dataspaces.
if dspace_type == H5ML.get_constant_value('H5S_NULL')
    % Null dataspace, just return the empty set.
    data = [];
    return;
end

% find the number of dimensions of the dataspace and their values.
[ndims,h5_dims] = H5S.get_simple_extent_dims(space);
dims = fliplr(h5_dims);

if ndims == 1
    % The dataspace is one-dimensional.  Force the output to be a column.
    data = cell(dims(1),1);
else
    data = cell(dims);
end
nmemb = H5T.get_nmembers(datatype);

for j = 1:nmemb
    Name = H5T.get_member_name(datatype,j-1);
    enum_value = H5T.get_member_value(datatype,j-1);
    idx = find(raw_data == enum_value);
    
    %%% Can this be done more efficiently?
    for k = 1:numel(idx)
        data{idx(k)} = Name;
    end
end
