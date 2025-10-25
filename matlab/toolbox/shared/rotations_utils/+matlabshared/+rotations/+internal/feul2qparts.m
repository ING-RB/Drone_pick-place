function [qa,qb,qc,qd] = feul2qparts(ein, rot)
%   This function is for internal use only. It may be removed in the future.

%FEUL2QPARTS - Quaternion Parts From Euler Angles
% DO NOT EDIT. This file was auto-generated using EulerConvBase

%   Copyright 2017-2024 The MathWorks, Inc.

%#codegen

ein = ein./2;
a = ein(:,1);
b = ein(:,2);
c = ein(:,3);

found = true;
switch upper(rot)
    case 'YZY'
        sinb = sin(b);
        cosb = cos(b);
        qa = cosb.*cos(a + c);
        qb = sinb.*sin(a - c);
        qc = cosb.*sin(a + c);
        qd = sinb.*cos(a - c);
    case 'YXY'
        sinb = sin(b);
        cosb = cos(b);
        qa = cosb.*cos(a + c);
        qb = sinb.*cos(a - c);
        qc = cosb.*sin(a + c);
        qd = -sinb.*sin(a - c);
    case 'ZYZ'
        sinb = sin(b);
        cosb = cos(b);
        qa = cosb.*cos(a + c);
        qb = -sinb.*sin(a - c);
        qc = sinb.*cos(a - c);
        qd = cosb.*sin(a + c);
    case 'ZXZ'
        sinb = sin(b);
        cosb = cos(b);
        qa = cosb.*cos(a + c);
        qb = sinb.*cos(a - c);
        qc = sinb.*sin(a - c);
        qd = cosb.*sin(a + c);
    case 'XYX'
        sinb = sin(b);
        cosb = cos(b);
        qa = cosb.*cos(a + c);
        qb = cosb.*sin(a + c);
        qc = sinb.*cos(a - c);
        qd = sinb.*sin(a - c);
    case 'XZX'
        sinb = sin(b);
        cosb = cos(b);
        qa = cosb.*cos(a + c);
        qb = cosb.*sin(a + c);
        qc = -sinb.*sin(a - c);
        qd = sinb.*cos(a - c);
    case 'XYZ'
        sina = sin(a);
        sinb = sin(b);
        sinc = sin(c);
        cosa = cos(a);
        cosb = cos(b);
        cosc = cos(c);
        qa = cosa.*cosb.*cosc - sina.*sinb.*sinc;
        qb = cosb.*cosc.*sina + cosa.*sinb.*sinc;
        qc = cosa.*cosc.*sinb - cosb.*sina.*sinc;
        qd = cosa.*cosb.*sinc + cosc.*sina.*sinb;
    case 'YZX'
        sina = sin(a);
        sinb = sin(b);
        sinc = sin(c);
        cosa = cos(a);
        cosb = cos(b);
        cosc = cos(c);
        qa = cosa.*cosb.*cosc - sina.*sinb.*sinc;
        qb = cosa.*cosb.*sinc + cosc.*sina.*sinb;
        qc = cosb.*cosc.*sina + cosa.*sinb.*sinc;
        qd = cosa.*cosc.*sinb - cosb.*sina.*sinc;
    case 'ZXY'
        sina = sin(a);
        sinb = sin(b);
        sinc = sin(c);
        cosa = cos(a);
        cosb = cos(b);
        cosc = cos(c);
        qa = cosa.*cosb.*cosc - sina.*sinb.*sinc;
        qb = cosa.*cosc.*sinb - cosb.*sina.*sinc;
        qc = cosa.*cosb.*sinc + cosc.*sina.*sinb;
        qd = cosb.*cosc.*sina + cosa.*sinb.*sinc;
    case 'XZY'
        sina = sin(a);
        sinb = sin(b);
        sinc = sin(c);
        cosa = cos(a);
        cosb = cos(b);
        cosc = cos(c);
        qa = cosa.*cosb.*cosc + sina.*sinb.*sinc;
        qb = cosb.*cosc.*sina - cosa.*sinb.*sinc;
        qc = cosa.*cosb.*sinc - cosc.*sina.*sinb;
        qd = cosa.*cosc.*sinb + cosb.*sina.*sinc;
    case 'ZYX'
        sina = sin(a);
        sinb = sin(b);
        sinc = sin(c);
        cosa = cos(a);
        cosb = cos(b);
        cosc = cos(c);
        qa = cosa.*cosb.*cosc + sina.*sinb.*sinc;
        qb = cosa.*cosb.*sinc - cosc.*sina.*sinb;
        qc = cosa.*cosc.*sinb + cosb.*sina.*sinc;
        qd = cosb.*cosc.*sina - cosa.*sinb.*sinc;
    case 'YXZ'
        sina = sin(a);
        sinb = sin(b);
        sinc = sin(c);
        cosa = cos(a);
        cosb = cos(b);
        cosc = cos(c);
        qa = cosa.*cosb.*cosc + sina.*sinb.*sinc;
        qb = cosa.*cosc.*sinb + cosb.*sina.*sinc;
        qc = cosb.*cosc.*sina - cosa.*sinb.*sinc;
        qd = cosa.*cosb.*sinc - cosc.*sina.*sinb;
    otherwise
        found = false;
        qa = zeros(size(a), "like", a);
        qb = zeros(size(a), "like", a);
        qc = zeros(size(a), "like", a);
        qd = zeros(size(a), "like", a);
end
coder.internal.assert(found, 'shared_rotations:quaternion:NoSeqConv', rot);
end
