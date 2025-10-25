function d = bits2word(b,arg1,arg2,arg3)
%HDL.BITS2WORD Convert text representation of binary number to double value
%   d = HDL.BITS2WORD(b,n) converts the n column-wise bit elements in b to
%   decimal values of type numerictype(0,n,0) 
%   d = HDL.BITS2WORD(b,typename) converts the column-wise bit elements in b 
%   to decimal values of the type specified in typename 
%   d = HDL.BITS2WORD(b,'like',p) converts the column-wise bit elements in b 
%   to decimal values of the same type as p
%   d = HDL.BITS2WORD(b,n,'like',p) converts the n column-wise bit elements
%   in b to decimal values of the same type as p

%   Copyright 2023 The MathWorks, Inc.

%#codegen

% Check that input arguments exist and are valid
coder.internal.assert(nargin >= 2, 'MATLAB:minrhs');

coder.internal.assert((isnumeric(b) || islogical(b)) && isreal(b) ...
    && (~isfi(b) || isfixed(b)), ...
    'hdlmllib:hdlmllib:Word2BitsInvalidInputArg');

b_temp = reshape(b,[1 numel(b)]);

% Convert b to binary values
b_vect = (b_temp ~= 0);

coder.internal.prefer_const(arg1);
coder.internal.assert(coder.internal.isConst(arg1), ...
    'hdlmllib:hdlmllib:Word2BitsNumBitsMustBeConst');

inSize = size(b);
outIsFi = false;
outIsFloat = false;
outIsLogical = false;
outFimath = hdlfimath;
numBits = uint16(0);

if nargin == 2
    outIsFi = ~ischar(arg1);

    if outIsFi
        % use provided number of input bits
        coder.internal.assert(isnumeric(arg1) && isscalar(arg1) ...
            && isreal(arg1) && arg1 > 0 && arg1 <= 128 && mod(arg1,1) == 0, ...
            'hdlmllib:hdlmllib:Word2BitsInvalidBitsArg');
        numBits = uint16(arg1);
        outFiType = fi([],0,numBits,0,outFimath);
    else
        % determine number of input bits based on typename string
        classname = arg1;
        switch(classname)
            case 'double'
                numBits = uint16(64);
                outIsFloat = true;
            case 'single'
                numBits = uint16(32);
                outIsFloat = true;
            case {'uint64', 'int64'}
                numBits = uint16(64);
            case {'uint32', 'int32'}
                numBits = uint16(32);
            case {'uint16', 'int16'}
                numBits = uint16(16);
            case {'uint8', 'int8'}
                numBits = uint16(8);
            case {'boolean', 'logical'}
                numBits = uint16(1);
                outIsLogical = true;
            otherwise
                coder.internal.error('hdlmllib:hdlmllib:Bits2WordInvalidTypeName');
        end
    end

    % Handle Simulink size propagation
    if coder.internal.isAmbiguousTypes
        outSize = [inSize(1)/numBits inSize(2:end)];
        d = zeros(outSize, 'like', fi([],0,numBits,0,outFimath));
        return;
    end

else
    % Input validation to get example value and number of input bits
    if nargin == 3
        coder.internal.assert(ischar(arg1) && strcmpi(arg1,'like'), ...
            'hdlmllib:hdlmllib:Bits2WordInvalidLikeArg');
        exampleVal = arg2;

        numBits = uint16(inSize(1)); % assume output is 1xN vector

    else % nargin == 4
        coder.internal.assert(coder.internal.isConst(arg2) && ...
            ischar(arg2) && strcmpi(arg2,'like'), ...
            'hdlmllib:hdlmllib:Bits2WordInvalidLikeArg');
        exampleVal = arg3;

        coder.internal.assert(isnumeric(arg1) && isscalar(arg1) ...
            && isreal(arg1) && arg1 > 0 && arg1 <= 128 && mod(arg1,1) == 0, ...
            'hdlmllib:hdlmllib:Word2BitsInvalidBitsArg');

        numBits = uint16(arg1); % use provided number of input bits

    end

    % Handle Simulink size propagation
    if coder.internal.isAmbiguousTypes
        outSize = [inSize(1)/numBits inSize(2:end)];
        d = zeros(outSize, 'like', fi([],0,numBits,0,outFimath));
        return;
    end

    % Determine the expected number of input bits for provided type
    classname = class(exampleVal);
    switch(classname)
        case 'double'
            expNumBits = uint16(64);
            outIsFloat = true;
        case 'single'
            expNumBits = uint16(32);
            outIsFloat = true;
        case {'uint64', 'int64'}
            expNumBits = uint16(64);
        case {'uint32', 'int32'}
            expNumBits = uint16(32);
        case {'uint16', 'int16'}
            expNumBits = uint16(16);
        case {'uint8', 'int8'}
            expNumBits = uint16(8);
        case {'boolean', 'logical'}
            expNumBits = uint16(1);
            outIsLogical = true;
        case 'embedded.fi'
            coder.internal.assert(isfixed(exampleVal), ...
                'hdlmllib:hdlmllib:Bits2WordInvalidLikeType',classname);
            expNumBits = uint16(exampleVal.WordLength);
            outIsFi = true;
            outFiType = exampleVal;
        otherwise
            coder.internal.error('hdlmllib:hdlmllib:Bits2WordInvalidLikeType',classname);
    end

    % Verify that the number of provided and expected bits is valid
    if nargin == 3
        coder.internal.assert(numBits == expNumBits, ...
            'hdlmllib:hdlmllib:Bits2WordInvalidNumRows', expNumBits);
    else % nargin == 4
        coder.internal.assert(numBits == expNumBits, ...
            'hdlmllib:hdlmllib:Bits2WordInvalidNumBitsForType', numBits, classname, expNumBits);
    end
end

% Verify that the number of rows is valid for this specified number of bits
coder.internal.assert(mod(inSize(1),numBits) == 0, ...
    'hdlmllib:hdlmllib:Bits2WordInvalidNumRows', numBits);

outSize = [inSize(1)/numBits inSize(2:end)];


% Convert bit array to output type
if outIsFloat
    d = zeros(1, prod(outSize), classname);

    if strcmp(classname, 'single')
        tempclass = 'uint32';
    else
        tempclass = 'uint64';
    end

    coder.unroll
    for i=1:numel(d)
        idx1 = (i-1)*numBits;

        temp = zeros(1, tempclass);

        coder.unroll
        for j=1:numBits
            temp = bitset(temp, numBits-j+1, uint16(b_vect(idx1+j)));
        end

        d(i) = typecast(temp, classname);

    end

elseif outIsLogical
    d = b_vect;
else % integer or fi type
    if outIsFi
        d = zeros(1, prod(outSize), 'like', outFiType);
    else
        d = zeros(1, prod(outSize), classname);
    end

    coder.unroll
    for i=1:numel(d)
        idx1 = (i-1)*numBits;

        coder.unroll
        for j=1:numBits
            d(i) = bitset(d(i), numBits-j+1, uint16(b_vect(idx1+j)));
        end
    end
end

d = reshape(d, outSize);