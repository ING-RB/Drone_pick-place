function out = reverse(varargin)
%coder.loop.reverse reverses the execution order of a for loop in the generated code
% 
%   coder.loop.reverse('loopID')  applies the reverse transform to the for 
%   loop with index name 'loopID'. This loop must be contained in the loop
%   nest immediately following this function.
%
%   x = coder.loop.reverse creates a coder.loop.Control object that  
%   contains a reverse transform. Call the apply method of 'x' immediately 
%   before the loop you intend to reverse.
%
%   coder.loop.reverse applies the reverse transform to the loop 
%   immediately following this command. 

%#codegen
%   Copyright 2021-2022 The MathWorks, Inc.
    coder.internal.preserveFormalOutputs;

    if coder.target('MATLAB') && nargout == 0
        return;
    end
    
    out = coder.loop.Control;
    out = out.reverse(varargin{:});
end