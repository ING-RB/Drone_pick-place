function itemOut = makePathAbsolute(item)
    arguments
        item char
    end

    if ~matlab.depfun.internal.PathNormalizer.isfullpath(item)
        item = fullfile(pwd,item);
    end
    itemOut = string(item);

    % If non existant item/folder happens to be: /full/path/to/helloworld
    % But the following happens to be there: /full/path/to/helloworld.m
    % We end up here, but _canonicalizepath will error.
    try %#ok<TRYNC>
        itemOut = string(builtin("_canonicalizepath", item));
    end
end