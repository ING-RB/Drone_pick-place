%FINDFILE  Search for file by name from context
%   f = FINDFILE(context, pathname)  searches for the file specified by 
%   pathname from the IntrospectionContext specified by context.
%   pathname can be a filename, a relative pathname, an absolute pathname,
%   or a URL. If found, FINDFILE returns a string containing the absolute
%   pathname (or URL) of the found file. If FINDFILE does not find a file,
%   it returns a 0x0 empty string array.
%
%   When pathname is a filename or relative pathname, FINDFILE searches for
%   it relative to the current folder, and from context as a partial pathname.
%
%   When pathname is an absolute pathname or a URL, FINDFILE checks if the
%   named file exists. If it does, FINDFILE returns pathname. If it does
%   not, FINDFILE returns a 0x0 empty string array.
%
%   FINDFILE(___, Name, Value) modifies the characteristics of the
%   search using one or more name-value arguments. You can specify one or
%   more name-value arguments in any order. If you do not specify the value
%   for a property, this function uses the default value.
%
%   FINDFILE Name-Value pairs:
%
%   Extensions        - List of file extensions. FINDFILE searches for a
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
%   Copyright 2024 The MathWorks, Inc.

function f = findFile(context, pathname, options)
    arguments (Input)
        context (1, 1) matlab.lang.IntrospectionContext
        pathname (1, 1) string
    end
    arguments(Input)
        options.Extensions (1,:) string {mustBeNonmissing(options.Extensions)} = [""]
    end
    arguments (Output)
        f (1, 1) string
    end

    f = context.findFileImpl(pathname, options);
end