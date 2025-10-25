function propnames = properties(classname,nv)
%This function is for internal use only. It may be removed in the future.
%
%properties Retrieve list of get-/set-able properties
%
%   PROPNAMES = properties(CLASSNAME) retrieve string-array, PROPNAMES, of
%   all public, gettable, non-hidden properties
%
%   PROPNAMES = properties(CLASSNAME) optionally accepts nv-pairs:
%
%       AccessType  - query either "GetAccess" or "SetAccess"
%
%                   Default: "GetAccess"
%
%       AccessLevel - a string which filters properties relative to CLASS's
%       access privileges. May be one of the following:
%
%                   public      - public properties
%                   protected   - protected properties
%                   allowed     - directly accessible or accessed via
%                                 superclass access list
%
%                   Default: "public"
%
%       ShowHidden - include (true) or exclude (false) hidden properties 
%
%                   Default: true

%   Copyright 2023 The MathWorks, Inc.

    arguments
        classname (1,1) string
        nv.AccessLevel (1,1) string {mustBeMember(nv.AccessLevel,["public","protected","allowed"])} = "public"
        nv.AccessType (1,1) string {mustBeMember(nv.AccessType,["GetAccess","SetAccess"])} = "GetAccess"
        nv.ShowHidden (1,1) {mustBeMember(nv.ShowHidden,[0 1])} = 0
    end

    % Retrieve meta object
    m = meta.class.fromName(classname);
    allnames = string({m.PropertyList.Name}');

    switch nv.AccessLevel 
        case "public"
            settableProps = cellfun(@(x)ischar(x) && string(x)=="public",{m.PropertyList.(nv.AccessType)});
        case "protected"
            settableProps = cellfun(@(x)ischar(x) && string(x)=="protected",{m.PropertyList.(nv.AccessType)});
        case "allowed"
            % Identify properties settable by current class
            settableProps = cellfun(@(x)ischar(x) && any(string(x)==["public","protected"]),{m.PropertyList.(nv.AccessType)});
    
            % Get hierarchy of current class
            classNames = superclasses(classname);
    
            % Find settable parent-class properties
            parentSettable = cellfun(@(x)~ischar(x) && ...
                isSettableByAncestor(x,classNames),{m.PropertyList.(nv.AccessType)});
    
            % Combine
            settableProps = settableProps | parentSettable;
    end
    
    % Return all settable
    if ~nv.ShowHidden
        isHidden = [m.PropertyList.Hidden];
        propnames = allnames(settableProps & ~isHidden);
    else
        propnames = allnames(settableProps(:));
    end
end

function settable = isSettableByAncestor(allowedAccessor,parentClasses)
    if iscell(allowedAccessor)
        settable = any(ismember(cellfun(@(x)string(x.Name),allowedAccessor)',parentClasses));
    else
        settable = any(ismember(allowedAccessor.Name,parentClasses));
    end
end
