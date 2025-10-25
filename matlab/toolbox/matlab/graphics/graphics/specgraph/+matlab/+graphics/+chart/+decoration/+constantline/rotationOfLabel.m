function rotation = rotationOfLabel(ax, lo, angle, xdir, ydir)
%Determines how much to rotate label

%   Copyright 2018 The MathWorks, Inc.

    switch ax
        case 'x'
            switch ydir
                case 'reverse'
                    angle = angle + 180;
            end
            switch lo
                case 'aligned'
                    rotation = 90 + -angle;
                case 'horizontal'
                    rotation = -angle;
            end  
        case 'y'
            switch xdir
                case 'normal'
                    rotation = angle;
                case 'reverse'
                    rotation = angle - 180;
            end
            
    end

end
