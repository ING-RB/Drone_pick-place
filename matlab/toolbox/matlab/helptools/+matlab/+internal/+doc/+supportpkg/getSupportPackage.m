function spkg = getSupportPackage(id)
    spkgs = matlab.internal.doc.supportpkg.loadSupportPackages;

    for field = ["basecode", "display_name"]
        if ~isfield(spkgs, field)
            continue;
        end

        spkg = spkgs(string({spkgs.(field)}) == id);
        if isscalar(spkg)
            return;
        end
    end

    spkg = struct("display_name", {}, ...
                  "basecode", {}, ...
                  "required_products", {}, ...
                  "product_family", {}, ...
                  "landing_page", {}, ...
                  "base_product_basecode", {});
end
% Copyright 2024 The MathWorks, Inc.
