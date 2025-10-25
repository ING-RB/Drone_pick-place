function x = str2double(s)
%

%   Copyright 1984-2023 The MathWorks, Inc.

if ischar(s)
    
    % Try to read simple case of something like 5.75
    [a,count,errmsg,nextindex] = sscanf(s,'%f',1);
    if count == 1 && isempty(errmsg) && nextindex > numel(s)
        x = a;
        return;
    end

    s = deblank(s);
    % Remove any commas so that numbers formatted like 1,200.34 are
    % handled.
    s(s == ',')= [];
    lenS = numel(s); %get len again since it has changed after deblanking
    
    % Try to get 123, 123i, 123i + 45, or 123i - 45
    [a,count,errmsg,nextindex] = sscanf(s,'%f %1[ij] %1[+-] %f',4);
    % simlest case is a double
    if count == 1 && isempty(errmsg) && nextindex > lenS
        x = a;
        return;
    end
    % now deal with complex
    if isempty(errmsg) && nextindex > lenS
       if count==2
            x = a(1)*1i;
        elseif count==4
            sign = (a(3)=='+')*2 - 1;
            x = complex(sign*a(4), a(1));
        else
            x = NaN;
        end
        return
    end

    % Try to get 123 + 23i or 123 - 23i
    [a,count,errmsg,nextindex] = sscanf(s,'%f %1[+-] %f %1[ij]',4);
    if isempty(errmsg) && nextindex > lenS
        if count==4
            sign = (a(2)=='+')*2 - 1;
            x = complex(a(1), sign*a(3));
        else
            x = NaN;
        end
        return
    end

    % Try to get i, i + 45, or i - 45
    [a,count,errmsg,nextindex] = sscanf(s,' %1[ij] %1[+-] %f',3);
    if isempty(errmsg) && nextindex > lenS
        if count==1
            x = 1i;
        elseif count==3
            sign = (a(2)=='+')*2 - 1;
            x = complex(sign*a(3), 1);
        else
            x = NaN;
        end
        return
    end

    % Try to get 123 + i or 123 - i
    [a,count,errmsg,nextindex] = sscanf(s,'%f %1[+-] %1[ij]',3);
    if isempty(errmsg) && nextindex > lenS
        if count==1
            x = a(1);
        elseif count==3
            sign = (a(2)=='+')*2 - 1;
            x = complex(a(1), sign);
        else
            x = NaN;
        end
        return
    end

    % Try to get -i, -i + 45, or -i - 45
    [a,count,errmsg,nextindex] = sscanf(s,' %1[+-] %1[ij] %1[+-] %f',4);
    if isempty(errmsg) && nextindex > lenS
        if count==2
            sign = (a(1)=='+')*2 - 1;
            x = sign*1i;
        elseif count==4
            sign1 = (a(1)=='+')*2 - 1;
            sign2 = (a(3)=='+')*2 - 1;
            x = complex(sign2*a(4), sign1);
        else
            x = NaN;
        end
        return
    end

    % Try to get 123 + 23*i or 123 - 23*i
    [a,count,errmsg,nextindex] = sscanf(s,'%f %1[+-] %f %1[*] %1[ij]',5);
    if isempty(errmsg) && nextindex > lenS
        if count==5
            sign = (a(2)=='+')*2 - 1;
            x = complex(a(1), sign*a(3));
        else
            x = NaN;
        end
        return
    end

    % Try to get 123*i, 123*i + 45, or 123*i - 45
    [a,count,errmsg,nextindex] = sscanf(s,'%f %1[*] %1[ij] %1[+-] %f',5);
    if isempty(errmsg) && nextindex > lenS
        if count==1
            x = a;
        elseif count==3
            x = a(1)*1i;
        elseif count==5
            sign = (a(4)=='+')*2 - 1;
            x = complex(sign*a(5), a(1));
        else
            x = NaN;
        end
        return
    end

    % Try to get i*123 + 45 or i*123 - 45
    [a,count,errmsg,nextindex] = sscanf(s,' %1[ij] %1[*] %f %1[+-] %f',5);
    if isempty(errmsg) && nextindex > lenS
        if count==1
            x = 1i;
        elseif count==3
            x = 1i*a(3);
        elseif count==5
            sign = (a(4)=='+')*2 - 1;
            x = complex(sign*a(5), a(3));
        else
            x = NaN;
        end
        return
    end

    % Try to get -i*123 + 45 or -i*123 - 45
    [a,count,errmsg,nextindex] = sscanf(s,' %1[+-] %1[ij] %1[*] %f %1[+-] %f',6);
    if isempty(errmsg) && nextindex > lenS
        if count==2
            sign = (a(1)=='+')*2 - 1;
            x = sign*1i;
        elseif count==4
            sign = (a(1)=='+')*2 - 1;
            x = sign*1i*a(4);
        elseif count==6
            sign1 = (a(1)=='+')*2 - 1;
            sign2 = (a(5)=='+')*2 - 1;
            x = complex(sign2*a(6), sign1*a(4));
        else
            x = NaN;
        end
        return
    end

    % Try to get 123 + i*45 or 123 - i*45
    [a,count,errmsg,nextindex] = sscanf(s,'%f %1[+-] %1[ij] %1[*] %f',5);
    if isempty(errmsg) && nextindex > lenS
        if count==5
            sign = (a(2)=='+')*2 - 1;
            x = complex(a(1), sign*a(5));
        else
            x = NaN;
        end
        return
    end

    % None of the above cases, but s still is a character array.
    x = NaN;

elseif ~isempty(s) && iscellstr(s)
    x = cellfun(@str2double, s);
elseif iscell(s)
    x = textArrayType2double(s, @cellLoop);
elseif isstring(s)
    x = textArrayType2double(s, @stringLoop);
else
    x = NaN;
end

end

function x = textArrayType2double(s, looper)
    x = [];
    for k=numel(s):-1:1
        x(k) = looper(s,k);
    end
    x = reshape(x,size(s));
end


function x = cellLoop(s,k)
    str = s{k};
    if iscell(str) || isstring(str)
        x = NaN;
    else
        x = str2double(str);
    end
end

function x = stringLoop(s,k)
    if ismissing(s(k))
        x = NaN;
    else
        % Note the implicit conversion to char here with the {}.
        x = str2double(s{k});
    end
end
