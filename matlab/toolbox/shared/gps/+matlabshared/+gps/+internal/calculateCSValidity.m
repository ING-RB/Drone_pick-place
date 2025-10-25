function [validity,csIdx] = calculateCSValidity(data)
% Function to calculate checksum and compare it with the checksum in the sentence

% Copyright 2020-21 The MathWorks, Inc.

if(isstring(data))
    data = char(data);
end
calculated_checksum = uint16(0);
% bytes in between "$" and "*" is considered for checksum
% calculation
count = 2;
noChecksumChar = 1;
csIdx = 0;
% checksum is xor of bytes in between $ and *.
while(noChecksumChar)
    if data(count) == uint8('*')
        csIdx = count;
        noChecksumChar = 0;
    else
        calculated_checksum = bitxor(calculated_checksum ,uint16(data(count)));
        count = count + 1;
    end
end
Checksum = uint16(hex2dec(data(count+1:count+2)));
if(calculated_checksum == Checksum)
    validity  = true;
else
    validity  = false;
end
end
