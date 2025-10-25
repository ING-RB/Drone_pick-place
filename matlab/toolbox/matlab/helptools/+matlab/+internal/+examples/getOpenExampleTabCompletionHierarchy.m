function hierarchy = getOpenExampleTabCompletionHierarchy(partialStr)
    persistent productpkgInstalled supportpkgInstalled
    persistent componentList sfileList examplenameList
    
    productpkg = numel(dir(fullfile(docroot,'docCatalog','exampleapi')));
    supportpkg = numel(dir(fullfile(matlabshared.supportpkg.getSupportPackageRoot,'help','docCatalog','exampleapi')));
    if isempty(productpkgInstalled) || productpkgInstalled ~= productpkg ...
            || isempty(supportpkgInstalled) || supportpkgInstalled ~= supportpkg
        [componentList, sfileList, examplenameList] = makeChoices();
        productpkgInstalled = productpkg;
        supportpkgInstalled = supportpkg;
    end

    partialStr = strrep(partialStr,"\","/");

    sw = @(x) startsWith(x,partialStr,'IgnoreCase',true);

    values = examplenameList(sw(examplenameList));
    if ~contains(partialStr, "/")
        components = componentList(sw(componentList));
        sfiles = sfileList(sw(sfileList));
        if ~isscalar(components) || numel(sfiles) > 0
            values = [components; sfiles];
        end
    end
    hierarchy = createHierarchyStruct(values);

    function s = createHierarchyStruct(list)
        s = struct('name',cellstr(list),'separator','#','isleaf',true);
    end

    function [componentList, sfileList, examplenameList] = makeChoices()
        exData = matlab.internal.example.api.FindAllExampleData();
        exComps = [exData.Component];
        exNames = [exData.Name];
    
        componentList = unique(exComps') + "/";
        sfileList = unique([exData.SupportingFiles]');
        examplenameList = (exComps+"/"+exNames)';
    end
end
