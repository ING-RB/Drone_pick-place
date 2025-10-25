function [av, qf] = privangvel(q, dt, pf, varargin)
%PRIVANGVEL angvel implementation, as a function
%   This function is for internal use only. It may be removed in the
%   future.

%   Copyright 2019-2024 The MathWorks, Inc.

%#codegen

narginchk(3,4);

[isFrame, qi] = parseargs(q, dt, pf, varargin{:});
qi = normalize(qi);
q = normalize(q);

qin = [qi; q(:)];

if isFrame
    qdiff = qin(2:end,:) .* conj(qin(1:end-1,:));
else
    qdiff = conj(qin(1:end-1,:)) .* qin(2:end,:);
end
qav = compact( cast(2 / dt, "like", dt) .* qdiff );
% Extract angular velocities and negate the sign if the real part of the
% quaternion is negative.
av = sign(qav(:,1)) .* qav(:,2:4);

qf = qin(end,:);
end

function [isFrame, qi] = parseargs(q, dt, pf, qi)

validateattributes(q, {'quaternion'}, {'column'}, '', 'q');
validateattributes(dt, {'double', 'single'}, ...
    {'real', 'positive', 'finite', 'scalar'}, '', 'dt');
isFrame = true;
found = true;
switch lower(pf)
    case 'frame'
        isFrame = true;
    case 'point'
        isFrame = false;
    otherwise
        found = false;
end
coder.internal.assert(found,'shared_rotations:quaternion:QuatPointFrame');
if nargin < 4
    qi = quaternion.ones(1,1, "like", dt);
end
validateattributes(qi, {'quaternion'}, {'scalar'}, '', 'qi');
end
