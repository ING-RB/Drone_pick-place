function tf = ispng(filename)
%ISPNG Returns true for a PNG file.
%   TF = ISPNG(FILENAME)

%   Copyright 1984-2020 The MathWorks, Inc.

if nargin > 0
    filename = convertStringsToChars(filename);
end

fid = matlab.internal.fopen(filename, 'r', 'ieee-be');
assert(fid ~= -1, message('MATLAB:imagesci:validate:fileOpen', filename));
sig = fread(fid, 8, 'uint8')';
fclose(fid);
tf = isequal(sig, [137 80 78 71 13 10 26 10]);
