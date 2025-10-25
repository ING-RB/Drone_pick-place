function obj = parenAssign(obj,rhs,varargin)
%   This method  is for internal use only. It may be removed in the future. 

% Implements OBJ(I) = RHS

%   Copyright 2018 The MathWorks, Inc.    


if (isa(obj,'double') && isempty(obj))
    %Building a new array. obj is unassigned.
    if isscalar(varargin)
        varargin = [ {1},varargin ];  %single index makes a row vector
    end
    qa(varargin{:}) = rhs.a;
    qb(varargin{:}) = rhs.b;
    qc(varargin{:}) = rhs.c;
    qd(varargin{:}) = rhs.d;
    obj = rhs.ctor(qa,qb,qc,qd);
elseif isempty(rhs)
    %deletion
    obj.a(varargin{:}) = [  ];
    obj.b(varargin{:}) = [  ];
    obj.c(varargin{:}) = [  ];
    obj.d(varargin{:}) = [  ];
else
    coder.internal.assert(isa(rhs,'quaternion'),'shared_rotations:quaternion:QuatRHS');
    obj.a(varargin{:}) = rhs.a;
    obj.b(varargin{:}) = rhs.b;
    obj.c(varargin{:}) = rhs.c;
    obj.d(varargin{:}) = rhs.d;
end
end
