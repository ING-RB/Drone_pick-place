function tf = isFigureAvailable
% This undocumented function may be removed in a future release.

% ISFIGUREAVAILABLE determines if figure windows can be created in the
% running instance of MATLAB.

%   Copyright 2010-2022 The MathWorks, Inc.

if ~parallel.internal.pool.isPoolWorker() && ...
        matlab.ui.internal.hasDisplay && matlab.ui.internal.isFigureShowEnabled
    tf = true;
else
    tf = false;
end
