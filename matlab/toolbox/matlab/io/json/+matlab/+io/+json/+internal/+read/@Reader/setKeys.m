function setKeys(r)
%

%   Copyright 2024 The MathWorks, Inc.

import matlab.io.json.internal.read.*

% Only set keys if the current type is an object
if r.getCurrentType() == JSONType.Object
    % Handle duplicate keys, if any
    % Set DuplicateKeyRule = "auto" behavior
    if r.opts.DuplicateKeyRule == "auto"
        % As the type of keys is always string for the
        % first release, DuplicateKeyRule = "auto" is
        % "makeUnique" by default.
        r.opts.DuplicateKeyRule = "makeUnique";
    end

    switch r.opts.DuplicateKeyRule
      case "makeUnique"
        r.makeUniqueKeys();
      case "preserveLast"
        % If DuplicatekeyRule is set to "preserveLast",
        % remove earlier instances of duplicate keys
        r.removeDuplicateKeys();
      case "error"
        [hasDuplicates, duplicateKey] = r.hasDuplicateKeys();
        if hasDuplicates
            error(message("MATLAB:io:dictionary:readdictionary:EncounteredDuplicateKeyNames", ...
                          duplicateKey, r.opts.Filename));
        end
    end
end
