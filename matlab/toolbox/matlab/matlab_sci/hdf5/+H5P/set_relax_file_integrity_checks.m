function set_relax_file_integrity_checks(fapl_id, flag)
%H5P.set_relax_file_integrity_checks relaxes file integrity checks that
%may issue errors for some valid files.
%  H5P.set_relax_file_integrity_checks(fapl_id,flag) sets the flag for relaxing
%  file integrity checks for the file access property list identifier FAPL_ID to the
%  value specified by FLAG.
%
%  fapl_id - File access property list identifier.
%  flag    - Flag for relaxing file integrity checks, specified as one of
%            these string scalars or character vectors or their numeric
%            equivalents:
%              "H5F_RFIC_UNUSUAL_NUM_UNUSED_NUMERIC_BITS": Relax
%                integrity checks for detecting unusually high values for
%                the number of unused bits in numeric datatype classes
%                (H5T_INTEGER, H5T_FLOAT, and H5T_BITFIELD).
%              "H5F_RFIC_ALL": Relax all integrity checks.
%
%   Example: Relax the integrity checks for detecting unusually high values
%   for the number of unused bits in numeric datatype classes. Then read an
%   entire dataset.
%       fapl = H5P.create("H5P_FILE_ACCESS");
%       H5P.set_relax_file_integrity_checks(fapl,"H5F_RFIC_UNUSUAL_NUM_UNUSED_NUMERIC_BITS")
%       fid = H5F.open("example.h5","H5F_ACC_RDONLY",fapl);
%       dset_id = H5D.open(fid,"/g1/g1.1/dset1.1.1");
%       data = H5D.read(dset_id);
%       H5D.close(dset_id)
%       H5F.close(fid)
%       H5P.close(fapl)
%
%  See also H5P.get_relax_file_integrity_checks.

%   Copyright 2024 The MathWorks, Inc.

validateattributes(fapl_id, {'H5ML.id'}, {'nonempty'});
if ~isnumeric(flag)
    validateattributes(flag,{'char','string'},{'nonempty','scalartext'});
    flag = convertStringsToChars(flag);
else
    validateattributes(flag,{'double'},{'nonempty','scalar','finite','integer'});
end

matlab.internal.sci.hdf5lib2('H5Pset_relax_file_integrity_checks',...
    fapl_id, flag);

