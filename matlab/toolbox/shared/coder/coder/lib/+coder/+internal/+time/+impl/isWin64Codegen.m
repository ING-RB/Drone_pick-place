function p = isWin64Codegen()
%MATLAB Code Generation Private Function

%   Copyright 2018-2019 The MathWorks, Inc.

%#codegen
arch = coder.const(feval('computer','arch'));
p = coder.internal.get_eml_option('TicTocPauseForceWindowsAPIs') || ...
    (~coder.internal.runs_in_matlab() && arch == "win64" && isHostOrRapidAccel());

%--------------------------------------------------------------------------

function p = isHostOrRapidAccel
p = coder.internal.isTargetMATLABHost() || coder.target('rtwForRapid');

%--------------------------------------------------------------------------
