function Q = getQuad(V)
%getQuad - The global quadrant of a vector
%
%   QUAD = getQuad(V) is the global quadrant of vector V. When a vector
%   falls directly on an axis, it is denoted as one of the four cardinal
%   directions

%   Copyright 2024 The MathWorks, Inc.

%#codegen
    x = V(:,1);
    y = V(:,2);
    % Initialize the Q array with zeros
    Q = zeros(size(x));
    
    % Determine the Q using logical indexing
    Q(x > 0 & y >= 0) = 2;  % Quadrant I+East, Right=2
    Q(x < 0 & y >= 0) = 1;  % Quadrant II+West, Left=1
    Q(x < 0 & y <= 0) = 1;  % Quadrant III
    Q(x > 0 & y <= 0) = 2;  % Quadrant IV
    % Points determine north-south
    Q(x == 0 & y > 0) = 3; % North
    Q(x == 0 & y < 0) = 4; % South
    % Origin
    Q(x == 0 & y == 0) = 5;
end
