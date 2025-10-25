function choices = dependenciesToRemoveChoices(pkg)
deps = pkg.Dependencies;
choices = [deps.Name];
end