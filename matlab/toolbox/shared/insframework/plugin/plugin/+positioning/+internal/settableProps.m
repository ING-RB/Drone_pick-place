function [s, hasPrivateProtected] = settableProps(classname, exemptProps)
%   This function is for internal use only. It may be removed in the future.
%SETTABLEPROPS Return list of settable properties.
%   This function does not work in codegen.
%
%   The inputs are:
%       classname = a char vec. Name of a class.
%
%       exemptProps - a cell array of chars. Properties which are okay to
%           be private or protected. Ignore these props for the purpose of
%           determining hasPrivateProtected.
%
%   The returned values are:
%       s - a cell array of char vectors. The names of publicly settable
%           and gettable properties
%
%       hasPrivateProtected - a boolean. True if the object has any private
%           or protected properties other than those on the exempt list,
%           exemptProps.


%   Copyright 2022 The MathWorks, Inc.      
  
mc = meta.class.fromName(classname);
mp = mc.PropertyList;
Np = numel(mp);
hasPrivateProtected = false;

s = cell(0);
for ii=1:Np
    % Add a property if it is publicly settable and gettable and
    % non-Constant.
    ga = mp(ii).GetAccess;
    sa = mp(ii).SetAccess;
    isconst = mp(ii).Constant;
    name = mp(ii).Name;

    if ischar(ga) && ischar(sa) && strcmp(ga, 'public') && strcmp(sa, 'public') 
            % Found a public property! Record it as long as it's not
            % constant.
            if ~isconst
                s{end+1} = name; %#ok<AGROW>
            end
    else
            % Not a public property. In the case that ga or sa is not a
            % char, that means it's access is controlled by a meta class
            % list, which means it's not public. Set the boolean flag.
            if ~ismember(name, exemptProps)
                hasPrivateProtected = true;
            end
    end
end
