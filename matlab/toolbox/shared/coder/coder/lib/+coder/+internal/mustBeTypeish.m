function mustBeTypeish(t)
%MATLAB Code Generation Private Function
%#codegen

%   Copyright 2022 The MathWorks, Inc.

coder.internal.allowEnumInputs;
coder.internal.allowHalfInputs;

coder.internal.assert(isa(t, 'coder.Type') || isa(t, 'coder.type.Base'),...
    'Coder:toolbox:CoderWriteMustBeTypeIsh');

end
