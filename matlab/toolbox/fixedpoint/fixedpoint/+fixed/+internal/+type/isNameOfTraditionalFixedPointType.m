function b = isNameOfTraditionalFixedPointType(nameStr,includeScaledDouble,caseSensitive,include64BitInt)
% isNameOfTraditionalFixedPointType is type that does/did require fixed-point license
%
% Usage
%    b = isNameOfTraditionalFixedPointType(nameStr,includeScaledDouble)
%
% Input
%    nameStr string representing a Simulink non-alias compiled type name
%    includeScaledDouble scaled double can optionally be included (default)
%                        or excluded
%    caseSensitive default true
% Outputs
%    b  logical true if type requires a Fixed-Point Designer license
%                    or did in past release.
%
% For traditional Simulink built-in types
%    'double', 'single', 'boolean', 'int8', ... 'uint32'
% false will be returned
%
% For types that do require Fixed-Point Designer licenses, such as
% For fixed-point types like
%    'sfix6', 'ufix17', 'sfix16_En5'
% return true.
%
% For scaled doubles like
%   'flts8_S7', 'fltu8_B3'
% return true if includeScaledDouble is true.
%
% For 64 bit integer types, new or traditional name
%    'int64', 'uin64', 'sfix64', 'ufix64'
% true will be returned, because these required a license before R2017a
%
% All other type names will return false
% Even if a type name is an alias to a fixed-point type, it will return
% false.

% Copyright 2017-2020 The MathWorks, Inc.

%#codegen
    if nargin < 2
        includeScaledDouble = true;
    end
    if nargin < 3
        caseSensitive = true;
    end
    if nargin < 4
        include64BitInt = true;
    end    
    
    nameStr = char(nameStr);
    if ~caseSensitive
        nameStr = lower(nameStr);
    end
    
    b = (length(nameStr) > 4 ) && (...
        isFixPattern(nameStr) || ...
        is64BitIntPattern(nameStr,include64BitInt) || ...
        isScaledDoublePattern(nameStr,includeScaledDouble) ...
        );
    %b = coder.const(b);
end

function b = isFixPattern(nameStr)

    % Note: this approach is less elegant than regex, but faster
    c1 = nameStr(1);
    b = false;
    if ('s' == c1 || 'u' == c1)
        if strncmp(nameStr(2:4),'fix', 3)
            b = any( nameStr(5) == '123456789' );
        end
    end
end

function b = is64BitIntPattern(nameStr,include64BitInt)
    if include64BitInt
        b = fixed.internal.type.is64BitIntPattern(nameStr,true);
    else
        b = false;
    end
end

function b = isScaledDoublePattern(nameStr,includeScaledDouble)
    b = false;
    if includeScaledDouble        
        % Note: this approach is less elegant than regex, but faster
        c1 = nameStr(4);
        if ('s' == c1 || 'u' == c1)
            if strncmp(nameStr(1:3),'flt', 3)
                b = any( nameStr(5) == '123456789' );
            end
        end
    end
end
