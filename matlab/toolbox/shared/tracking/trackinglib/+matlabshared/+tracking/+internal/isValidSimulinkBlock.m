function flag = isValidSimulinkBlock(block)
%ISVALIDSIMULINKBLOCK(BLOCK) Return true if BLOCK is a valid Simulink block.
%   The function performs the check without checking out a Simulink
%   license. BLOCK can be full block path or block handle.
%
%   See also: isSimulinkModel.m
%
%   This function is for internal use only and may be removed in a future
%   release.

%   Copyright 2022 The MathWorks, Inc.

flag = false;
isSimulinkLoaded = inmem('-isloaded', 'get_param');
if isSimulinkLoaded
    try %#ok<TRYNC>
        flag = ~isempty(get_param(block,'BlockType'));
    end
end
end

