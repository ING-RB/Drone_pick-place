function BlockIndex = getCorrectBlockIndex(blkH)
% getCorrectBlockIndex Helper function for EKF&UKF&PF blocks
%
% These block can have multiple CorrectX blocks underneath where X is an
% integer >=1. blkH is a handle to one of these blocks. This code extracts
% this integer X from the block name. 
%
% This is called by the MaskInit code of CorrectX blocks under EKF/UKF/PF

%   Copyright 2016-2017 The MathWorks, Inc.

str = get_param(blkH, 'Name'); % block name string
str = regexp(str,'Correct(\d+)','tokens');
% Safety: Ensure we get a number
if isempty(str)
    BlockIndex = 1;
else
    BlockIndex = str2double(str{1}{1});
end
end