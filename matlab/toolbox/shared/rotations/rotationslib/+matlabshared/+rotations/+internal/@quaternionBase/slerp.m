function qo = slerp(q1, q2, t, opt)
%SLERP - Spherical Linear Interpolation
%  QO = SLERP(Q1,Q2,T) spherically interpolates between Q1 and Q2 by the
%  interpolation coefficient T. T is a single or double precision number
%  between 0 and 1, inclusive.  The inputs Q1, Q2, and T must have
%  compatible sizes. In the simplest cases, they can be the same size or
%  any one can be a scalar.  Two inputs have compatible sizes if, for every
%  dimension, the dimension sizes of the inputs are either the same or one
%  of them is 1.
%  
%  QO = SLERP(Q1,Q2,T,OPT) specifies if a shortest path optimization should
%  be used. If OPT is set to 'short' then the interpolated values will be
%  along the shortest path on the great circle between Q1 and Q2. If OPT is
%  set to 'natural' the shortest path optimization is skipped, and the
%  natural path between Q1 and Q2 will be used for interpolation. For
%  'natural' the path depends on the dot product of Q1 and Q2. The default
%  is 'short'.
%
%  Example:
%     q = quaternion([40 20 10; 50 10 5], 'eulerd', 'ZYX', 'frame');
%     qs = slerp(q(1), q(2), 0.7);
%     eulerd(qs, 'ZYX', 'frame')
%
%   See also QUATERNION, MEANROT

%   Copyright 2018-2024 The MathWorks, Inc.

%q1 and q2 and t must be compatible sizes and vectors

%#codegen

arguments
    q1 {mustBeA(q1,'quaternion')}
    q2 {mustBeA(q2,'quaternion')}
    t {mustBeA(t, {'double', 'single'}), mustBeGreaterThanOrEqual(t,0), ...
        mustBeLessThanOrEqual(t,1), mustBeReal(t), ...
        mustBeNonsparse(t)}
    opt {mustBeMember(opt, {'short', 'natural'})} = 'short';
end
% Honor user request for implicit expansion
coder.internal.implicitExpansionBuiltin;

% For codegen implicit expansion, ensure compatible dims, else throw a proper error.
quatAssertCompatibleDims(q1, q2);
quatAssertCompatibleDims(q2, t);
quatAssertCompatibleDims(t, q1);

optbool = strcmpi(opt, 'short'); % use the shortest path optimization

% Normalize and expand
q1normed = normalize(q1);
q2normed = normalize(q2);

if isscalar(q1) && isscalar(q2)
    q1n = q1normed;
    q2n = q2normed;
else
    q1n = q1normed .* ones(size(q2), "like", q2);
    q2n = q2normed .* ones(size(q1), "like", q1);
end

% to use indexing, put in a private function (i.e. not a class member)
qo = matlabshared.rotations.internal.privslerp(q1n,q2n,t, optbool);
