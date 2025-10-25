function flag = get_relax_file_integrity_checks(fapl_id)
%H5P.get_relax_file_integrity_checks gets the flag for relaxed file integrity checks.
%  flag = H5P.get_relax_file_integrity_checks(fapl_id) returns the flag for
%  relaxing file integrity checks from the file access property list identifier
%  FAPL_ID.
%
%  fapl_id - File access property list identifier.
%  flag    - Flag for relaxing file integrity checks, interpreted as one of these:
%               "H5F_RFIC_UNUSUAL_NUM_UNUSED_NUMERIC_BITS": Relax integrity
%                 checks for detecting unusually high values for the number
%                 of unused bits in numeric datatype classes (H5T_INTEGER,
%                 H5T_FLOAT, and H5T_BITFIELD).
%               "H5F_RFIC_ALL": Relax all integrity checks.
%
%  Example: Retrieve the flag for relaxing file integrity checks after setting it.
%      fapl = H5P.create("H5P_FILE_ACCESS");
%      H5P.set_relax_file_integrity_checks(fapl,"H5F_RFIC_UNUSUAL_NUM_UNUSED_NUMERIC_BITS")
%      fid = H5F.open("example.h5","H5F_ACC_RDONLY",fapl);
%      dset_id = H5D.open(fid,"/g1/g1.1/dset1.1.1");
%      flag = H5P.get_relax_file_integrity_checks(fapl)
%      H5D.close(dset_id)
%      H5F.close(fid)
%      H5P.close(fapl)
%
%  See also H5P.set_relax_file_integrity_checks.

%   Copyright 2024 The MathWorks, Inc.


validateattributes(fapl_id,{'H5ML.id'},{'nonempty','scalar'});
flag = matlab.internal.sci.hdf5lib2(...
    'H5Pget_relax_file_integrity_checks',fapl_id);

