classdef  (Hidden = true) quaternionBase < matlab.mixin.internal.indexing.Paren & ...
        matlab.mixin.internal.indexing.ParenAssign
    %QUATERNIONBASE - Base class for quaternion and quaternioncg
    %   This class is for internal use only. It may be removed in the future.
    %
    
    %   Copyright 2017-2024 The MathWorks, Inc.

    %#codegen

    properties  (Access = protected)
        %Quaternion parts
        a
        b
        c
        d
    end

    methods
        function obj = quaternionBase(arg1,  arg2, arg3, arg4)
            switch nargin
                case 0
                    %quaternion()
                    obj.a = [];
                    obj.b = [];
                    obj.c = [];
                    obj.d = [];

                case 1
                    if isa(arg1, 'matlabshared.rotations.internal.quaternionBase')
                    %quaternion(q)  - copy constructor
                        obj = arg1;
                    else
                        if coder.internal.isConstTrue(isequal(size(arg1), [0 0]))
                        %quaternion([])
                        % This handles the explicit case of [] or known
                        % (codegen constant) 0x0. Just assign empties
                        % to each part.
                            obj.a = arg1;
                            obj.b = arg1;
                            obj.c = arg1;
                            obj.d = arg1;
                        else
                        %quaternion([1 2 3 4])
                        % This branch handles N-by-4 in sim.
                        % In codegen ?x? and ?x4 will get here. ?x4 will go
                        % through and produce a varsize quaternion. ?x?
                        % will throw an error at runtime if the columns are
                        % not equal to 4.
                            validateattributes(arg1, {'double', 'single'}, ...
                                {'real', '2d', 'ncols', 4}, 'quaternionBase');
                            obj.a = arg1(:,1);
                            obj.b = arg1(:,2);
                            obj.c = arg1(:,3);
                            obj.d = arg1(:,4);
                        end
                    end
                case 2
                    localAssert(ischar(arg2) || isStringScalar(arg2), 'shared_rotations:quaternion:Constructor4Inputs')
                    [obj.a,obj.b,obj.c,obj.d] = partsFromConversion(arg1, arg2);
                   
                case 3
                    localAssert(ischar(arg2) || isStringScalar(arg2), 'shared_rotations:quaternion:Constructor4Inputs')
                    [obj.a,obj.b,obj.c,obj.d] = partsFromConversion(arg1, arg2, arg3);
                   
                otherwise  % 4 inputs
                    if ischar(arg2) || isstring(arg2)
                    % Conversion constructors - euler, eulerd, rotvec, rotvecd, rotmat
                        [obj.a,obj.b,obj.c,obj.d] = partsFromConversion(arg1, arg2, arg3, arg4);
                                   
                    else %quaternion(1,1,1,1)
                        [arg1,arg2,arg3,arg4] = processFourInputConst(arg1, arg2, arg3, arg4);             
                        obj.a = arg1;
                        obj.b = arg2;
                        obj.c = arg3;
                        obj.d = arg4;
                    end
            end
        end
    end    

    methods 
        y = cat(dim, varargin)
        y = horzcat(obj, varargin)
        y = vertcat(obj, varargin)
        tf = ismatrix(obj)
        tf = isscalar(obj)
        tf = isvector(obj)
        tf = isrow(obj)
        tf = iscolumn(obj)
        tf = isempty(obj)
        n = numel(obj)
        n = ndims(obj)
        l = length(obj)
        varargout = size(obj, varargin)
        r = plus(q1, q2)
        r = minus(q1, q2)
        obj = uminus(obj)
        o = mtimes(x,y)
        o = mrdivide(x,y)
        o = mldivide(x,y)
        q = conj(q)
        p = prod(q, varargin)
        c = classUnderlying(q)
        c = underlyingType(q)
        tf = eq(q,p)
        ip = interp1(x,q,xquery,method,extrap)
        tf = isnan(q)
        tf = isequal(varargin)
        tf = isequaln(varargin)
        tf = isfinite(q)
        tf = isinf(q)
        q = normalize(q)
        n = norm(q)
        u = rotatepoint(q,v)
        u = rotateframe(q,v)
        [w,x,y,z] = parts(q)
        m = compact(q)
        rv = rotvec(q)
        rvd = rotvecd(q)
        a = euler(q, seq, pf)
        a = eulerd(q, seq, pf)
        r = rotmat(q, pf)
        x = dist(q,p)
        validateattributes(obj, varargin)
        tf = ne(p,q)
        qexp = exp(q)
        qlog = log(q)
        qavg = meanrot(q, varargin)
        s = slerp(q1, q2, h, opt)
        [av, qf] = angvel(q, dt, pf, varargin)
    end

    methods (Abstract, Static)
        o = zeros(varargin)
        o = ones(varargin)
        o = nan(varargin)
    end

    methods (Abstract, Hidden)
        o = ctor(obj, varargin) %A way to call the subclass constructor
    end

    methods (Hidden)
        e = end(obj,k,n)
        x = castLike(obj, a)
        o = zerosLike(obj, varargin)
        q = onesLike(obj, varargin)
        q = nanLike(obj, varargin)
        quatAssertCompatibleDims(x,y) % for codegen but accessible in sim
    end

    methods (Access = protected, Abstract)
        q = buildOutput(q,a,b,c,d)
    end

    methods (Access = protected)
        tf = binaryIsEqual(q,p)
        tf = binaryIsEqualn(q,p)
    end

