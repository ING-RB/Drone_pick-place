function fw = r2cVectorFcn(f,convertArgs,hasMatrixArgs)
% Utility for generating a new function handle from a vector-valued
% function in the context of solving ODEs, e.g. ODEFcns. Only nargout(f) ==
% 1 is supported. convertArgs is a logical array of length nargin(f) >= 2.
% If convertArgs(j) is true, argument j is converted from real interleaved form to
% complex form before calling the user-supplied f. Optimized forms exist
% for f(t,y), f(t,y,p), f(t,y,yp), and f(t,y,yp,p), with and without
% conversion of the p arguments. A generic wrapper would not be used at
% this time, so the function issues an error if there is no optimized
% wrapper for a given convertArgs pattern.
% hasMatrixArgs is an indication that the typecast for vectors should be
% replaced with the r2cArray logic since these inputs may be matrices. For
% now, this is a logical since it's only used for delay, and therefore
% applies to any lagged argument. The functions marked with an m suffix are
% used for this.

%    Copyright 2024 MathWorks, Inc.

nc = numel(convertArgs);
assert(nc >= 2 && nc <= 5 && ...        % No wrappers for nc < 2 and nc > 4
    ~convertArgs(1) && ...              % t must not be converted.
    (nc < 2 || convertArgs(2)) && ...   % y must be converted if present.
    (nc < 4 || convertArgs(3)) && ...   % yp must be converted if present.
    (nc < 5 || convertArgs(4)));        % ypdel must be converted if present.
if ~hasMatrixArgs
    if nc == 2
        fw = @(t,y)i2c2(f,t,y);
    elseif nc == 3
        if convertArgs(3)
            % f(t,y,p) with conversion of p or f(t,y,yp)
            fw = @(t,y,yp)i3c23(f,t,y,yp);
        else
            % f(t,y,p)
            fw = @(t,y,p)i3c2(f,t,y,p);
        end
    else
        % convertArgs(3) is guaranteed to be true. No supported fully-implicit
        % solver requires conversion of the parameters input. If one is added,
        % here is where we would conditionally assign a wrapper that accepts 4
        % inputs and converts inputs 2, 3, and 4. Following the naming
        % convention, it would be i4c234(f,t,y,yp,p). The assert() guarding the
        % top of the function will need to be modified to allow convertArgs(4)
        % to be true.
        fw = @(t,y,yp,p)i4c23(f,t,y,yp,p);
    end
else % matrix args
    if nc == 3
        % f(t,y,ydel)
        fw = @(t,y,ydel) i3c23m(f,t,y,ydel);
    elseif nc == 4
        if convertArgs(4)
            % f(t,y,ydel,ypdel)
            fw = @(t,y,ydel,ypdel) i4c234m(f,t,y,ydel,ypdel);
        else
            % f(t,y,ydel,p) don't convert p
            fw = @(t,y,ydel,p) i4c23m(f,t,y,ydel,p);
        end
    else % nc == 5
        % f(t,y,ydel,ypdel,p) don't convert p alternative cannot be true
        fw = @(t,y,ydel,ypdel,p) i5c234m(f,t,y,ydel,ypdel,p);
    end
end
end

function out = i2c2(f,t,y)
% For f(t,y).
y = typecast(real(y),'like',complex(y));
out = complex(f(t,y));
out = typecast(out,'like',real(out));
out = out(:); % Return a column vector (scalar complex out results in a 1x2 row vector).
end

function out = i3c2(f,t,y,p)
% For f(t,y,p) without converting p.
y = typecast(real(y),'like',complex(y));
out = complex(f(t,y,p));
out = typecast(out,'like',real(out));
out = out(:); % Return a column vector (scalar complex out results in a 1x2 row vector).
end

function out = i3c23(f,t,y,p)
% For f(t,y,p), converting both y and p.
% Also works for implicit problems f(t,y,yp).
y = typecast(real(y),'like',complex(y));
p = typecast(real(p),'like',complex(p));
out = complex(f(t,y,p));
out = typecast(out,'like',real(out));
out = out(:); % Return a column vector (scalar complex out results in a 1x2 row vector).
end

function out = i3c23m(f,t,y,p)
% For f(t,y,p), converting both y and p.
y = typecast(real(y),'like',complex(y));
p = matlab.ode.internal.r2cArray(p);
out = complex(f(t,y,p));
out = typecast(out,'like',real(out));
out = out(:); % Return a column vector (scalar complex out results in a 1x2 row vector).
end

function out = i4c23(f,t,y,yp,p)
% For f(t,y,yp,p), converting y and yp but not p.
y = typecast(real(y),'like',complex(y));
yp = typecast(real(yp),'like',complex(yp));
out = complex(f(t,y,yp,p));
out = typecast(out,'like',real(out));
out = out(:); % Return a column vector (scalar complex out results in a 1x2 row vector).
end

function out = i4c23m(f,t,y,yp,p)
% For f(t,y,yp,p), converting y and yp but not p.
y = typecast(real(y),'like',complex(y));
yp = matlab.ode.internal.r2cArray(yp);
out = complex(f(t,y,yp,p));
out = typecast(out,'like',real(out));
out = out(:); % Return a column vector (scalar complex out results in a 1x2 row vector).
end

function out = i4c234m(f,t,y,ydel,ypdel)
% For f(t,y,yp,p), converting y and yp but not p.
y = typecast(real(y),'like',complex(y));
ydel = matlab.ode.internal.r2cArray(ydel);
ypdel = matlab.ode.internal.r2cArray(ypdel);
out = complex(f(t,y,ydel,ypdel));
out = typecast(out,'like',real(out));
out = out(:); % Return a column vector (scalar complex out results in a 1x2 row vector).
end

function out = i5c234m(f,t,y,ydel,ypdel,p)
% For f(t,y,yp,p), converting y and yp but not p.
y = typecast(real(y),'like',complex(y));
ydel = matlab.ode.internal.r2cArray(ydel);
ypdel = matlab.ode.internal.r2cArray(ypdel);
out = complex(f(t,y,ydel,ypdel,p));
out = typecast(out,'like',real(out));
out = out(:); % Return a column vector (scalar complex out results in a 1x2 row vector).
end
