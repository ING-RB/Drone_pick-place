function tf = isfits(filename)
%ISFITS Returns true for a FITS file.
%   TF = ISFITS(FILENAME)

%   Copyright 1984-2020 The MathWorks, Inc.

if nargin > 0
    filename = convertStringsToChars(filename);
end

fid = matlab.internal.fopen(filename, 'r');
assert(fid ~= -1, message('MATLAB:imagesci:validate:fileOpen', filename));
sig = fread(fid, 6, 'uint8=>char')';
fclose(fid);
tf = isequal(sig, 'SIMPLE');
