%CODER.HDL.CONSTRAINLATENCY Specify the minimum and maximum acceptable hardware latency for a MATLAB function
%
%   CODER.HDL.CONSTRAINLATENCY(minimum_latency, maximum_latency) enables you
%   to specify the desired hardware latency range for a block of code.
%
%   Example:
%     function y = hdltest(a,b)
%         u = a+8;
%         v = b+6;
%         y = region1(u,v);
%     end
%
%     function z = region1(a,b)
%         % Optional comment between function definition and pragma
%         coder.hdl.constrainlatency(0,2);
%         m = a+1;
%         n = b+2;
%         z = m*n;
%     end
%
%   This is a code generation function.  It has no effect in MATLAB.

%#codegen
function constrainlatency(minLatency, maxLatency)
%

%   Copyright 2021-2024 The MathWorks, Inc.

    coder.columnMajor;
    
    if coder.target('hdl')
        coder.ceval('__hdl_constrainlatency', minLatency, maxLatency);
    end
end

% LocalWords:  hdltest
