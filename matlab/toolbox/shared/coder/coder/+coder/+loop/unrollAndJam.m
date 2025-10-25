function out = unrollAndJam(varargin)
%coder.loop.unrollAndJam applies the unroll and jam transform to a for loop in the generated code
%
%   coder.loop.unrollAndJam('loopID',unrollFactor) serializes iterations of
%   the loop with index name 'loopID'. This loop must be contained in the 
%   loop nest immediately following this function. The unrollFactor 
%   argument specifies the number of serializations inside the loop.
%
%   x = coder.loop.unrollAndJam creates a coder.loop.Control object that 
%   contains an unroll and jam transform. Call the apply method of 'x'  
%   immediately before loop which you intend to transform. The default  
%   value of unrollFactor is 2.
%
%   coder.loop.unrollAndJam applies the unroll and jam transform to the
%   loop immediately following this command. 

%#codegen
%   Copyright 2021-2022 The MathWorks, Inc.
    coder.internal.preserveFormalOutputs;

    if coder.target('MATLAB') && nargout == 0
        return;
    end
    
    out = coder.loop.Control;
    out = out.unrollAndJam(varargin{:});
end