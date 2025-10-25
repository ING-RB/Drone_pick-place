function out = tile(varargin)
%coder.loop.tile tiles the for loop with an outer for loop in the generated code
%
%   coder.loop.tile('loopID',tileSize,'tiledLoopID') wraps the loop with 
%   index name 'loopID' within an outer loop. The increment size of the 
%   outer loop is set to tileSize. The outer loop index name is set to 
%   'tiledLoopID'. The loop you want to tile must be contained in the loop 
%   nest immediately following this function.
%
%   x = coder.loop.tile creates a coder.loop.Control object that contains a
%   tile transform. Call the apply method of 'x' immediately before the 
%   loop you want to tile. The default value of tileSize is 2.
%
%   coder.loop.tile applies the tile transform to the loop immediately 
%   following this command.

%#codegen
%   Copyright 2021-2022 The MathWorks, Inc.
    coder.internal.preserveFormalOutputs;

    if coder.target('MATLAB') && nargout == 0
        return;
    end
    
    out = coder.loop.Control;
    out = out.tile(varargin{:});
end