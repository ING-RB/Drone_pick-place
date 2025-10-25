function blocksize = getBlockSizeForKDE(x)
%GETBLOCKSIZEFORKDE Return block size to use in KDE computation
%   BLOCKSIZE = GETBLOCKSIZEFORKDE(X) returns a block size BLOCKSIZE to use 
%   when performing KDE on some data X. The block size determines if KDE is
%   performed on the dataset as a whole or if it is instead performed on
%   chunks.
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

%   Copyright 2023 The MathWorks, Inc.
if isa(x,"gpuArray")
    blocksize = 2e7; % Roughly 16MB largest block
else
    blocksize = 3e4;
end
end