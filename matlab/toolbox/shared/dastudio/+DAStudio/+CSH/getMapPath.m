function path = getMapPath(key)
    [shortname,group] = matlab.internal.doc.csh.findMapKey(key);
    if isempty(shortname) || shortname == ""
        path = group;
    else
        path = shortname + "/" + group;
    end
end

