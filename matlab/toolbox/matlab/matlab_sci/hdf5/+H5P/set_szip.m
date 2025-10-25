function set_szip(plistId, optionsMask, pixelsPerBlock)
%H5P.set_szip  Set SZIP compression in dataset creation.
%   H5P.set_szip(plistId,optionsMask,pixelsPerBlock) sets SZIP
%   compression, H5Z_FILTER_SZIP, for the dataset creation property
%   list identifier plistId. optionsMask is a bitmask conveying the
%   the desired SZIP options - valid values are 'H5_SZIP_EC_OPTION_MASK'
%   for entropy encoding, and 'H5_SZIP_NN_OPTION_MASK' for nearest
%   neighbor encoding. pixelsPerBlock is the number of pixels (HDF5
%   data elements) in each data block and must be even, greater
%   than zero, and less than or equal to 32; typical values are 8, 10,
%   16, or 32. pixelsPerBlock affects compression ratio - the more
%   pixel values vary, the smaller this number should be to achieve
%   better performance.
%
%   Example:  Create a two dimensional double precision dataset of size 
%   [100 200] with chunk size of [10 20], and specify SZIP compression 
%   using entropy encoding and 12 pixels per block. 
%       fid = H5F.create('myfile.h5');
%       typeId = H5T.copy('H5T_NATIVE_DOUBLE');
%       dims = [100 200];
%       h5dims = fliplr(dims);
%       spaceId = H5S.create_simple(2,dims,[]);
%       dcpl = H5P.create('H5P_DATASET_CREATE');
%       chunkDims = [10 20];
%       h5ChunkDims = fliplr(chunkDims);
%       H5P.set_chunk(dcpl,h5ChunkDims);
%       pixelsPerBlock = 12; 
%       H5P.set_szip(dcpl,H5ML.get_constant_value('H5_SZIP_EC_OPTION_MASK'),pixelsPerBlock);
%       dsetId = H5D.create(fid,'myDataset',typeId,spaceId,dcpl);
%       H5D.close(dsetId);
%       H5S.close(spaceId);
%       H5T.close(typeId);
%       H5F.close(fid);
%
%   See also H5P.set_deflate, H5ML.get_constant_value.

%   Copyright 2024 The MathWorks, Inc.

validateattributes(plistId,{'H5ML.id'},{'nonempty'});

if ~isnumeric(optionsMask)
    % Convert the optionsMask to the HDF5 constant value
    optionsMask = H5ML.get_constant_value(optionsMask);
end

% Issue error if optionsMask is not one of the two valid values 
validOptionsMask = [H5ML.get_constant_value('H5_SZIP_EC_OPTION_MASK') ...
    H5ML.get_constant_value('H5_SZIP_NN_OPTION_MASK')];
if ~isscalar(optionsMask) || ~ismember(optionsMask,validOptionsMask)
    error(message('MATLAB:imagesci:hdf5lib:invalidSZIPOptionsMask'));
end

validateattributes(pixelsPerBlock,{'numeric'},...
    {'nonempty','scalar','integer','positive','even','<=',32});

matlab.internal.sci.hdf5lib2('H5Pset_szip',...
    plistId,optionsMask,pixelsPerBlock);
