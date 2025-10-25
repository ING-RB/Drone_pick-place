function src_dset_name = get_virtual_dsetname(dcpl_id,mapping_index)
%H5P.get_virtual_dsetname  Get name of source dataset in the mapping.
%   src_dset_name = get_virtual_dsetname(dcpl_id,mapping_index) returns
%   the name of the source dataset used in the mapping for the virtual
%   dataset.  dcpl_id is the identifier for the virtual dataset creation
%   property list.  mapping_index is the index of the number of mappings
%   for the virtual dataset (zero or greater, and less than number of
%   mappings returned by H5P.get_virtual_count).  src_dset_name is the
%   name of the source dataset.
%
%   Example:
%       % Create the file access property list with latest library versions
%       faplID = H5P.create('H5P_FILE_ACCESS');
%       H5P.set_libver_bounds(faplID,'H5F_LIBVER_LATEST','H5F_LIBVER_LATEST');    
%       datatypeID = H5T.copy('H5T_NATIVE_DOUBLE');
%       % For dataset A
%       dataspaceID1 = H5S.create_simple(2,[4 4],[]);
%       fileID1 = H5F.create('A.h5','H5F_ACC_TRUNC','H5P_DEFAULT',faplID);
%       datasetID1 = H5D.create(fileID1,'A',datatypeID,dataspaceID1,'H5P_DEFAULT');
%       H5D.write(datasetID1,'H5ML_DEFAULT','H5S_ALL','H5S_ALL','H5P_DEFAULT',randn(4,4));
%       H5S.close(dataspaceID1);
%       H5D.close(datasetID1);
%       H5F.close(fileID1);
%       % Create a file for the virtual dataset and related identifiers
%       fileVDS = H5F.create('VDS.h5','H5F_ACC_TRUNC','H5P_DEFAULT',faplID);
%       vspaceID = H5S.create_simple(2,[15 6],[]);
%       vdcplID = H5P.create('H5P_DATASET_CREATE');
%       H5P.set_layout(vdcplID,'H5D_VIRTUAL');
%       H5P.set_fill_value(vdcplID,datatypeID,-10);
%       % Build the mappings
%       srcSpaceID = H5S.create_simple(2,[4 4],[]);
%       H5S.select_hyperslab(vspaceID,'H5S_SELECT_SET',[0 0],[],[],[4 4]);
%       H5P.set_virtual(vdcplID,vspaceID,'A.h5','A',srcSpaceID);
%       % Create the virtual dataset and close the file and space IDs
%       vdatasetID = H5D.create(fileVDS,'vdsData',datatypeID,vspaceID,'H5P_DEFAULT',vdcplID,'H5P_DEFAULT');
%       H5S.close(vspaceID);
%       H5S.close(srcSpaceID);
%       H5D.close(vdatasetID);
%       H5F.close(fileVDS);
%       % Open the file and virtual dataset
%       vdsFileID = H5F.open('VDS.h5','H5F_ACC_RDONLY','H5P_DEFAULT');
%       vdsDatasetID = H5D.open(vdsFileID,'vdsData','H5P_DEFAULT');
%       % Get creation property list and mapping properties
%       vdcplID = H5D.get_create_plist(vdsDatasetID);
%       % Get storage layout
%       vlayout = H5P.get_layout(vdcplID);
%       % Get virtual mapping count
%       map_count = H5P.get_virtual_count(vdcplID);
%       % Get source dataset names
%       src_dset_name = H5P.get_virtual_dsetname(vdcplID,0);
%       % Read the data
%       H5D.read(vdsDatasetID,'H5ML_DEFAULT','H5S_ALL','H5S_ALL','H5P_DEFAULT')
%       H5D.close(vdsDatasetID);
%       H5F.close(vdsFileID);
%
%   See also H5P.get_virtual_count, H5P.set_virtual, H5P.get_virtual_srcspace.

%   Copyright 2021-2024 The MathWorks, Inc.

validateattributes(dcpl_id,{'H5ML.id'},{'nonempty','scalar'});
validateattributes(mapping_index, {'double'}, ...
    {'integer','nonempty','nonnegative'});
src_dset_name = matlab.internal.sci.hdf5lib2('H5Pget_virtual_dsetname',...
    dcpl_id,mapping_index);
