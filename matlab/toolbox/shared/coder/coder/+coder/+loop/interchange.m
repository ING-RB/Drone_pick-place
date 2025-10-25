function out = interchange(varargin)
%coder.loop.interchange interchanges for loops in the generated code
%
%   coder.loop.interchange('loopA_ID','loopB_ID') interchanges nested loops
%   with index names loopA_ID and loopB_ID. These two loops must be 
%   contained in the loop nest immediately following this function.
%
%   x = coder.loop.interchange('loopA_ID','loopB_ID') creates a 
%   coder.loop.Control object that contains an interchange transform. Call 
%   the apply method of 'x' immediately before the loop nest that contains 
%   the two loops that you want to interchange.

%#codegen
%   Copyright 2021-2022 The MathWorks, Inc.
    coder.internal.preserveFormalOutputs;

    if coder.target('MATLAB') && nargout == 0
        return;
    end
    
    out = coder.loop.Control;
    out = out.interchange(varargin{:});
end