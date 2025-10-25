function csByte = generateCS2sComplementSum(packet)
% Function to generate checksum. Function evaluates sum of all bytes, discard carry and
% and find 2s complement of this value. This value is considered as
% checksum byte

%Copyright 2021 The MathWorks, Inc.
 %#codegen
byteSum = uint16(0);
datalength = numel(packet);
% Sum all the bytes, discard the carry
for i = 1:datalength
    byteSum = mod(byteSum + uint16(packet(i)),256);
end
% find 2s complement of the sum 
 csByte = uint8(mod(uint16(bitcmp(uint8(byteSum))) + 1,256));