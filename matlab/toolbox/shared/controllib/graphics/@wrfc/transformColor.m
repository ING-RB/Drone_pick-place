function NewColor = transformColor(Color,Alpha)
%transformColor  Transforms color to make it a lighter shade of same color.
%
%  used to compute new color of shaded lines/patches for uncertainty type
%  bounds

%  Author(s): Craig Buhr
%  Copyright 1986-2010 The MathWorks, Inc.

if nargin == 1
    % Default Value
    Alpha = .25;
end
NewColor = Color+(1-Color)*(1-Alpha);
