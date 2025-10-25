classdef (Hidden) SquadNaturalStrategy < matlabshared.rotations.internal.interpolation.InterpolationStrategy 
%   This class is for internal use only. It may be removed in the future. 
%   %SQUADNATURALSTRATEGY The squad-natural interpolation strategy concrete class


%   Copyright 2024 The MathWorks, Inc.		

    %#codegen

    properties
        si
    end

    methods
        function obj = plan(obj, ~, values)
            % PLAN precompute the Si intermediate keyframes
            qm = values(1:end-2, :);
            qi = values(2:end-1, :);
            qp = values(3:end, :);
            thefour = cast(4, classUnderlying(values));
            siKeyframes = qi.*exp(  - (log(qi.\qp) + log(qi.\qm))./thefour);
            sall = [values(1,:); siKeyframes; values(end,:)];
            obj.si = sall;
        end
        function y = interpolate(obj, xq, xhigh, xlow, yhigh, ylow, xlowidx, page)
            h = (xq - xlow)./(xhigh - xlow);
            cls = classUnderlying(yhigh);
            theone = ones(1, cls);
            thetwo = cast(2, cls);

            Hf = thetwo.*h.*(theone-h);
            t1 = matlabshared.rotations.internal.privslerp(ylow, yhigh, h,false);
            siKeyframes = obj.si;
            t2 = matlabshared.rotations.internal.privslerp(siKeyframes(xlowidx, page), siKeyframes(xlowidx+1, page), h, false);
            y = matlabshared.rotations.internal.privslerp(t1, t2, Hf, false);
        end
        function y = normalizeLut(~, y)
            y = normalize(y);
        end
    end

end
