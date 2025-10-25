function TD = hardwareSettings(varargin)
%CODER.HARDWARESETTINGS Get settings associated with the current hardware.
%
%  This functions works for code generation only.  In MATLAB, it generates
%  an error.  Use coder.target to write code using coder.hardwareSettings
%  that will also run in MATLAB.
%
%  TD = CODER.HARDWARESETTINGS() Returns a MATLAB structure containing
%  fields that represent the user-accessible settings of the current target
%  hardware.
%
%  V = CODER.HARDWARESETTINGS(S) Returns the value of the setting named S
%  of the current target hardware.
%
%  For example, to get the clock rate of the current target hardware:
%
%    CPUClockRate = coder.hardwareSettings('CPUClockRate');
%
%  See also coder.HardwareBase, coder.target.

%   Copyright 2006-2019 The MathWorks, Inc.

TD = []; %#ok<NASGU>
error(message('Coder:builtins:NotSupportedInMATLAB','coder.hardwareSettings'));
