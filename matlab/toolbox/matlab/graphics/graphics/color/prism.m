function map = prism(m)
%

%   C. Moler, 8-11-92.
%   Copyright 1984-2024 The MathWorks, Inc.

arguments
    m (1,1) double {mustBeInteger, mustBeNonnegative} = matlab.graphics.internal.colormapheight
end

if nargin + nargout == 0
    h = get(gca,'Child');
    m = length(h);
end

% R = [red; orange; yellow; green; blue; violet]
R = [1 0 0; 1 1/2 0; 1 1 0; 0 1 0; 0 0 1; 2/3 0 1];

% Generate m/6 vertically stacked copies of r with Kronecker product.
e = ones(ceil(m/6),1);
R = kron(e,R);
R = R(1:m,:);

if nargin + nargout == 0
    % Apply to lines in current axes.
    for k = 1:m
        if strcmp(get(h(k),'type'),'line')
            set(h(k),'Color',R(k,:))
        end
    end
else
    map = R;
end
end