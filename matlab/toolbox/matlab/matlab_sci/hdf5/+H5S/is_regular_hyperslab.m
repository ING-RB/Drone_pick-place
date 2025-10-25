function value = is_regular_hyperslab(space_id)
%H5S.is_regular_hyperslab determines whether a hyperslab
%selection is regular
%   value = H5S.is_regular_hyperslab(space_id) queries the type of hyperslab
%   selection from the dataspace identifier (space_id). A regular hyperslab
%   selection is a hyperslab selection described by setting the offset, stride,
%   count, and block parameters for a single H5S.select_hyperslab call. If
%   several calls to H5S.select_hyperslab are needed, then the hyperslab
%   selection is irregular. 
%
%   value returns a positive value if the hyperslab selection is regular,
%   zero if it is not.
%
%   Example: 
%         % Select a regular hyperslab and retrieve the selection
%         % Create a simple dataspace
%         space_id = H5S.create_simple(2,[10 10],[]);
%         % Select a hyperslab
%         H5S.select_hyperslab(space_id,'H5S_SELECT_SET',[0 0],[2 2],[4 4],[2 2]); 
%         % Retrieve the hyperslab parameters
%         val = H5S.is_regular_hyperslab(space_id);
%         [start,stride,count,block] = H5S.get_regular_hyperslab(space_id)
%   
%   See also H5S.select_hyperslab, H5S.get_regular_hyperslab

%   Copyright 2021-2024 The MathWorks, Inc.

validateattributes(space_id,{'H5ML.id'},{'nonempty'});
value = matlab.internal.sci.hdf5lib2('H5Sis_regular_hyperslab',space_id);
