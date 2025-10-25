function resolveddirs = resolveAnyPackages(context, varargin)
    %RESOLVEANYPACKAGES Resolve package specifiers into package root folders.
    %   RESOLVEANYPACKAGES('PATH', PKGSPEC) resolves PKGSPEC into a package on
    %   the MATLAB Search Path and returns its root folder.
    %
    %   RESOLVEANYPACKAGES('INSTALLED', PKGSPEC) resolves PKGSPEC into an
    %   installed MATLAB Package and returns its root folder.

    %   Copyright 2023 The MathWorks, Inc.

    resolveddirs = varargin;

    if ~matlab.internal.feature('packages')
        return;
    end

    n = length(varargin);
    for i = 1:n
        sz = size(varargin{i});
        if sz(1) ~= 1 || ~ischar(varargin{i}) || isfolder(varargin{i})
            continue;
        end

        try
            packageID = matlab.package.internal.resolvePackageSpecifier(varargin{i}, context);
        catch ex
            switch ex.identifier
                case 'mpm:arguments:EmptyPackageSpecifier'
                    continue;
                case 'mpm:arguments:InvalidPackageSpecifier'
                    continue;
                otherwise
                    warning(ex.identifier, '%s', ex.message);
                    [resolveddirs, n] = removeElementInLoop(resolveddirs,i,n);
                    continue;
            end
        end

        % warn on attempt to resolve nonmodular package specifier
        if any(ismissing(packageID)) && strcmp(context, 'path')
            try
                packageID = matlab.package.internal.resolvePackageSpecifier(varargin{i}, 'installed');
            catch
                continue
            end

            if packageIsNotModular(packageID)
                warning('MATLAB:mpath:packageIsNotModular', ...
                    'Specified package is not modular: %s', varargin{i});
                [resolveddirs, n] = removeElementInLoop(resolveddirs,i,n);
            end

            continue;
        end

        if any(ismissing(packageID))
            continue;
        end

        package = matlab.mpm.internal.info(packageID);

        if ~package.Modular
            warning('MATLAB:mpath:packageIsNotModular', ...
                'Specified package is not modular: %s', varargin{i});
            [resolveddirs, n] = removeElementInLoop(resolveddirs,i,n);
            continue;
        end

        resolveddirs{i} = convertStringsToChars(package.InstallationLocation);
    end
end

function [arr,loopCounter] = removeElementInLoop(arr,idx,loopCounter)
    arr(idx) = [];
    loopCounter = loopCounter-1;
end

function notModular = packageIsNotModular(packageID)
    notModular = false;

    if any(ismissing(packageID))
        return;
    end

    package = matlab.mpm.internal.info(packageID);

    notModular = ~package.Modular;
end