function NotSupportedInWebAppServer(feature)
% NotSupportedInWebAppServer helper function for internal use only 
% which throws the error msg for un-supported functions in deployed web
% apps

%   Copyright 2020 The MathWorks, Inc.

s = settings;
if (s.matlab.ui.figure.ShowInWebApps.ActiveValue || ...
   (isdeployed && matlab.internal.environment.context.isWebAppServer))
      % alert the user of the error and throw a MATLAB exception that will show up in the log

      % get the first figure created in which to display the uialert
      % in case the app has managed to create one or more others
      appFigure = allchild(groot);
      len = length(appFigure);
      if len > 1
          appFigure = appFigure(len);
      end

      % display msg to user only if there is actually a figure in which to display it
      if len > 0
          msg = message('MATLAB:ui:uifigure:AppEncounteredAnError').getString;
          %g2253331: show exception from the log also in the pop-up window
          msg = [msg newline message('MATLAB:ui:uifigure:UnsupportedWebAppsFunctionality', feature).getString];
          uialert(appFigure, msg, 'Error', 'Icon', 'error');
      end

      throwAsCaller(MException(message('MATLAB:ui:uifigure:UnsupportedWebAppsFunctionality', feature)));
end

end

