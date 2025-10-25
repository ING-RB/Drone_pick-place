function tf = isico(filename)
%ISICO Returns true for an ICO file.
%   TF = ISICO(FILENAME)

%   Copyright 1984-2020 The MathWorks, Inc.

if nargin > 0
    filename = convertStringsToChars(filename);
end

fid = matlab.internal.fopen(filename, 'r', 'ieee-le');
assert(fid ~= -1, message('MATLAB:imagesci:validate:fileOpen', filename));
sig = fread(fid, 2, 'uint16');
fclose(fid);
tf = isequal(sig, [0; 1]);
