function Bounds = getBounds(this)
%getBounds  Data update method for bounds

%   Author(s): Craig Buhr
%   Copyright 1986-2010 The MathWorks, Inc.

if isempty(this.Bounds) || isempty(this.Bounds.UpperAmplitudeBound)
    computeBounds(this)
end

Bounds = this.Bounds;


