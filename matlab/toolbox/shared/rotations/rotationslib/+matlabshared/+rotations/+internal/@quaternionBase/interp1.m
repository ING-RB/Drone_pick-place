function intp = interp1(x,v,xq,method,extrapval)
%INTERP1 - 1-D data interpolation (table lookup)
%	This MATLAB function returns the interpolated values of a 1-D function at 
%	specific query points.

%   Copyright 2024 The MathWorks, Inc.    
    
%#codegen

    narginchk(2, 5);

    % create the interpolant object 
    ri = matlabshared.rotations.internal.interpolation.rotationalInterpolant;

    if isa(x, 'quaternion')
        % interp1(q, xquery,....)
        vlut = ri.validateVLut(x,  'interp1', 'v');
        xlut = ri.createXLut(vlut);
        query = ri.validateQuery(v, 'interp1', 'xq');

        if nargin > 2
            coder.internal.prefer_const(xq);
            coder.internal.assert(coder.internal.isConst(xq), ...
                'shared_rotations:interpolation:MethodMustBeConstant');
            ri.validateMethod(xq, 'interp1', 'method');
            alg = xq;
        else
            alg = ri.defaultMethod;
        end

        if nargin > 3
            ev = ri.validateExtrapVal(method, 'interp1', 'extrapval');
        else
            ev = quaternion.nan(1,1, "like", query);
        end

    else
        % interp1(x, q, xquery,....)
        xlut = ri.validateXLut(x, 'interp1', 'x');
        vlut = ri.validateVLut(v, 'interp1', 'v');
        query = ri.validateQuery(xq, 'interp1', 'xq');

        % crossvalidate x and v
        ri.crossvalidateLut(xlut, vlut);

        if nargin > 3
            coder.internal.prefer_const(method);
            coder.internal.assert(coder.internal.isConst(method), ...
                'shared_rotations:interpolation:MethodMustBeConstant');
            ri.validateMethod(method, 'interp1', 'method');
            alg = method;
        else
            alg = ri.defaultMethod;
        end

        if nargin > 4
            ev = ri.validateExtrapVal(extrapval, 'interp1', 'extrapval');
        else
            ev = quaternion.nan(1,1, "like", query);
        end

    end
    ri = ri.setInterpolator(coder.const(alg));
    ri = ri.setExtrapVal(ev);
    ri = ri.setLut(xlut, vlut);
    intp = ri.interpolate(query);
end

