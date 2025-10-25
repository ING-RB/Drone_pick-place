%INTROSPECTIONCONTEXT represents a "view" of all known MATLAB content that is visible 
%   from a specified location.
%
%   If the location is the MATLAB command line, then all visible content is defined 
%   by the MATLAB path. 
%   If the location is within a function/method defined in a file that is in a path 
%   folder, the visible content includes all names in scope for that function followed 
%   by the MATLAB path. 
% 
%   In other words:
%
%   All the nested, all the local functions, and classes defined in that same file.
%   All functions defined in a folder named "private" of the folder where the file 
%   is defined.
%   All invokable on-the-path symbols (including those provided by the interfaces of on-the-path packages)
%   Finally, if the location is within a function or method defined in a package-based file,
%   the visible content includes all names in scope for that function, followed by what can 
%   be seen using the three-tier lookup rules in place for modular name resolution.  
% 
%   In other words:
%
%   All the nested, all local functions, and classes defined in that same file.
%   All functions defined in a folder named "private" of the folder where the file
%   is defined.
%   All symbols in private, then public member folders of the same package.
%   All symbols in the public interface of packages upon which this one depends.
%   All invokable on-the-path symbols (including those provided by the interfaces of on-the-path packages),
%   if the package in question depends on/uses the path.
%
%   An Introspection object can be obtained in one of the following ways:
%
%   By asking for the current context.
%   By asking for a caller's context.
%   Based on a file or folder location.
%   For a given package.
%
%   The Introspection object defines methods that can then be used for the following introspection needs:
%
%   Given a specific namespace, give me all its classes, functions, or inner namespaces that are 
%   visible from the specified context.
%   Given a name of a class, resolve the class in the specified context and return a classID object.
%   Given the name of a function, class, script, model, or static method, resolve the name in the 
%   specified context and return a ResolvedSymbol object.
%   Given a name, resolve all possible matches for that symbol and return a ResolvedSymbol array.
%   In-MATLAB Execution Context Class.
%
%   Copyright 2024 The MathWorks, Inc.