function swathID = attach(swfid,swathname) 
%attach attach to swath dataset.
%   swathID = attach(swfID,SWATHNAME) attaches to the swath identified
%   by SWATHNAME in the file identified by swfID.  swathID is the
%   identifier for the named swath.
%
%   This function corresponds to the SWattach function in the HDF-EOS
%   library C API.
%
%   Example:
%       import matlab.io.hdfeos.*
%       swfid = sw.open('swath.hdf');
%       swathID = sw.attach(swfid,'Example Swath');
%       sw.detach(swathID);
%       sw.close(swfid);
%
%   See also sw, sw.detach.

%   Copyright 2010-2017 The MathWorks, Inc.

if nargin > 1
    swathname = convertStringsToChars(swathname);
end

swathID = hdf('SW','attach',swfid,swathname);
hdfeos_sw_error(swathID,'SWattach');
