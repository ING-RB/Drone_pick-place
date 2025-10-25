function p = canUseExtrinsic
%MATLAB Code Generation Private Function

% Return true if an extrinsic call can be used in the present context. False
% otherwise.

%   Copyright 2017-2019 The MathWorks, Inc.
%#codegen
coder.inline('always');
if coder.target('MATLAB')
    p = true;
else
    INMATLAB = coder.const(coder.internal.runs_in_matlab());

    p = coder.const(INMATLAB && coder.internal.get_eml_option('MXArrayCodegen')) && ~coder.internal.isInParallelRegion();
end
