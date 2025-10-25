function o = rdivide(x,y)
% ./  Right array quaternion divide.
%    X./Y denotes element-by-element division. This is equivalent to X
%    right-multiplied by the inverse of Y. Either X or Y may be quaternions.
%    The operation uses quaternion multiplication and quaternion inverse as
%    appropriate.
%
%    X and Y must have compatible sizes. In the simplest cases, they can be
%    the same size or one can be a scalar. Two inputs have compatible sizes
%    if, for every dimension, the dimension sizes of the inputs are either
%    the same or one of them is 1.
% 
%    C = rdivide(X,Y) is called for the syntax 'X ./ Y' when X or Y is a
%    quaternion.

%   Copyright 2018-2021 The MathWorks, Inc.    

%#codegen 

% Honor user request for implicit expansion
coder.internal.implicitExpansionBuiltin;

% Ensure compatible dims, else throw a proper error.
quatAssertCompatibleDims(x,y);

    if isa(y, 'matlabshared.rotations.internal.quaternionBase') && isa(x, 'matlabshared.rotations.internal.quaternionBase')
        xa = x.a;
        xb = x.b;
        xc = x.c;
        xd = x.d;
        
        ya = y.a;
        yb = -y.b;
        yc = -y.c;
        yd = -y.d;

        % y = inv(y)
        n =  ya.^2 + yb.^2 + yc.^2 + yd.^2;
        ya = ya./n;
        yb = yb./n;
        yc = yc./n;
        yd = yd./n;
       

        oa = xa.*ya - xb.*yb - xc.*yc - xd.*yd;
        ob = xa.*yb + xb.*ya + xc.*yd - xd.*yc;
        oc = xa.*yc - xb.*yd + xc.*ya + xd.*yb;
        od = xa.*yd + xb.*yc - xc.*yb + xd.*ya;
        o = matlabshared.rotations.internal.coder.quaternioncg(oa,ob,oc,od);

    elseif (isa(y, 'double') || isa(y, 'single')) && isreal(y) && ...
            isa(x, 'matlabshared.rotations.internal.quaternionBase')
        oa = x.a./y;
        ob = x.b./y;
        oc = x.c./y;
        od = x.d./y;
        o = matlabshared.rotations.internal.coder.quaternioncg(oa,ob,oc,od);

    elseif (isa(x, 'double') || isa(x, 'single')) && isreal(x) && ...
            isa(y, 'matlabshared.rotations.internal.quaternionBase')
        ya = y.a;
        yb = -y.b;
        yc = -y.c;
        yd = -y.d;

        % y = inv(y)
        n =  ya.^2 + yb.^2 + yc.^2 + yd.^2;
        ya = ya./n;
        yb = yb./n;
        yc = yc./n;
        yd = yd./n;

        oa = x.*ya;
        ob = x.*yb;
        oc = x.*yc;
        od = x.*yd;
        o = matlabshared.rotations.internal.coder.quaternioncg(oa,ob,oc,od);
    else
        coder.internal.errorIf(true, 'shared_rotations:quaternion:QuatDivReals');
    end
end
