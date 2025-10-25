function set_virtual(dcpl_id, vspace_id, src_file_name, src_dset_name, src_space_id)
%H5P.set_virtual sets the mapping between source and virtual datasets
%   H5P.set_virtual(dcpl_id, vspace_id, src_file_name, src_dset_name,
%   src_space_id) maps the elements of the virtual dataset, described by
%   the virtual dataspace identifier (vspace_id) to the elements of the
%   source dataset described by the source dataspace identifier
%   (src_space_id). The source dataset is identified by the
%   name of the source dataset (src_dset_name) and the name of the source
%   file (src_file_name)
%
%   dcpl_id = Dataset creation property list identifier that will be used
%   when creating the virtual dataset
%
%   vspace_id = Dataspace identifier with the selection within the virtual
%   dataset applied 
%
%   src_file_name = Name of the source file
%
%   src_dset_name = Name of the source dataset
%
%   src_space_id = Source dataset's dataspace identifier with a selection applied
%
%   Example:
%         % Create the file access property list with latest library versions
%         faplID = H5P.create('H5P_FILE_ACCESS');
%         H5P.set_libver_bounds(faplID,'H5F_LIBVER_LATEST','H5F_LIBVER_LATEST');          
%         datatypeID = H5T.copy('H5T_NATIVE_DOUBLE');
%         % Define source dataset A
%         dataspaceID = H5S.create_simple(2,[4 4],[]);
%         fileID = H5F.create('A.h5','H5F_ACC_TRUNC','H5P_DEFAULT',faplID);
%         datasetID = H5D.create(fileID,'A',datatypeID,dataspaceID,'H5P_DEFAULT');
%         H5D.write(datasetID,'H5ML_DEFAULT','H5S_ALL','H5S_ALL','H5P_DEFAULT',randn(4,4));
%         H5S.close(dataspaceID);
%         H5D.close(datasetID);
%         H5F.close(fileID);
%         % Create a file for the virtual dataset and related identifiers
%         fileVDS = H5F.create('VDS.h5','H5F_ACC_TRUNC','H5P_DEFAULT',faplID);
%         vspaceID = H5S.create_simple(2,[15 6],[]);
%         vdcplID = H5P.create('H5P_DATASET_CREATE');
%         H5P.set_layout(vdcplID,'H5D_VIRTUAL');
%         H5P.set_fill_value(vdcplID,datatypeID,-10);
%         % Build the mappings
%         srcSpaceID = H5S.create_simple(2,[4 4],[]);
%         H5S.select_hyperslab(vspaceID,'H5S_SELECT_SET',[0 0],[],[],[4 4]);
%         H5P.set_virtual(vdcplID,vspaceID,'A.h5','A',srcSpaceID);
%         % Create the virtual dataset and close the file and space IDs
%         vdatasetID = H5D.create(fileVDS,'vdsData',datatypeID,vspaceID,'H5P_DEFAULT',vdcplID,'H5P_DEFAULT');
%         H5S.close(vspaceID);
%         H5S.close(srcSpaceID);
%         H5D.close(vdatasetID);
%         H5F.close(fileVDS);
%         % Open the file and virtual dataset
%         vdsFileID = H5F.open('VDS.h5','H5F_ACC_RDONLY','H5P_DEFAULT');
%         vdsDatasetID = H5D.open(vdsFileID,'vdsData','H5P_DEFAULT');
%         % Get creation property list and mapping properties
%         vdcplID = H5D.get_create_plist(vdsDatasetID);
%         % Get storage layout
%         vlayout = H5P.get_layout(vdcplID);
%         % Get virtual mapping count
%         vcount = H5P.get_virtual_count(vdcplID);
%         % Get source file names
%         src_filename = H5P.get_virtual_filename(vdcplID,0);
%         % Get source dataset names
%         src_dset_name = H5P.get_virtual_dsetname(vdcplID,0);
%         % Read the data
%         data = H5D.read(vdsDatasetID,'H5ML_DEFAULT','H5S_ALL','H5S_ALL','H5P_DEFAULT');
%         H5D.close(vdsDatasetID);
%         H5F.close(vdsFileID);
%
%   See also H5P.get_virtual_count, H5P.get_virtual_srcspace

%   Copyright 2021-2024 The MathWorks, Inc.

% The path to the full source file will not be resolved here for the
% following reasons:
% 1. The source file need not exist at the time of creating the VDS.
% 2. The location of the source file can be specified by using an
% environment variable. This location is added as a prefix to the filename.

validateattributes(dcpl_id, {'H5ML.id'}, {'nonempty'});
validateattributes(vspace_id, {'H5ML.id'}, {'nonempty'});
validateattributes(src_space_id, {'H5ML.id'}, {'nonempty'});

validateattributes(src_file_name, {'char', 'string'}, {'nonempty', 'scalartext'});
src_file_name = convertStringsToChars(src_file_name);

validateattributes(src_dset_name, {'char', 'string'}, {'nonempty', 'scalartext'});
src_dset_name = convertStringsToChars(src_dset_name);

matlab.internal.sci.hdf5lib2('H5Pset_virtual',...
    dcpl_id, vspace_id, src_file_name, src_dset_name, src_space_id);
