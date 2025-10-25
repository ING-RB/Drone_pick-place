function gridID = attach(gfid,gridname) 
%attach Attach to existing grid.
%   gridID = attach(gfID,GRIDNAME) attaches to the grid dataset
%   identified by GRIDNAME in the file identified by gfID.  gridID is the
%   identifier for the grid dataset.
%
%   This function corresponds to the GDattach function in the HDF-EOS
%   library C API.
%
%   Example:  Attach to the grid named 'PolarGrid' in the file 'grid.hdf'.
%       import matlab.io.hdfeos.*
%       gfID = gd.open('grid.hdf');
%       gridID = gd.attach(gfID,'PolarGrid');
%       gd.detach(gridID);
%       gd.close(gfID);
%
%   See also gd, gd.detach, gd.readField, gd.inqGrid.

%   Copyright 2010-2017 The MathWorks, Inc.

if nargin > 1
    gridname = convertStringsToChars(gridname);
end

gridID = hdf('GD','attach',gfid,gridname);
hdfeos_gd_error(gridID,'GDattach');
