function out = areAllTpToolsInstalled(instrSetObj)
%matlab.hwmgr.internal.util.areAllTpToolsInstalled Checks if all tools in 
% the given set are installed.
%
% Inputs:
%   instrSetObj - A single instance or cell array of instances of the
%                 InstructionSet class
%
% Outputs:
%   out - Logical value indicating whether all tools in the set are
%         installed (true) or not installed (false).
%
% Example:
%   instrsetDir = fullfile(matlabroot, 'test', 'tools', ...
%                             'shared', 'hwmanager', 'hwsetup', 'testdata', 'instructionsets');
%   instrSet = matlab.hwmgr.internal.getInstructionSetsFromFolder(istrsetDir)
%   allInstalled = matlab.hwmgr.internal.util.areAllTpToolsInstalled(instrSet);
%   disp(allInstalled); % This will display 'true' if 'isInstalled' is true
%
% See also: matlab.hwmgr.internal.util.isInternetAccessAvailable
%
% Copyright 2024 The MathWorks, Inc.
if ~iscell(instrSetObj)
    instrSetObj = {instrSetObj}; % Wrap single object in cell array for uniform processing
end

assert(all(cellfun(@(x) isa(x, 'matlab.hwmgr.internal.InstructionSet'), instrSetObj)), ...
    'Input must be a single or cell array of InstructionSet object.')

out = true;
for i = 1:numel(instrSetObj)
    if ~instrSetObj{i}.isInstalled
        out = false;
        break;
    end
end
end