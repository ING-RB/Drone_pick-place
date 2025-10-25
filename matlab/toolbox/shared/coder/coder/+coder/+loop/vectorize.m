function out = vectorize(varargin)
%coder.loop.vectorize applies the vectorize transform to a for loop in the generated code
%
%   coder.loop.vectorize('loopID') applies the vectorize transform to the 
%   for loop with index name 'loopID'. This loop must be contained in
%   the loop nest immediately following this function.
%
%   x = coder.loop.vectorize creates a coder.loop.Control object that  
%   contains a vectorize transform. Call the apply method of 'x'  
%   immediately before the loop you intend to vectorize.
%
%   coder.loop.vectorize applies the vectorize transform to the for loop 
%   immediately following this command. 
% 
%   To apply this transform, in your code generation configuration
%   settings, set the InstructionSetExtensions parameter.

%#codegen
%   Copyright 2021-2022 The MathWorks, Inc.
    coder.internal.preserveFormalOutputs;

    if coder.target('MATLAB') && nargout == 0
        return;
    end
    
    out = coder.loop.Control;
    out = out.vectorize(varargin{:});
end