end

function [qa,qb,qc,qd] = partsFromConversion(arg1, arg2, arg3, arg4)
% quaternion parts from a conversion constructor - euler,eulerd, rotvec,rotvecd, rotmat
  
    n = nargin;

    valid = true;
    switch(lower(arg2))
        case 'rotvec'
           %quaternion(r, 'rotvec')
            coder.internal.assert(n==2, 'shared_rotations:quaternion:QuatRotvecConv');
            [qa,qb,qc,qd] = partsFromRotvec(arg1);

        case 'rotvecd'
            % quaternion(r, 'rotvecd')
            coder.internal.assert(n==2, 'shared_rotations:quaternion:QuatRotvecdConv');
            [qa,qb,qc,qd] = partsFromRotvecd(arg1);

        case 'rotmat'
            %quaternion(R, 'rotmat', 'point')
            %quaternion(R, 'rotmat', 'frame')
            coder.internal.assert(n ==3,'shared_rotations:quaternion:QuatRotmatConv');
            [qa,qb,qc,qd] = partsFromRotmat(arg1,arg2,arg3);

        case 'euler'
            %quaternion(e, 'euler', 'XYZ', 'point')
            %quaternion(e, 'euler', 'XYZ', 'frame')
            coder.internal.assert(n==4,'shared_rotations:quaternion:QuatEulerConv');        
            [qa,qb,qc,qd] = partsFromEuler(arg1,arg2,arg3,arg4);

        case 'eulerd'
            %quaternion(e, 'eulerd', 'XYZ', 'point')
            %quaternion(e, 'eulerd', 'XYZ', 'frame')
            coder.internal.assert(n==4,'shared_rotations:quaternion:QuatEulerdConv');
            [qa,qb,qc,qd] = partsFromEulerd(arg1,arg2,arg3,arg4);

        otherwise
            valid= false;
            qa = [];
            qb = [];
            qc = [];
            qd = [];
            %unexpected conversion string.
    end
    coder.internal.assert(valid, 'shared_rotations:quaternion:QuatUnexpectedConv');
end

function [qa,qb,qc,qd] = partsFromRotvec(arg1)
% Validate inputs for rotvec conversion and produce quaternion parts
    validateattributes(arg1, {'single', 'double'}, {'real', 'ncols', 3, '2d'}, ...
        'quaternionBase');
    [qa,qb,qc,qd] = matlabshared.rotations.internal.rotvec2qparts(arg1);
end

function [qa,qb,qc,qd] = partsFromRotvecd(arg1)
% Validate inputs for rotvecd conversion and produce quaternion parts
    validateattributes(arg1, {'single', 'double'}, {'real', 'ncols', 3, '2d'}, ...
        'quaternionBase');
    [qa,qb,qc,qd] = matlabshared.rotations.internal.rotvec2qparts(deg2rad(arg1));
end

