function dec = base2dec(str,base)
%

%   Copyright 1984-2023 The MathWorks, Inc.

    narginchk(2,2);
    if (base < 2 || base > 36 || floor(base) ~= base)
        error(message('MATLAB:base2dec:InvalidBase'));
    elseif ~isstring(str)        
        dec = base2decImpl(str,base);
    elseif any(ismissing(str),'all')
        error(message('MATLAB:string:MissingNotSupported'));
    else
        % Handle string arrays
        dec = zeros(size(str));
        for i = 1:numel(str)
           dec(i) = base2decImpl(str(i),base);
        end
    end
    if any(dec>=flintmax,'all')
        warning(message('MATLAB:base2dec:InputExceedsFlintmax'))
    end

end

function d = base2decImpl(h,b)
    h = char(h);
    if isempty(h)
        d = []; 
        return;
    end

    if ~isempty(find(h==' ' | h==0,1)) 
      h = strjust(h);
      h(h==' ' | h==0) = '0';
    end
    
    % BASE2DEC accepts numbers like 12abf in base 16
    h = upper(h);

    [m,n] = size(h);
    bArr = [ones(m,1) cumprod(b(ones(m,n-1)),2)];
    values = -1*ones(256,1);
    values(double('0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ')) = 0:35;
    if any(any(values(h) >= b | values(h) < 0))
        error(message('MATLAB:base2dec:NumberOutsideRange', h,b));
    end
    a = fliplr(reshape(values(abs(h)),size(h)));
    d = sum((bArr .* a),2);
end
