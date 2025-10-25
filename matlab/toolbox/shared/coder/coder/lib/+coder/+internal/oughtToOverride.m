function out = oughtToOverride(cls, fcn)
%MATLAB Code Generation Private Function
%check if classname cls should override function fcn
%do not allow single or double to override functions

%   Copyright 2021-2022 The MathWorks, Inc.
%#codegen
coder.internal.prefer_const(cls, fcn)
out = coder.const(~coder.internal.isFloatClass(cls)) &&...
      coder.const(feval('coder.internal.hasStaticMethod', cls, fcn));

end
