%CODER.HDL.STABLE Specify the minimum and maximum acceptable hardware
%latency for a MATLAB function
%
%   CODER.HDL.STABLE(var_name) enables you to define stable inputs in your
%   MATLAB code and thus facilitate area optimization of the synthesized
%   SystemC code. This pragma can be used when an input port holds a stable
%   value during MATLAB simulation. This pragma must be inserted at the
%   start of the MATLAB design.
%
%   Example:
%     function out = myFun(in1, in2)
%         coder.hdl.stable('in2');
%         out = int16(in1);
%         for i = 1:100
%             out = out + in2;
%         end
%     end
%
%   This is a code generation function.  It has no effect in MATLAB.

%#codegen
function stable(ioVar)
%

%   Copyright 2022-2024 The MathWorks, Inc.
    coder.internal.prefer_const(ioVar);
    coder.internal.assert(ischar(ioVar), 'hdlmllib:hdlmllib:StablePragmaBadArg');
    coder.columnMajor;
    if coder.target('hdl')
        coder.ceval('-preservearraydims', '__hdl_stable', ioVar);
    end
end

% LocalWords:  hdlmllib
