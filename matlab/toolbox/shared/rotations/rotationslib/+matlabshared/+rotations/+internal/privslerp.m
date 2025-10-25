function qo = privslerp(q1n, q2n, t, useshortestpath)
%   This function is for internal use only. It may be removed in the future. 
%PRIVSLERP Slerp implementation, as a function

%   Copyright 2018-2024 The MathWorks, Inc.

%#codegen 

% Honor user request for implicit expansion
coder.internal.implicitExpansionBuiltin;

% Get parts
[a1, b1, c1, d1] = parts(q1n);
[a2, b2, c2, d2] = parts(q2n);

% Implement quaternion dot product, inline
dp = a1.*a2 + b1.*b2 + c1.*c2 + d1.*d2;

if useshortestpath
    % Negative dot product, the quaternions aren't pointing the same way (one
    % pos, one negative). Flip the second one. Sim and codegen path because
    % logical indexing on the rhs is a varsize operation which causes MATLAB
    % Coder to error. The for-loop is also more efficient in the generated C
    % code.
    thezero = zeros(1, "like", dp);
    if isempty(coder.target)
        dpidx = dp < thezero;
        if any(dpidx(:))
            a2(dpidx) = -a2(dpidx);
            b2(dpidx) = -b2(dpidx);
            c2(dpidx) = -c2(dpidx);
            d2(dpidx) = -d2(dpidx);        
            dp(dpidx) = -dp(dpidx);
        end
    else
        for ii=1:numel(dp)
            if dp(ii) < thezero
                a2(ii) = -a2(ii);
                b2(ii) = -b2(ii);
                c2(ii) = -c2(ii);
                d2(ii) = -d2(ii);
                dp(ii) = -dp(ii);
            end
        end
    end
end
theone = cast(1, "like", dp);
dp(dp > theone) = 1;  % fix dot products that are 1+eps-ish
theta0 = real(acos(dp));


% Don't do 1./sin(theta0) because for 'natural' we could have antipodal
% quaternions with theta0=pi. But sin(pi) ~= 0, so we don't get inf later.
% Instead do sinang = sin(theta0) to check for near eps values later,
% before taking the reciprocal. 

% Original code: 
% qnumerator = q1n.*sin((1- t).*theta0) + q2n.*sin(t.*theta0);
% qo =  qnumerator.* sinv;
%
% Instead of above, avoid quaternion constructor for performance.
% Faster code:
sinang = sin(theta0);
sinv = 1./sinang;

sin1 = sin((1-t).*theta0)./sinv;
sin2 = sin(t.*theta0)./sinv;

ao = a1.*sin1 + a2.*sin2;
bo = b1.*sin1 + b2.*sin2;
co = c1.*sin1 + c2.*sin2;
do = d1.*sin1 + d2.*sin2;
qo = quaternion(ao, bo, co, do);


% Fix up dp == 1 or -1 which causes NaN quaternions. This means the two
% quaternions are the same rotation so just use the first. 
%
% In both cases sinang will be a small number because theta0 will be 0 or
% pi. Remove those values and just use q1 instead.

smallSin = sinang < (10* eps("like", dp)); 
if any(smallSin(:)) % Don't do this unless necessary
    infmapExpanded = smallSin & true(size(qo)); % handle implicit expansion to size(qo)
    infmapExpandedNumeric = cast(infmapExpanded, classUnderlying(qo)); % same thing as above with 1s
    replaceval = q1n .* infmapExpandedNumeric; % an array with q1n everywhere there's an inf in infmapExpanded
    qo(infmapExpanded) = replaceval(infmapExpanded); % replace
end

qo = normalize(qo);
