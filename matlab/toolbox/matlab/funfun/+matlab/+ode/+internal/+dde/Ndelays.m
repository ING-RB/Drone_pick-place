function v = Ndelays(t,y,ydel,ypdel,IVP,IVP_T0,DELTA,MINCHANGE,varargin)
    % ddensd helper to evaluate the delays
    D = ydel(t,y,varargin{:});
    Dp = ypdel(t,y,varargin{:});
    
    if any(Dp > t)
        error(message('MATLAB:ddensd:DELYPGreaterThanT',sprintf('%g',t)));
    end
    
    if IVP
        if any(D < IVP_T0)
            error(message('MATLAB:ddensd:DELYLessThanT0',sprintf('%g',t)));
        end
        if any(Dp < IVP_T0)
            error(message('MATLAB:ddensd:DELYPLessThanT0',sprintf('%g',t)));
        end
        if (any(Dp == t) && (t > IVP_T0))
            error(message('MATLAB:ddensd:IVPDELYPEqualT',sprintf('%g',t)));
        end
    else
        if any(Dp == t)
            error(message('MATLAB:ddensd:DELYPEqualT',sprintf('%g',t)));
        end
    end
    Dpd = Dp - max(DELTA*abs(Dp),MINCHANGE);
    v = [D(:);Dp(:);Dpd(:)];
end 
%   Copyright 2024 The MathWorks, Inc.