function f = findfile(pathname, scope, options)
    % FINDFILE Search for file by name
    %   f = FINDFILE(pathname)  searches for the file specified by pathname.
    %   pathname can be a filename, a relative pathname, an absolute pathname,
    %   or a URL. If found, FINDFILE returns a string containing the absolute
    %   pathname (or URL) of the found file. If FINDFILE does not find a file,
    %   it returns a 0x0 empty string array.
    %
    %   When pathname is a filename or relative pathname, FINDFILE searches for
    %   it relative to the current folder, and on the MATLAB Search Path as a
    %   partial pathname.
    %
    %   When pathname is an absolute pathname or a URL, FINDFILE checks if the
    %   named file exists. If it does, FINDFILE returns pathname. If it does
    %   not, FINDFILE returns a 0x0 empty string array.
    %
    %   FINDFILE(pathname, scope) searches the specified scope instead of
    %   the MATLAB Search Path and current folder.
    %   *scope* could be specified as one of the followings:
    %       "matlabpath"(default): The MATLAB Search Path and relative to the
    %                              current folder.
    %       "pkgpath"            : The search path of the current package.
    %       "pkginterface"       : The interface of the current package
    %   Specifying "pkgpath" or "pkginterface" when there is no current package
    %   and no Package name-value pair argument (see below) is an error.
    %
    %   FINDFILE(___, Name, Value) modifies the characteristics of the
    %   search using one or more name-value arguments. You can specify one or
    %   more name-value arguments in any order. If you do not specify the value
    %   for a property, this function uses the default value.
    %
    %   FINDFILE Name-Value pairs:
    %
    %   Package           - Specify the package to search instead of the current
    %                       package (see scope).
    %                       This option is unsupported when scope is "matlabpath".
    %                       Package specifier, specified as a string containing
    %                       a package name or as a package specifier of the form
    %                       Name[@version-range][@id] where:
    %
    %                         - Name is the name attribute of a package followed.
    %                         - [@version-range] can optionally be added to
    %                           specify packages with a matching version-range.
    %                         - @id: can optionally be added to specify packages
    %                           with a matching id property.
    %
    %                       For example, myPackage, myPackage@1.2.3, and
    %                       myPackage@1.2.3@6b2c2af2-8fff-11ec-b909-0242ac120002
    %                       are valid package specifiers.
    %
    %                       This syntax allows user to disambiguate packages with
    %                       the same name, or multiple installation of different
    %                       versions of the same package.
    %                       (default) missing
    %
    %   Extension         - List of file extensions. FINDFILE searches for a
    %                       file name with one of the specified extensions.
    %                       If FINDFILE finds more than one match in the same
    %                       folder, it gives precedence to earlier extensions
    %                       on the extensions list.
    %                       Valid extensions:     ".ext", "ext", ".", ""
    %                       Invalid extensions:   ".ext.1", "..", "ext."
    %                       If pathname already has an extension, FINDFILE
    %                       ignores this argument.
    %                       (default) [""]
    %
    %   Example 1:
    %        A package author can place the config.xml file into the private
    %        member folders of the package. To refer to this file inside the
    %        same package, the author can use:
    %        f = findfile("config.xml", "pkgpath")
    %
    %   Example 2:
    %        A package user can find the data file exported by the package
    %        "Nets" with:
    %        f = findfile("net.mat", "pkginterface",Package="Nets");
    %
    %   Example 3:
    %        A package author can take a string representing a filename from
    %        the user, the string may or may not contain necessary extensions
    %        expected by the function. The author can use:
    %        f = findfile(userInput, Extensions=[".xlsx",".csv"])
    %

    %   Copyright 2024 The MathWorks, Inc.
    arguments
        pathname (1,1) string
        scope (1,1) matlab.internal.introspection.findfile.ScopeEnum = "matlabpath"
        options.Package (1,1) string = missing
        options.Extensions (1,:) string {mustBeNonmissing(options.Extensions)} = [""]
    end

    if ~matlab.internal.feature("packages") && scope ~= "matlabpath"
        error(message('MATLAB:findfile:FeatureMatlabPackageOff'));
    end

    if scope == "matlabpath"
        if (~ismissing(options.Package))
            error(message('MATLAB:findfile:InvalidArgumentsCombination'));
        end
    end

    f = matlab.internal.introspection.bnFindFile(pathname, string(scope), options);
