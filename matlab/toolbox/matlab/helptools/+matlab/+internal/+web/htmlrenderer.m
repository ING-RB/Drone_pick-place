function success = htmlrenderer(option)
%HTMLRENDERER Specify which HTML renderer to use.
%   This command is unsupported and may change at any time in the future.
 
%   Copyright 1984-2020 The MathWorks, Inc.

success = 1;
if strcmp(option, 'basic')
    com.mathworks.mlwidgets.html.HtmlComponentFactory.setDefaultType('HTMLRENDERER');
elseif strcmp(option, 'textonly')
    com.mathworks.mlwidgets.html.HtmlComponentFactory.setDefaultType('DUMMY');     
elseif strcmp(option, 'default')
    com.mathworks.mlwidgets.html.HtmlComponentFactory.setDefaultType(' ');
else
    fprintf('Option ''%s'' not recognized.\n', option);
    success = 0;
    return;
end

fprintf('Your HTML rendering engine is now set to ''%s''.\n', option);