function [qa,qb,qc,qd] = partsFromRotmat(arg1,arg2,arg3)
% Validate inputs for rotmat conversion and produce quaternion parts
    coder.internal.errorIf((isa(arg1, 'double') || isa(arg1, 'single')) && (isa(arg2, 'double') || isa(arg2, 'single')) && (isa(arg3, 'double') || isa(arg3, 'single')), ...
        'shared_rotations:quaternion:Constructor4Inputs');
    coder.internal.assert(strcmpi(arg2, 'rotmat'), 'shared_rotations:quaternion:QuatRotmatConv');
    
    validateattributes(arg1, {'double', 'single'}, ...
        {'real', 'ncols', 3, 'nrows', 3}, 'quaternionBase');
    coder.internal.assert(ndims(arg1) < 4, ...
        'shared_rotations:quaternion:RotmatDims');
    
    switch arg3
        case 'point'
            [qa,qb,qc,qd] = matlabshared.rotations.internal.frotmat2qparts(permute(arg1, [2 1 3]));
            found = true;
        case 'frame'
            [qa,qb,qc,qd] = matlabshared.rotations.internal.frotmat2qparts(arg1);
            found = true;
        otherwise
            n = size(arg1, 3);
            qa = zeros(n,1, "like", arg1);
            qb = zeros(n,1, "like", arg1);
            qc = zeros(n,1, "like", arg1);
            qd = zeros(n,1, "like", arg1);
            found = false;
    end
    coder.internal.assert(found, 'shared_rotations:quaternion:QuatRotmatConv');
end

function [qa,qb,qc,qd] = partsFromEuler(arg1,arg2,arg3,arg4)
% Validate inputs for euler conversion and produce quaternion parts
    if ~(isa(arg2, 'double') || isa(arg2, 'single'))
        coder.internal.assert(strcmpi(arg2, 'euler'), 'shared_rotations:quaternion:QuatEulerConv');
        
        validateattributes(arg1, {'double', 'single'}, ...
            {'real', '2d', 'ncols', 3}, 'quaternionBase');
        switch lower(arg4)
            case 'point'
                %flip arguments for point.
                arg3c = char(arg3);
                r3 = [arg3c(3) arg3c(2) arg3c(1)];
                [qa, qb, qc, qd] = ...
                    matlabshared.rotations.internal.feul2qparts(fliplr(arg1), r3);
                found = true;
            case 'frame'
                [qa, qb, qc, qd] = ...
                    matlabshared.rotations.internal.feul2qparts(arg1, arg3);
                found = true;
            otherwise
                found = false;
                n = size(arg1, 1);
                qa = zeros(n,1, "like", arg1);
                qb = zeros(n,1, "like", arg1);
                qc = zeros(n,1, "like", arg1);
                qd = zeros(n,1, "like", arg1);
        end
        coder.internal.assert(found, 'shared_rotations:quaternion:QuatEulerConv');
        
    end

end

function [qa,qb,qc,qd] = partsFromEulerd(arg1,arg2,arg3,arg4)
% Validate inputs for eulerd conversion and produce quaternion parts
    if ~(isa(arg2, 'double') || isa(arg2, 'single'))
        coder.internal.assert(strcmpi(arg2, 'eulerd'), 'shared_rotations:quaternion:QuatEulerdConv');
        
        validateattributes(arg1, {'double', 'single'}, ...
            {'real', '2d', 'ncols', 3}, 'quaternionBase');

        arg1 = deg2rad(arg1);
        switch lower(arg4)
            case 'point'
                %flip arguments for point.
                arg3c = char(arg3);
                r3 = [arg3c(3) arg3c(2) arg3c(1)];
                [qa, qb, qc, qd] = ...
                    matlabshared.rotations.internal.feul2qparts(fliplr(arg1), r3);
                found = true;
            case 'frame'
                [qa, qb, qc, qd] = ...
                    matlabshared.rotations.internal.feul2qparts(arg1, arg3);
                found = true;
            otherwise
                found = false;
                n = size(arg1, 1);
                qa = zeros(n,1, "like", arg1);
                qb = zeros(n,1, "like", arg1);
                qc = zeros(n,1, "like", arg1);
                qd = zeros(n,1, "like", arg1);
        end
        coder.internal.assert(found, 'shared_rotations:quaternion:QuatEulerdConv');
    end
end

function [arg1,arg2,arg3,arg4] = processFourInputConst(arg1, arg2, arg3, arg4)
% Validate inputs for quaternion(1,2,3,4) syntax. Produce quaternion parts.
    localAssert(isa(arg2, class(arg1)) && isa(arg3, class(arg1)) && isa(arg4, class(arg1)), 'shared_rotations:quaternion:SameClass');
    localAssert(isreal(arg1) && isreal(arg2) && isreal(arg3) && isreal(arg4), 'shared_rotations:quaternion:MustBeReal');
    localAssert(isequal(size(arg1), size(arg2), size(arg3), size(arg4)), 'shared_rotations:quaternion:SameSize');
    localAssert((isa(arg1, 'double') || isa(arg1, 'single')), 'shared_rotations:quaternion:SameClass');
end

function localAssert(cond, msg)
if ~cond
    coder.internal.assert(cond, msg)
end
end
