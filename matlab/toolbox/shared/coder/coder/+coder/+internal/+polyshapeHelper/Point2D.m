classdef Point2D
% Helper class to perform simple operations on one vertex

%   Copyright 2022 The MathWorks, Inc.

    %#codegen
    
    properties
        X
        Y
    end

    methods
        function obj = Point2D(x, y)
            obj.X = x;
            obj.Y = y;
        end

        function d = Distance2(obj, p)
            dx = obj.X - p.X;
            dy = obj.Y - p.Y;
            
            d = dx * dx + dy * dy;
        end

        function d = Distance(obj, p)
            d = realsqrt(Distance2(obj, p));
        end

        function obj = rotate(obj, theta, ox, oy)
            if (~isfinite(obj.X) || ~isfinite(obj.Y))
                return;
            end

            sa = sin(theta);
            ca = cos(theta);
            obj.X = obj.X - ox;
            obj.Y = obj.Y - oy;
            X1 = obj.X * ca - obj.Y * sa;
            Y1 = obj.X * sa + obj.Y * ca;
            obj.X = X1 + ox;
            obj.Y = Y1 + oy;
            % Check to ensure rotation did not result in a non finite
            % vertex
            if (~isfinite(obj.X) || ~isfinite(obj.Y))
                coder.internal.error('MATLAB:polyshape:rotateOverflow');
            end
        end

    end

end
