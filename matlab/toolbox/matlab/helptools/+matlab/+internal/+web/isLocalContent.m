function local = isLocalContent(location)
    if ~isa(location, "matlab.net.URI")
        location = matlab.internal.web.resolveLocation(location);
    end
    local = ~isempty(location) && (location.Scheme == "file" || matches(location.Host, "localhost"|"127.0.0.1"));
end