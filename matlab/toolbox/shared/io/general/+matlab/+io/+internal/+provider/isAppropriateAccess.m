function tf = isAppropriateAccess(metaprop, mode)
%isAppropriateAccess   Returns true if METAPROP has the appropriate
%   access level for MODE.
%
%   MODE can be "set" or "get".
%
%   In "get" mode, METAPROP must have "public" GetAccess.
%   In "set" mode, METAPROP must have "public" SetAccess.
%
%   See also: matlab.io.internal.Provider

%   Copyright 2021 The MathWorks, Inc.

    arguments
        metaprop (1, 1) meta.property
        mode     (1, 1) string {mustBeMode}
    end

    if mode == "get"
        % NOTE: this drops support for property access lists.
        % TODO: find a way to support those. It'll be hard to do
        %       so without knowing the caller's class name.
        tf = metaprop.GetAccess == "public";
    elseif mode == "set"
        tf = metaprop.SetAccess == "public";
    end
end

function mustBeMode(mode)
    mustBeMember(mode, ["get" "set"]);
end
