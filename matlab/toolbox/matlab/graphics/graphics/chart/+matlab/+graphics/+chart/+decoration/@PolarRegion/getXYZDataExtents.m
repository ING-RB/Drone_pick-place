function extents = getXYZDataExtents(obj, transform, ~)
%

%   Copyright 2023 The MathWorks, Inc.

rext = sort(obj.RadiusSpan, 'ascend');
if any(isnan(rext)) || all(isinf(rext))
    rext=[nan nan];
elseif isinf(rext(1))
    rext(1) = rext(2);
elseif isinf(rext(2))
    rext(2) = rext(1);
end


thetaext = sort(obj.ThetaSpan, 'ascend');
if any(isnan(thetaext)) || all(isinf(thetaext))
    thetaext=[nan nan];
elseif isinf(thetaext(1))
    thetaext(1)=thetaext(2);
elseif isinf(thetaext(2))
    thetaext(2)=thetaext(1);
end

% Transform just theta to support ThetaAxisUnits
extents = [thetaext * transform(1); rext; nan(1,2)];
end
