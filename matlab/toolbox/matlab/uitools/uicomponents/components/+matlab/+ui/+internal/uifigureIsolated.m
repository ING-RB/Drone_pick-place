function fig = uifigureIsolated(varargin)
% Implementation of uifigure creation

% Copyright 2024 The MathWorks, Inc.

    fig = matlab.ui.internal.uifigureImpl(true, varargin{:});

end
