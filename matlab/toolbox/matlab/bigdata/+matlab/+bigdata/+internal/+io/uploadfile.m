function uploadfile(localSrc, iriDst)
%UPLOADFILE Uploads a local file to a remote cloud storage IRI.

%   Copyright 2018-2020 The MathWorks, Inc.

import matlab.io.internal.vfs.stream.createStream

[localSrc, iriDst] = convertStringsToChars(localSrc, iriDst);
src = createStream(localSrc, 'r');
dst = createStream(iriDst, 'w');

numBytes = double(src.FileSize);
THIRTY_TWO_MB = 32 * 1024 * 1024;

while numBytes > 0
    bufferSize = min(numBytes, THIRTY_TWO_MB);
    buffer = read(src, bufferSize, 'uint8');
    write(dst, buffer);
    numBytes = numBytes - bufferSize;
end

% Commit changes, allowing any errors to propagate back to the client.
close(dst);
end
