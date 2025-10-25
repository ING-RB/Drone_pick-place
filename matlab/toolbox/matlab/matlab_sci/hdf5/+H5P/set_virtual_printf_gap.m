function set_virtual_printf_gap(dapl_id, gap_size)
%H5P.set_virtual_printf_gap  Set number of missing source files/datasets.
%   H5P.set_virtual_printf_gap(dapl_id, gap_size) sets the access property
%   list for the virtual dataset (dapl_id) to instruct the library to stop
%   looking for the mapped data stored in the files and/or datasets with
%   the printf-style names after not finding (gap_size) files and/or
%   datasets. The found source files and datasets will determine the extent
%   of the unlimited virtual dataset with the printf-style mappings.
%
%   dapl_id = Dataset access property list identifier of the virtual
%   dataset
%
%   gap_size = Max number of files and/or datasets allowed to be missing for
%   determining the extent of an unlimited virtual dataset with
%   printf-style mappings
%
%   Example:
%       % Create the file access property list
%       faplID = H5P.create('H5P_FILE_ACCESS');
%       H5P.set_libver_bounds(faplID,'H5F_LIBVER_LATEST','H5F_LIBVER_LATEST');          
%       datatypeID = H5T.copy('H5T_NATIVE_DOUBLE');
%       fileID = H5F.create('srcFile.h5','H5F_ACC_TRUNC','H5P_DEFAULT',faplID);
%       dataspaceID = H5S.create_simple(2,[5 5],[]);
%       % For dataset A-0
%       datasetID1 = H5D.create(fileID,'A-0',datatypeID,dataspaceID,'H5P_DEFAULT');
%       H5D.write(datasetID1,'H5ML_DEFAULT','H5S_ALL','H5S_ALL','H5P_DEFAULT',randn(5,5));
%       H5D.close(datasetID1);
%       % For dataset A-2
%       datasetID2 = H5D.create(fileID,'A-2',datatypeID,dataspaceID,'H5P_DEFAULT');
%       H5D.write(datasetID2,'H5ML_DEFAULT','H5S_ALL','H5S_ALL','H5P_DEFAULT',randn(5,5));
%       H5D.close(datasetID2);
%       % For dataset A-3
%       datasetID3 = H5D.create(fileID,'A-3',datatypeID,dataspaceID,'H5P_DEFAULT');
%       H5D.write(datasetID3,'H5ML_DEFAULT','H5S_ALL','H5S_ALL','H5P_DEFAULT',randn(5,5));
%       H5D.close(datasetID3);
%       H5F.close(fileID);
%       vFileID = H5F.create('vdsFile.h5','H5F_ACC_TRUNC','H5P_DEFAULT','H5P_DEFAULT');
%       vspaceID = H5S.create_simple(2,[20 8],[H5ML.get_constant_value('H5S_UNLIMITED') 8]);
%       vdcplID = H5P.create('H5P_DATASET_CREATE');
%       H5P.set_layout(vdcplID,'H5D_VIRTUAL');
%       H5P.set_fill_value(vdcplID,datatypeID,-10);
%       % Create printf-style virtual mapping
%       H5S.select_hyperslab(vspaceID,'H5S_SELECT_SET',[0 0],[6 1],[H5ML.get_constant_value('H5S_UNLIMITED') 1],[5 5]);
%       H5P.set_virtual(vdcplID,vspaceID,'srcFile.h5','/A-%b',dataspaceID);
%       vdatasetID = H5D.create(vFileID,'vdsData',datatypeID,vspaceID,'H5P_DEFAULT',vdcplID,'H5P_DEFAULT');
%       H5S.close(vspaceID);
%       H5D.close(vdatasetID);
%       H5P.close(vdcplID);
%       H5F.close(vFileID);
%       % Re-open the virtual file and dataset
%       vFileID = H5F.open('vdsFile.h5','H5F_ACC_RDONLY','H5P_DEFAULT');
%       vdaplID = H5P.create('H5P_DATASET_ACCESS');
%       % Get the default printf_gap
%       gap = H5P.get_virtual_printf_gap(vdaplID);
%       % Read the data with the default gap
%       vdatasetID = H5D.open(vFileID,'vdsData',vdaplID);
%       data1 = H5D.read(vdatasetID,datatypeID,'H5S_ALL','H5S_ALL','H5P_DEFAULT');
%       H5D.close(vdatasetID);
%       % Set the printf_gap to 1 and retrieve it
%       H5P.set_virtual_printf_gap(vdaplID,1);
%       gap = H5P.get_virtual_printf_gap(vdaplID);
%       % Read the data with the set gap
%       vdatasetID = H5D.open(vFileID,'vdsData',vdaplID);
%       data2 = H5D.read(vdatasetID,datatypeID,'H5S_ALL','H5S_ALL','H5P_DEFAULT');
%       H5D.close(vdatasetID);
%       H5F.close(vFileID);
%
%   See also H5P.set_virtual, H5P.get_virtual_printf_gap.

%   Copyright 2021-2024 The MathWorks, Inc.

validateattributes(dapl_id, {'H5ML.id'}, {'nonempty'});
validateattributes(gap_size, {'double'}, {'integer', 'nonnegative'});
matlab.internal.sci.hdf5lib2('H5Pset_virtual_printf_gap', dapl_id, gap_size);
