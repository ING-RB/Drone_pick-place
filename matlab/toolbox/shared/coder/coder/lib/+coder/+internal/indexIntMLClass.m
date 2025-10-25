function cls = indexIntMLClass
%

%   Copyright 2013-2019 The MathWorks, Inc.

% Return a MATLAB integer class representing coder.internal.indexIntClass.  This
% rounds-up in the sense that it chooses the next larger type if its size is not
% a power of 2.

%#codegen
idxIntNbits = double(coder.internal.int_nbits(coder.internal.indexIntClass()));
nbits = pow2(nextpow2(idxIntNbits));
issigned = intmin(coder.internal.indexIntClass()) < zeros(coder.internal.indexIntClass());
cls = coder.internal.int_cls_from_nbits(nbits, issigned);
