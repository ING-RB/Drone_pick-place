function [x,ok] = str2num(s,varargin)
%

%   Copyright 1984-2023 The MathWorks, Inc.

    if nargin > 0
        s = convertStringsToChars(s);
    end
    
    if ~ischar(s) || ~ismatrix(s)
       error(message('MATLAB:str2num:InvalidArgument'))
    end
    
    isDefaultCall = nargin == 1;

    try
        isRestrictedEval = nargin > 1 && matlab.internal.strfun.isRestrictedEval(varargin{:});
    catch e
        e.throw;
    end

    if isempty(s)
        x = [];
        ok=false;
        return
    end
    
    % Replace any char(0) characters with spaces
    if ~all(all(s))
        s(s==char(0)) = ' ';
    end

    m = size(s,1);
    n = size(s,2);
    
    if m==1
      [x,ok] = protected_conversion(['[' s ']'], isDefaultCall, isRestrictedEval); % Always add brackets
    else
        semi = ';';
        space = ' ';
        if ~any(any(s == '[' | s == ']'))  % String does not contain brackets
            o = ones(m-1,1);
            s = [['[';space(o)] s [semi(o) space(o);' ]']]';
        elseif ~any(any(s(1:m-1,:) == semi))  % No ;'s in non-last rows
            s = [s,[semi(ones(m-1,1));space]]';
        else                               % Put ;'s where appropriate
            spost = space(ones(m,1));
            for i = 1:m-1
                last = find(s(i,:) ~= space,1,'last');
                if s(i,n-last+1) ~= semi
                    spost(i) = semi;
                end
            end
            s = [s,spost]';
        end
        [x,ok] = protected_conversion(s, isDefaultCall, isRestrictedEval);
    end
    
    if (ischar(x) || iscell(x) || isstring(x)) || (isRestrictedEval && ~(isnumeric(x) || islogical(x)))
       x = [];
       ok = false;
    end
end

function [STR2NUM_result,STR2NUM_ok] = protected_conversion(STR2NUM_StR, STR2NUM_isDefaultCall, STR2NUM_isRestrictedEval)
    % Try to convert the string into a number.  If this fails, return [] and ok=0
    % Protects variables in STR2NUM from "variables" in s. Uses ugly variable 
    % names to discourage users from slurping up these variables.
    
    try
        if STR2NUM_isDefaultCall
            STR2NUM_result = matlab.internal.strfun.restrictedEval(STR2NUM_StR);
        else
            STR2NUM_result = matlab.internal.strfun.restrictedEval(STR2NUM_StR,STR2NUM_isRestrictedEval);
        end
        STR2NUM_ok = true;
    catch exception %#ok
        STR2NUM_result = [];
        STR2NUM_ok = false;
    end
end
