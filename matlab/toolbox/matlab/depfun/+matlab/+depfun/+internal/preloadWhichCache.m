function preloadWhichCache(pcm_navigator)
% Preload the WHICH cache from the given database.
% 
%  DATABASE: Full path to the database file. DependencyDepot will create
%  the database if necessary.
%
%  PTH: A cell-array of path items; order matters, as this list controls
%  the precedence of builtins with the same name and the availability of
%  builtins with assigned toolbox locations.

%   Copyright 2013-2023 The MathWorks, Inc.
    
    % Empty the cache
    matlab.depfun.internal.cacheWhich();
    
    % Load all the builtins from the database, normalizing their
    % paths to the MATLAB root.
    tbl = pcm_navigator.builtinRegistry;
    builtinSym = cellstr(keys(tbl))';
    v = values(tbl)';
    
    import matlab.depfun.internal.MatlabType
    import matlab.depfun.internal.requirementsConstants
    % G1228159
    % WHICH returns nothing for built-in packages, so they should not
    % shadow things. They are useless in the built-in cache.
    if ~isempty(v)
        type = [ v.type ];
        builtinPkgIdx = type == MatlabType.BuiltinPackage;
        v(builtinPkgIdx) = [];
        builtinSym(builtinPkgIdx) = [];
        type = type(~builtinPkgIdx);
        loc = {v.loc};
        
        builtinStr = strings(size(builtinSym));
        % Built-in class
        builtinClsIdx = type == MatlabType.BuiltinClass;
        builtinStr(builtinClsIdx) = strcat(builtinSym(builtinClsIdx), ...
                                    requirementsConstants.IsABuiltInMethodStr);
        % Built-in Function with non-empty location
        builtinFcnIdx = type == MatlabType.BuiltinFunction;
        emptyLocIdx = (loc == "");
        nonEmptyBuiltinFcnIdx = builtinFcnIdx & (~emptyLocIdx);
        builtinStr(builtinFcnIdx & (~emptyLocIdx)) = strcat(...
            requirementsConstants.BuiltInStr, ' (', ...
            loc(nonEmptyBuiltinFcnIdx), requirementsConstants.FileSep, ...
            builtinSym(nonEmptyBuiltinFcnIdx), ')');
        % Undocumented built-in
        undocumentedIdx = (builtinFcnIdx & emptyLocIdx) | ~(builtinClsIdx | builtinFcnIdx);
        builtinStr(undocumentedIdx) = strcat(requirementsConstants.BuiltInStr,...
                                        ' (undocumented)');

        % Preload the cache
        matlab.depfun.internal.cacheWhich(builtinSym, cellstr(builtinStr));    
    end
end

% LocalWords:  Preload PTH builtins concatenate
