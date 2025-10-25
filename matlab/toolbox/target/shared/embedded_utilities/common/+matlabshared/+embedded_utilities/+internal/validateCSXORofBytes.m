function isValid = validateCSXORofBytes(packet,checksumByte)
% Function to validate checksum. Function evaluates XOR of all bytes and
% then check with the input checksum byte to ensure validity

%Copyright 2021 The MathWorks, Inc.
    
 %#codegen
calculatedChecksum = uint8(0);
isValid = false;
datalength = numel(packet);
for i = 1:datalength
    calculatedChecksum = bitxor(calculatedChecksum,packet(i));
end
if calculatedChecksum == checksumByte
    isValid = true;
end