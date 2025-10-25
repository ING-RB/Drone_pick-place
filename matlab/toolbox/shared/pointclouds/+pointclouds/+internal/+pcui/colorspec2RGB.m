function rgb = colorspec2RGB(str)
% map colorspec string to RGB triplet. Use Line object to do
% the work of converting string to RGB.

% Copyright 2018 The MathWorks, Inc.

persistent converter;
if isempty(converter)
    converter =  matlab.graphics.chart.primitive.Line;
end
try
    if strncmpi(str,'n',1)
        % 'none' is a valid string for Line, but not a valid
        % colorspec. % set to bad Color value for Line to throw
        % error.
        converter.Color = 'xx';
    end
    converter.Color = str;
    rgb = converter.Color;
catch ME   
    error(message('vision:pointcloud:invalidColorspec',str));
end
