function y = vertcat(obj, varargin)
%VERTCAT Vertical concatenation of quaternion arrays
%   C = VERTCAT(A,B,...) implements [A; B; ...] for quaternions

%   Copyright 2018 The MathWorks, Inc.    

%#codegen 
    
   %Validate
   n = numel(varargin);
   coder.internal.assert(isa(obj, 'matlabshared.rotations.internal.quaternionBase'), ...
       'shared_rotations:quaternion:AllQuat');
   for ii=1:n
       coder.internal.assert(isa(varargin{ii},'matlabshared.rotations.internal.quaternionBase'), ...
           'shared_rotations:quaternion:AllQuat');

   end
   %Get parts
   qa = cell(1,n);
   qb = cell(1,n);
   qc = cell(1,n);
   qd = cell(1,n);
   for ii=1:numel(varargin)
       qa{ii} = varargin{ii}.a;
       qb{ii} = varargin{ii}.b;
       qc{ii} = varargin{ii}.c;
       qd{ii} = varargin{ii}.d;
   end
   %Concat:
   ya = vertcat(obj.a, qa{:});
   yb = vertcat(obj.b, qb{:});
   yc = vertcat(obj.c, qc{:});
   yd = vertcat(obj.d, qd{:});
   
   y = quaternion(ya,yb,yc,yd);
end 
