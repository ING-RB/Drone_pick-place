function out = parallelize(varargin)
%coder.loop.parallelize controls parallelization of loops in the generated code
%
%   coder.loop.parallelize('never')  disables automatic parallelization of 
%   the for loop placed immediately after it.
%
%   coder.loop.parallelize('loopID') applies the parallelize transform to 
%   the for loop with index name 'loopID'. This loop must be contained in
%   the loop nest immediately following this function.
%
%   x = coder.loop.parallelize creates a coder.loop.Control object that  
%   contains a parallelize transform. Call the apply method of 'x'  
%   immediately before the loop you want to parallelize.
%
%   coder.loop.parallelize applies the parallelize transform to the for 
%   loop immediately following this command. 
% 
%   To apply this transform, enable this configuration setting:
%   EnableOpenMP (for code generation from MATLAB) or MultiThreadedLoops 
%   (for code generation from Simulink).

%#codegen
%   Copyright 2021-2022 The MathWorks, Inc.
    coder.internal.preserveFormalOutputs;

    if coder.target('MATLAB') && nargout == 0
        return;
    end
    
    out = coder.loop.Control;
    out = out.parallelize(varargin{:});
end