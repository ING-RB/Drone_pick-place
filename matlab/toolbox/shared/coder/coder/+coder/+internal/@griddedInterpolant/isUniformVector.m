function b = isUniformVector(G, len, cls)
    % checks if the sample points form a uniform vector
    % cubic method is valid only for uniform vectors.

    %   Copyright 2022 The MathWorks, Inc.

    %#codegen

    coder.internal.prefer_const(cls);

    coder.internal.assert(len >= 2,'MATLAB:griddedInterpolant:DegenerateGridErrId');
    b = true;
    firstOrLast = max(abs(G(1)), abs(G(len)));
    scale = max(firstOrLast, len);
    eps_h = 2 * (scale * eps(cls));

    exactlyUniform = true;
    h_min = G(2) - G(1);
    
    for i = 2:len-1
        h = G(i + 1) - G(i);
        gap = abs(h - h_min);
        if (gap > eps_h)
            b = false;
        end
        exactlyUniform = exactlyUniform & (h == h_min);
        if (h < h_min)
            h_min = h;
        end
    end

    if (b)
        b = ~( (h_min < eps_h) && ~exactlyUniform);
    end

end
