function choices = dependenciesToAddChoices(pkg)
deps = matlab.mpm.internal.mpmListStringChoices;
if(~isempty(pkg.Dependencies))
    deps= deps(~ismember(deps, pkg.Dependencies.Name) & ~strcmp(deps, pkg.Name));
end
choices = deps;
end