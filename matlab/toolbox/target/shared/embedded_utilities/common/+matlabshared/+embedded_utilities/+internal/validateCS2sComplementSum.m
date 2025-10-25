function isValid = validateCS2sComplementSum(packet,checksumByte)
% Function to validate checksum. Function evaluates sum of all bytes, discard carry and
% and find 2s complement of this value. This value will be check against
% input checksum byte to ensure validity

%Copyright 2021 The MathWorks, Inc.
%#codegen
byteSum = uint16(0);
isValid = false;
datalength = numel(packet);
% Sum all the bytes, discard the carry
for i = 1:datalength
    byteSum = mod(byteSum + uint16(packet(i)),256);
end
% find 2s complement of the sum 
calculatedChecksum = uint8(mod(uint16(bitcmp(uint8(byteSum))) + 1,256));
if calculatedChecksum == checksumByte
    isValid = true;
end