function hash = hashUInt32(in)
%#codegen

%   Copyright 2023-2024 The MathWorks, Inc.

c1 = uint32(0xcc9e2d51);
c2 = uint32(0x1b873593);
r1 = int32(15);
r2 = int32(13);
m=uint32(5);
n = uint32(0xe6546b64);

hash = uint32(0);%use seed?


for idx = 1:numel(in)

    chunk = bitshift(in(idx), -16);%high order half - FIXME: should this use eml_rshift? and in general, should we use the builtins here?
    coder.unroll();
    for i=1:2 %fixme: work with more chunks for bigger types? or arrays?
        chunk = bigMul(chunk, c1); %FIXME: muls are generating bounds checks for saturation - any way to disable?
        chunk = rotateLeft(chunk, r1);
        chunk = bigMul(chunk, c2);
        hash = bitxor(chunk, hash, 'uint32');
        hash = rotateLeft(hash, r2);
        hash = bigPlus(bigMul(hash,m), n);

        chunk = bitand(in(idx), uint32(0xffff));%low order half
    end

end

%murmur includes an xor with 'len' here, not sure why

hash = bitxor(hash, bitshift(hash, 16, 'uint32'), 'uint32');
hash = bigMul(hash,uint32(0x85ebca6b));
hash = bitxor(hash, bitshift(hash, 13, 'uint32'), 'uint32');
hash = bigMul(hash,uint32(0xc2b2ae35));
hash = bitxor(hash, bitshift(hash, 16, 'uint32'), 'uint32');


end

function out = rotateLeft(in, n)
coder.internal.prefer_const(n);

out = bitor(bitshift(in, -1*n, 'uint32'), bitshift(in, 32-n, 'uint32'), 'uint32');

%n must be less than 32
%fixme: should this use builtins instead?
%algorithm from here: https://blog.regehr.org/archives/1063
%out = bitor(bitshift(in, -1*n), bitshift(in, bitand(-1*in, uint32(31)))); <-something is wrong with this line but im not sure what

end


function out = bigMul(a,b)
coder.inline('always');
coder.internal.prefer_const(b);

if coder.target('MATLAB')
    out = coder.internal.wrappingMulUInt32(a,b);
else
    out = eml_times(a,b,'uint32','wrap');
end

end

function out = bigPlus(a,b)
coder.inline('always');
coder.internal.prefer_const(b);

if coder.target('MATLAB')
    out = coder.internal.wrappingAddUInt32(a,b);
else
    out = eml_plus(a,b,'uint32', 'wrap');
end

end

% LocalWords:  rshift builtins muls
