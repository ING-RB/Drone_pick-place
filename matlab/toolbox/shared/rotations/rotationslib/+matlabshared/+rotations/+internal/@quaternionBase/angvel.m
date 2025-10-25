function [av, qf] = angvel(q, dt, pf, varargin)
%ANGVEL Angular velocity from quaternion array
%   AV = ANGVEL(Q, DT, 'frame') returns an N-by-3 array of angular
%   velocities AV in radians per second from the N-by-1 quaternion vector Q
%   and the delta time DT between each quaternion in seconds. The angular
%   velocities are calculated from quaternions that  represent frame
%   rotations.
%
%   AV = ANGVEL(Q, DT, 'point') returns an N-by-3 array of angular
%   velocities AV in radians per second from the N-by-1 quaternion vector Q
%   and the delta time DT between each quaternion in seconds. The angular
%   velocities are calculated from quaternions that  represent point
%   rotations.
%
%   [AV, QF] = ANGVEL(Q, DT, PF, QI) gives access to initial and final
%   quaternions, QI and QF. QI is a scalar quaternion.
%
%   Example:
%       % Create an angular velocity array from a quaternion array.
%       eulerAngs = [(0:10:90).', zeros(numel(0:10:90), 2)];
%       q = quaternion(eulerAngs, 'eulerd', 'ZYX', 'frame');
%       dt = 1;
%       av = angvel(q, dt, 'frame');
%
%   See also dist, conj, slerp

%   Copyright 2019 The MathWorks, Inc.    

%#codegen 

[av, qf] = matlabshared.rotations.internal.privangvel(q, dt, pf, ...
    varargin{:});
end
