function csByte = generateCSXORofBytes(packet)
% Function to generate checksum. Function evaluates XOR of all bytes
% to create checksum byte

%Copyright 2021 The MathWorks, Inc.
    
 %#codegen
csByte = uint8(0);
datalength = numel(packet);
for i = 1:datalength
    csByte = bitxor(csByte,packet(i));
end
