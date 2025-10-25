function disableRotate3D(this)
%DISABLEROTATE3D  Disable Rotate3D behavior property for axes in Axesgrid

%  Author(s): C. Buhr
%  Copyright 1986-2004 The MathWorks, Inc.

% Disable Rotation for axes
bh = hgbehaviorfactory('Rotate3D');
set(bh,'Enable',false);
hgaddbehavior(this.Axes2d(:),bh);
