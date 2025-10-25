function bfithelp(cmd)
% BFITHELP Displays help for Basic Fitting and Data Statistics
%   BFITHELP('bf') displays Basic Fitting Help
%   BFITHELP('ds') displays Data Statistics Help

%   Copyright 1984-2024 The MathWorks, Inc.

switch cmd
    case 'bf'
        try
            helpview('matlab','basic-fitting-help');
        catch err
            bfitcascadeerr(getString(message('MATLAB:graph2d:bfit:ErrorUnableToDisplayHelpForBasicFitting', err.message ))...
                , getString(message('MATLAB:graph2d:bfit:TitleBasicFitting')));
        end
        
    case 'ds'
        try
            helpview('matlab','data-stats-help');
        catch err
            bfitcascadeerr(getString(message('MATLAB:graph2d:bfit:ErrorUnableToDisplayHelpForDataStatistics', err.message )),...
                getString(message('MATLAB:graph2d:bfit:TitleDataStatistics')));
        end
end
