function eout = qparts2feul(qa,qb,qc,qd,rot)
%   This function is for internal use only. It may be removed in the future.

%QPARTS2FEUL - Euler angles from quaternion parts
% DO NOT EDIT. This file was auto-generated using EulerConvBase

%   Copyright 2017-2024 The MathWorks, Inc.

%#codegen

%columnize quaternion parts
qa = qa(:);
qb = qb(:);
qc = qc(:);
qd = qd(:);
the1 = ones(1, "like", qa); % single(1) or double(1) as appropriate
the2 = 2*the1; % single(2) or double(2) as appropriate
a = zeros(size(qa), "like", qa);
b = zeros(size(qb), "like", qb);
c = zeros(size(qc), "like", qc);

found = true;
switch upper(rot)
    case 'YZY'
        tmp = qa.^2.*the2 - the1 + qc.^2.*the2;
        tmp(tmp > the1) = the1;
        tmp(tmp < -the1) = -the1;
        for ii=1:numel(tmp)
            if (tmp(ii) < 0) && abs(tmp(ii) + 1) < 10*eps(the1)
                a(ii) = 2.*atan2(qb(ii),qd(ii));
                c(ii) = 0;
                b(ii) = cast(pi, "like", tmp);
            elseif (tmp(ii) > 0) && abs(tmp(ii) - 1) < 10*eps(the1)
                a(ii) = 2.*atan2(qc(ii),qa(ii));
                c(ii) = 0;
                b(ii) = cast(0, "like", tmp);
            else
                a(ii) = atan2((qa(ii).*qb(ii).*the2 + qc(ii).*qd(ii).*the2),(qa(ii).*qd(ii).*the2 - qb(ii).*qc(ii).*the2));
                c(ii) = -atan2((qa(ii).*qb(ii).*the2 - qc(ii).*qd(ii).*the2),(qa(ii).*qd(ii).*the2 + qb(ii).*qc(ii).*the2));
                b(ii) = acos(tmp(ii));
            end
        end
    case 'YXY'
        tmp = qa.^2.*the2 - the1 + qc.^2.*the2;
        tmp(tmp > the1) = the1;
        tmp(tmp < -the1) = -the1;
        for ii=1:numel(tmp)
            if (tmp(ii) < 0) && abs(tmp(ii) + 1) < 10*eps(the1)
                a(ii) = -2.*atan2(qd(ii),qb(ii));
                c(ii) = 0;
                b(ii) = cast(pi, "like", tmp);
            elseif (tmp(ii) > 0) && abs(tmp(ii) - 1) < 10*eps(the1)
                a(ii) = 2.*atan2(qc(ii),qa(ii));
                c(ii) = 0;
                b(ii) = cast(0, "like", tmp);
            else
                a(ii) = -atan2((qa(ii).*qd(ii).*the2 - qb(ii).*qc(ii).*the2),(qa(ii).*qb(ii).*the2 + qc(ii).*qd(ii).*the2));
                c(ii) = atan2((qa(ii).*qd(ii).*the2 + qb(ii).*qc(ii).*the2),(qa(ii).*qb(ii).*the2 - qc(ii).*qd(ii).*the2));
                b(ii) = acos(tmp(ii));
            end
        end
    case 'ZYZ'
        tmp = qa.^2.*the2 - the1 + qd.^2.*the2;
        tmp(tmp > the1) = the1;
        tmp(tmp < -the1) = -the1;
        for ii=1:numel(tmp)
            if (tmp(ii) < 0) && abs(tmp(ii) + 1) < 10*eps(the1)
                a(ii) = -2.*atan2(qb(ii),qc(ii));
                c(ii) = 0;
                b(ii) = cast(pi, "like", tmp);
            elseif (tmp(ii) > 0) && abs(tmp(ii) - 1) < 10*eps(the1)
                a(ii) = 2.*atan2(qd(ii),qa(ii));
                c(ii) = 0;
                b(ii) = cast(0, "like", tmp);
            else
                a(ii) = -atan2((qa(ii).*qb(ii).*the2 - qc(ii).*qd(ii).*the2),(qa(ii).*qc(ii).*the2 + qb(ii).*qd(ii).*the2));
                c(ii) = atan2((qa(ii).*qb(ii).*the2 + qc(ii).*qd(ii).*the2),(qa(ii).*qc(ii).*the2 - qb(ii).*qd(ii).*the2));
                b(ii) = acos(tmp(ii));
            end
        end
    case 'ZXZ'
        tmp = qa.^2.*the2 - the1 + qd.^2.*the2;
        tmp(tmp > the1) = the1;
        tmp(tmp < -the1) = -the1;
        for ii=1:numel(tmp)
            if (tmp(ii) < 0) && abs(tmp(ii) + 1) < 10*eps(the1)
                a(ii) = 2.*atan2(qc(ii),qb(ii));
                c(ii) = 0;
                b(ii) = cast(pi, "like", tmp);
            elseif (tmp(ii) > 0) && abs(tmp(ii) - 1) < 10*eps(the1)
                a(ii) = 2.*atan2(qd(ii),qa(ii));
                c(ii) = 0;
                b(ii) = cast(0, "like", tmp);
            else
                a(ii) = atan2((qa(ii).*qc(ii).*the2 + qb(ii).*qd(ii).*the2),(qa(ii).*qb(ii).*the2 - qc(ii).*qd(ii).*the2));
                c(ii) = -atan2((qa(ii).*qc(ii).*the2 - qb(ii).*qd(ii).*the2),(qa(ii).*qb(ii).*the2 + qc(ii).*qd(ii).*the2));
                b(ii) = acos(tmp(ii));
            end
        end
    case 'XYX'
        tmp = qa.^2.*the2 - the1 + qb.^2.*the2;
        tmp(tmp > the1) = the1;
        tmp(tmp < -the1) = -the1;
        for ii=1:numel(tmp)
            if (tmp(ii) < 0) && abs(tmp(ii) + 1) < 10*eps(the1)
                a(ii) = 2.*atan2(qd(ii),qc(ii));
                c(ii) = 0;
                b(ii) = cast(pi, "like", tmp);
            elseif (tmp(ii) > 0) && abs(tmp(ii) - 1) < 10*eps(the1)
                a(ii) = 2.*atan2(qb(ii),qa(ii));
                c(ii) = 0;
                b(ii) = cast(0, "like", tmp);
            else
                a(ii) = atan2((qa(ii).*qd(ii).*the2 + qb(ii).*qc(ii).*the2),(qa(ii).*qc(ii).*the2 - qb(ii).*qd(ii).*the2));
                c(ii) = -atan2((qa(ii).*qd(ii).*the2 - qb(ii).*qc(ii).*the2),(qa(ii).*qc(ii).*the2 + qb(ii).*qd(ii).*the2));
                b(ii) = acos(tmp(ii));
            end
        end
    case 'XZX'
        tmp = qa.^2.*the2 - the1 + qb.^2.*the2;
        tmp(tmp > the1) = the1;
        tmp(tmp < -the1) = -the1;
        for ii=1:numel(tmp)
            if (tmp(ii) < 0) && abs(tmp(ii) + 1) < 10*eps(the1)
                a(ii) = -2.*atan2(qc(ii),qd(ii));
                c(ii) = 0;
                b(ii) = cast(pi, "like", tmp);
            elseif (tmp(ii) > 0) && abs(tmp(ii) - 1) < 10*eps(the1)
                a(ii) = 2.*atan2(qb(ii),qa(ii));
                c(ii) = 0;
                b(ii) = cast(0, "like", tmp);
            else
                a(ii) = -atan2((qa(ii).*qc(ii).*the2 - qb(ii).*qd(ii).*the2),(qa(ii).*qd(ii).*the2 + qb(ii).*qc(ii).*the2));
                c(ii) = atan2((qa(ii).*qc(ii).*the2 + qb(ii).*qd(ii).*the2),(qa(ii).*qd(ii).*the2 - qb(ii).*qc(ii).*the2));
                b(ii) = acos(tmp(ii));
            end
        end
    case 'XYZ'
        tmp = qa.*qc.*the2 + qb.*qd.*the2;
        tmp(tmp > the1) = the1;
        tmp(tmp < -the1) = -the1;
        for ii=1:numel(tmp)
            if (tmp(ii) > 0) && abs(tmp(ii) - 1) < 10*eps(the1)
                a(ii) = 2.*atan2(qb(ii),qa(ii));
                c(ii) = 0;
                b(ii) = cast(0.5.*pi, "like", tmp);
            elseif (tmp(ii) < 0) && abs(tmp(ii) + 1) < 10*eps(the1)
                a(ii) = 2.*atan2(qb(ii),qa(ii));
                c(ii) = 0;
                b(ii) = cast(-0.5.*pi, "like", tmp);
            else
                a(ii) = atan2((qa(ii).*qb(ii).*the2 - qc(ii).*qd(ii).*the2),(qa(ii).^2.*the2 - the1 + qd(ii).^2.*the2));
                c(ii) = atan2((qa(ii).*qd(ii).*the2 - qb(ii).*qc(ii).*the2),(qa(ii).^2.*the2 - the1 + qb(ii).^2.*the2));
                b(ii) = asin(tmp(ii));
            end
        end
    case 'YZX'
        tmp = qa.*qd.*the2 + qb.*qc.*the2;
        tmp(tmp > the1) = the1;
        tmp(tmp < -the1) = -the1;
        for ii=1:numel(tmp)
            if (tmp(ii) > 0) && abs(tmp(ii) - 1) < 10*eps(the1)
                a(ii) = 2.*atan2(qb(ii),qa(ii));
                c(ii) = 0;
                b(ii) = cast(0.5.*pi, "like", tmp);
            elseif (tmp(ii) < 0) && abs(tmp(ii) + 1) < 10*eps(the1)
                a(ii) = -2.*atan2(qb(ii),qa(ii));
                c(ii) = 0;
                b(ii) = cast(-0.5.*pi, "like", tmp);
            else
                a(ii) = atan2((qa(ii).*qc(ii).*the2 - qb(ii).*qd(ii).*the2),(qa(ii).^2.*the2 - the1 + qb(ii).^2.*the2));
                c(ii) = atan2((qa(ii).*qb(ii).*the2 - qc(ii).*qd(ii).*the2),(qa(ii).^2.*the2 - the1 + qc(ii).^2.*the2));
                b(ii) = asin(tmp(ii));
            end
        end
    case 'ZXY'
        tmp = qa.*qb.*the2 + qc.*qd.*the2;
        tmp(tmp > the1) = the1;
        tmp(tmp < -the1) = -the1;
        for ii=1:numel(tmp)
            if (tmp(ii) > 0) && abs(tmp(ii) - 1) < 10*eps(the1)
                a(ii) = 2.*atan2(qc(ii),qa(ii));
                c(ii) = 0;
                b(ii) = cast(0.5.*pi, "like", tmp);
            elseif (tmp(ii) < 0) && abs(tmp(ii) + 1) < 10*eps(the1)
                a(ii) = -2.*atan2(qc(ii),qa(ii));
                c(ii) = 0;
                b(ii) = cast(-0.5.*pi, "like", tmp);
            else
                a(ii) = atan2((qa(ii).*qd(ii).*the2 - qb(ii).*qc(ii).*the2),(qa(ii).^2.*the2 - the1 + qc(ii).^2.*the2));
                c(ii) = atan2((qa(ii).*qc(ii).*the2 - qb(ii).*qd(ii).*the2),(qa(ii).^2.*the2 - the1 + qd(ii).^2.*the2));
                b(ii) = asin(tmp(ii));
            end
        end
    case 'XZY'
        tmp = qb.*qc.*the2 - qa.*qd.*the2;
        tmp(tmp > the1) = the1;
        tmp(tmp < -the1) = -the1;
        for ii=1:numel(tmp)
            if (tmp(ii) < 0) && abs(tmp(ii) + 1) < 10*eps(the1)
                a(ii) = 2.*atan2(qb(ii),qa(ii));
                c(ii) = 0;
                b(ii) = cast(0.5.*pi, "like", tmp);
            elseif (tmp(ii) > 0) && abs(tmp(ii) - 1) < 10*eps(the1)
                a(ii) = 2.*atan2(qb(ii),qa(ii));
                c(ii) = 0;
                b(ii) = cast(-0.5.*pi, "like", tmp);
            else
                a(ii) = atan2((qa(ii).*qb(ii).*the2 + qc(ii).*qd(ii).*the2),(qa(ii).^2.*the2 - the1 + qc(ii).^2.*the2));
                c(ii) = atan2((qa(ii).*qc(ii).*the2 + qb(ii).*qd(ii).*the2),(qa(ii).^2.*the2 - the1 + qb(ii).^2.*the2));
                b(ii) = -asin(tmp(ii));
            end
        end
    case 'ZYX'
        tmp = qb.*qd.*the2 - qa.*qc.*the2;
        tmp(tmp > the1) = the1;
        tmp(tmp < -the1) = -the1;
        for ii=1:numel(tmp)
            if (tmp(ii) < 0) && abs(tmp(ii) + 1) < 10*eps(the1)
                a(ii) = -2.*atan2(qb(ii),qa(ii));
                c(ii) = 0;
                b(ii) = cast(0.5.*pi, "like", tmp);
            elseif (tmp(ii) > 0) && abs(tmp(ii) - 1) < 10*eps(the1)
                a(ii) = 2.*atan2(qb(ii),qa(ii));
                c(ii) = 0;
                b(ii) = cast(-0.5.*pi, "like", tmp);
            else
                a(ii) = atan2((qa(ii).*qd(ii).*the2 + qb(ii).*qc(ii).*the2),(qa(ii).^2.*the2 - the1 + qb(ii).^2.*the2));
                c(ii) = atan2((qa(ii).*qb(ii).*the2 + qc(ii).*qd(ii).*the2),(qa(ii).^2.*the2 - the1 + qd(ii).^2.*the2));
                b(ii) = -asin(tmp(ii));
            end
        end
    case 'YXZ'
        tmp = qc.*qd.*the2 - qa.*qb.*the2;
        tmp(tmp > the1) = the1;
        tmp(tmp < -the1) = -the1;
        for ii=1:numel(tmp)
            if (tmp(ii) < 0) && abs(tmp(ii) + 1) < 10*eps(the1)
                a(ii) = 2.*atan2(qc(ii),qa(ii));
                c(ii) = 0;
                b(ii) = cast(0.5.*pi, "like", tmp);
            elseif (tmp(ii) > 0) && abs(tmp(ii) - 1) < 10*eps(the1)
                a(ii) = 2.*atan2(qc(ii),qa(ii));
                c(ii) = 0;
                b(ii) = cast(-0.5.*pi, "like", tmp);
            else
                a(ii) = atan2((qa(ii).*qc(ii).*the2 + qb(ii).*qd(ii).*the2),(qa(ii).^2.*the2 - the1 + qd(ii).^2.*the2));
                c(ii) = atan2((qa(ii).*qd(ii).*the2 + qb(ii).*qc(ii).*the2),(qa(ii).^2.*the2 - the1 + qc(ii).^2.*the2));
                b(ii) = -asin(tmp(ii));
            end
        end
    otherwise
        found = false;
        a = zeros(size(qa), "like", qa);
        b = zeros(size(qa), "like", qa);
        c = zeros(size(qa), "like", qa);
end
coder.internal.assert(found, 'shared_rotations:quaternion:NoSeqConv', rot);
eout = [a b c];
end
