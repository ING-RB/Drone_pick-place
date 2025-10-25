function disp(this)
%MATLAB Code Generation Private Method

%   Copyright 2017-2018 The MathWorks, Inc.
%#codegen
if coder.target('MATLAB')
    str = '';
    for c = ONE:this.n
        k = this.colidx(c);
        while k < this.colidx(c+ONE)
            if isreal(this.d)
                str = [str, sprintf('   (%d,%d) = %g\n', ...
                                    this.rowidx(k), c, this.d(k))]; %#ok
            else
                str = [str, sprintf('   (%d,%d) = %g + %gi\n', ...
                                    this.rowidx(k), c, real(this.d(k)), imag(this.d(k)))]; %#ok

            end
            k = k+ONE;
        end
    end
    if isempty(str)
        str = sprintf('    All zero sparse: %dx%d\n', this.m, this.n);
    end
    disp(str);
else
    builtin('disp',this);
end

%--------------------------------------------------------------------------
