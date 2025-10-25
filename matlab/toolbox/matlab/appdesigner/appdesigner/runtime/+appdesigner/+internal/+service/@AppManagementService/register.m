function register(obj, app, uiFigure)
%

%   Copyright 2024 The MathWorks, Inc.

    validateattributes(app, {'matlab.apps.AppBase' 'matlab.apps.App'}, {});

    obj.manageApp(app, uiFigure);
end
