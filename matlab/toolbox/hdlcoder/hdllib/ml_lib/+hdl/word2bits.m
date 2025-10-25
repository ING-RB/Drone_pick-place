function b = word2bits(d,n)
%HDL.WORD2BITS Convert decimal integer to its binary representation
%   HDL.WORD2BITS(d,n) returns n bits of the binary representation of d as a
%   ufix1 vector

%   Copyright 2023 The MathWorks, Inc.

%#codegen

% Check that input argument exists and is valid
coder.internal.assert(nargin == 2, 'MATLAB:minrhs');
coder.internal.assert((isnumeric(d) || islogical(d)) && isreal(d) ...
    && (~isfi(d) || isfixed(d)), ...
    'hdlmllib:hdlmllib:Word2BitsInvalidInputArg');
coder.internal.assert(isnumeric(n) && isscalar(n) && isreal(n) ...
    && n > 0 && mod(n,1) == 0 && n <= 65535, ...
    'hdlmllib:hdlmllib:Word2BitsInvalidBitsArg');
coder.internal.assert(coder.internal.isConst(n), ...
    'hdlmllib:hdlmllib:Word2BitsNumBitsMustBeConst');

n = uint16(n);
sz = size(d);

% Handle Simulink type propagation
if coder.internal.isAmbiguousTypes
    b = zeros([n*sz(1), sz(2:end)],'like',fi([],0,1,0));
    return;
end

% Get size and type information about input data
expectedNumBits = uint16(0);

isFloatInput = false;

d_vect_tmp = reshape(d, [1 numel(d)]);

switch (class(d))
    case {'uint64', 'int64'}
        d_vect = d_vect_tmp;
        expectedNumBits = uint16(64);
    case {'uint32', 'int32'}
        d_vect = d_vect_tmp;
        expectedNumBits = uint16(32);
    case {'uint16', 'int16'}
        d_vect = d_vect_tmp;
        expectedNumBits = uint16(16);
    case {'uint8', 'int8'}
        d_vect = d_vect_tmp;
        expectedNumBits = uint16(8);
    case {'boolean', 'logical'}
        d_vect = fi(d_vect_tmp,0,1,0);
        expectedNumBits = uint16(1);
    case 'double'
        d_vect = typecast(d_vect_tmp,'uint64');
        expectedNumBits = uint16(64);
        isFloatInput = true;
    case 'single'
        d_vect = typecast(d_vect_tmp,'uint32');
        expectedNumBits = uint16(32);
        isFloatInput = true;
    case 'embedded.fi'
        d_vect = d_vect_tmp;
        expectedNumBits = uint16(d.WordLength);
    otherwise
        coder.internal.error('hdlmllib:hdlmllib:Word2BitsInvalidInputArg');
end

% Verify that the number of output bits is enough for the input value
if isFloatInput
    coder.internal.assert(uint16(n) == expectedNumBits, 'hdlmllib:hdlmllib:Word2BitsInvalidNumFloatBits', expectedNumBits, class(d), n);
else
    coder.internal.assert(uint16(n) >= expectedNumBits, 'hdlmllib:hdlmllib:Word2BitsNotEnoughOutputBits', expectedNumBits);
end

numToCopy = min(n, expectedNumBits);

% Convert input to vector of ufix1 bits
b = zeros([1 numel(d)*n],'like',fi([],0,1,0));

coder.unroll
for i=1:numel(d)
    idx1 = i * n - numToCopy + 1;
    idx2 = i * n;

    % copy over bits from the original data to the output vector
    b(idx1:idx2) = fi(bitget(d_vect(i), numToCopy:-1:1),0,1,0);

    % sign extend first bit (1) if negative int or fi
    if ~isFloatInput && d_vect(i) < 0
        b((i-1)*n+1:idx1-1) = fi(1,0,1,0);
    end
end

% Match original input size
outSize = [n*sz(1), sz(2:end)];
b = reshape(b, outSize);


