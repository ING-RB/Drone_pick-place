%MATLABRC Master startup MATLAB script.
%   MATLABRC is automatically executed by MATLAB during startup.
%   It sets the default figure size, and sets a few uicontrol defaults.
%
%   On multi-user or networked systems, the system manager can put
%   any messages, definitions, etc. that apply to all users here.
%
%   A STARTUP command is invoked after executing MATLABRC if the file 'startup.m'
%   exists on the MATLAB path.

%   Copyright 1984-2022 The MathWorks, Inc.

try
    % The RecursionLimit forces MATLAB to throw an error when the specified
    % function call depth is hit.  This protects you from blowing your stack
    % frame (which can cause MATLAB and/or your computer to crash).
    % The default is set to 500.
    % Uncomment the line below to set the recursion limit to something else.
    % Set the value to inf if you don't want this protection
    % set(0,'RecursionLimit',700)
catch exc
    warning(message('MATLAB:matlabrc:RecursionLimit', exc.identifier, exc.message));
end

% Set default warning level to WARNING BACKTRACE.  See help warning.
warning backtrace

try
    % Enable/Disable selected warnings by default
    warning off MATLAB:mir_warning_unrecognized_pragma

    warning off MATLAB:JavaComponentThreading
    warning off MATLAB:JavaEDTAutoDelegation

    % Random number generator warnings
    warning off MATLAB:RandStream:ReadingInactiveLegacyGeneratorState
    warning off MATLAB:RandStream:ActivatingLegacyGenerators

    warning off MATLAB:class:DynPropDuplicatesMethod
catch exc
    warning(message('MATLAB:matlabrc:DisableWarnings', exc.identifier, exc.message));
end

% Clean up workspace.
clear

% Defer echo until startup is complete
try
if strcmpi(system_dependent('getpref','GeneralEchoOn'),'BTrue')
    echo on
end
catch exc
    warning(message('MATLAB:matlabrc:InitPreferences', exc.identifier, exc.message));
end

