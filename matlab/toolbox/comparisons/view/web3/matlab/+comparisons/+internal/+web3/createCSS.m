function htmlCSS = createCSS()
%

%   Copyright 2021 The MathWorks, Inc.

    htmlCSS = cell(100, 1);
    currentline = 1;

    function writeLine(str, varargin)
        htmlCSS{currentline} = sprintf(str, varargin{:});
        currentline = currentline + 1;
    end

    colors = getSettingsColors();

    writeLine('<style type="text/css">\n');

    writeLine('pre {\n');
    writeLine('  display:inline-block;\n');
    writeLine('}\n');
    writeLine('.diffnomatch {\n');
    writeLine('  background: %s;\n',char(colors.modifiedline));
    writeLine('     display: inline-block;\n');
    writeLine('}\n');
    writeLine('.right {\n');
    writeLine('  background: %s;\n',char(colors.rightdiff));
    writeLine('     display: inline-block;\n');
    writeLine('}\n');
    writeLine('.left {\n');
    writeLine('  background: %s;\n',char(colors.leftdiff));
    writeLine('     display: inline-block;\n');
    writeLine('}\n');
    writeLine('.diffsoft {\n');
    writeLine('    color: #888;\n');
    writeLine('}\n');
    writeLine('.diffskip {\n');
    writeLine('       color: #888;\n');
    writeLine('  background: %s;\n',char(colors.background));
    writeLine('     display: inline-block;\n');
    writeLine('}\n');
    writeLine('.bold {\n');
    writeLine('  font-weight:bold;\n');
    writeLine('}\n');

    writeLine('</style>\n');

    htmlCSS = sprintf('%s\n', htmlCSS{1:currentline-1});
end

function colors = getSettingsColors()
    import comparisons.internal.colorutil.Colors
    import comparisons.internal.colorutil.rgb2hex

    colors.background = '#e0e0e0';
    colors.leftdiff     = rgb2hex( Colors.leftColor() );
    colors.rightdiff    = rgb2hex( Colors.rightColor() );
    colors.modifiedline = rgb2hex( Colors.modifiedColor() );
end