function warnfiguredialog(functionName)
%

%   Copyright 2006-2021 The MathWorks, Inc.

% Throws error if in -nojvm mode. 
% Does not error for -nodisplay and -noFigureWindows modes
matlab.ui.internal.utils.checkJVMError;

% @TODO When we are ready to deprecate dialogs in NoFigureWindows modes
% other than nojvm, use this check to throw errors:
% if feature('NoFigureWindows')

if ~feature('ShowFigureWindows')
    warning(message('MATLAB:hg:NoDisplayNoFigureSupportSeeReleaseNotes', functionName));
end

end

