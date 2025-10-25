function o = ldivide(x,y)
%.\  Left array divide.
%    X.\Y denotes element-by-element division. This is equivalent to Y
%    left-multiplied by the inverse of X. Either X or Y may be quaternions.
%    The operation uses quaternion multiplication and quaternion inverse as
%    appropriate.
%
%    X and Y must have compatible sizes. In the simplest cases, they can be
%    the same size or one can be a scalar. Two inputs have compatible sizes
%    if, for every dimension, the dimension sizes of the inputs are either
%    the same or one of them is 1.
% 
%    C = ldivide(X,Y) is called for the syntax 'X .\ Y' when X or Y is a
%    quaternion.

%   Copyright 2018 The MathWorks, Inc.    





    if isa(y, 'matlabshared.rotations.internal.quaternionBase') && ...
            isa(x, 'matlabshared.rotations.internal.quaternionBase')
        ya = y.a;
        yb = y.b;
        yc = y.c;
        yd = y.d;
        
        xa = x.a;
        xb = -x.b;
        xc = -x.c;
        xd = -x.d;

        % x = inv(x)
        n =  xa.^2 + xb.^2 + xc.^2 + xd.^2;
        xa = xa./n;
        xb = xb./n;
        xc = xc./n;
        xd = xd./n;
       

        x.a = xa.*ya - xb.*yb - xc.*yc - xd.*yd;
        x.b = xa.*yb + xb.*ya + xc.*yd - xd.*yc;
        x.c = xa.*yc - xb.*yd + xc.*ya + xd.*yb;
        x.d = xa.*yd + xb.*yc - xc.*yb + xd.*ya;
        o = x;
    elseif (isa(y, 'double') || isa(y, 'single')) && isreal(y) && ...
            isa(x, 'matlabshared.rotations.internal.quaternionBase')

        xa = x.a;
        xb = -x.b;
        xc = -x.c;
        xd = -x.d;

        % x = inv(x)
        n =  xa.^2 + xb.^2 + xc.^2 + xd.^2;
        xa = xa./n;
        xb = xb./n;
        xc = xc./n;
        xd = xd./n;

        x.a = y.*xa;
        x.b = y.*xb;
        x.c = y.*xc;
        x.d = y.*xd;
        o = x;
    elseif (isa(x, 'double') || isa(x, 'single')) && isreal(x) && ...
            isa(y, 'matlabshared.rotations.internal.quaternionBase')
        y.a = y.a./x;
        y.b = y.b./x;
        y.c = y.c./x;
        y.d = y.d./x;
        o = y;
    else
        coder.internal.errorIf(true, 'shared_rotations:quaternion:QuatDivReals');
    end
end
