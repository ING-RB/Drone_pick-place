function replaceBlock(currentBlkPath,desiredBlockPath,varargin)
% replaceBlock Replace a block under the mask
%
%   replaceBlock(currentBlkPath,desiredBlockPath,varargin)
%
% Replace a block while keeping the name and location of the original
% block. 
%
%   Inputs:
%     currentBlkPath - Full path to the current block
%     desiredBlkPath - Full path to the new, desired block
%     varargin       - NVPair properties to be set on the desired block

%   Copyright 2016 The MathWorks, Inc.

p = get_param(currentBlkPath,'Position');
delete_block(currentBlkPath);
add_block(desiredBlockPath,currentBlkPath,'Position',p,varargin{:});
end