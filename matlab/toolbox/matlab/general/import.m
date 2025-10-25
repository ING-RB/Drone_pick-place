%   import Adds to the current namespaces and classes import list.
%   import NamespaceName.ClassName adds the fully qualified class name to 
%   the import list.
%
%   import NamespaceName.FunctionName adds the specified namespace-defined
%   function to the current import list.
%
%   import NamespaceName.* adds the specified namespace to the current
%   import list.
%
%   import Namespace1.ClassName1 Namespace2.ClassName2 ... adds multiple 
%   fully qualified class names.
%
%   import Namespace1.* Namespace2.* ... adds multiple namespaces.
%
%   Use the functional form of import, such as import(S), when the namespace
%   or class name is stored in a string.
%
%   L = import(...) returns as a cell array of character row vectors the 
%   contents of the current import list as it exists when import completes.
%   L = import, with no inputs, returns the current import list without
%   adding to it.
%
%   import allows your code to refer to an imported class or function using
%   fewer or no namespace prefixes.
%
%   import affects only the import list of the function or script within 
%   which it is used.  There is also a base import list that is used at the 
%   command prompt. When an import is used at the command prompt it affects  
%   the base import list.
%
%
%   clear import clears the base import list.  The import lists of
%   functions may not be cleared.
%
%   Examples:
%   %Example 1: add the containers.Map class to the current import list
%       import containers.Map
%       myMap = Map('KeyType', 'char', 'ValueType', 'double');
%
%   %Example 2: import two Java packages 
%       import java.util.Enumeration java.lang.String
%       s = String('hello');     % Create a java.lang.String object
%       methods Enumeration      % List the java.util.Enumeration methods
%
%   %Example 3: add the java.awt.* package to the current import list
%       import java.awt.*
%       f = Frame;               % Create a java.awt.Frame object
%
%IMPORTING DATA
%   You can also import various types of data into MATLAB.  This includes
%   importing from MAT-files, text files, binary files, and HDF files.  To 
%   import data from MAT-files, use the load function.  To use the
%   graphical user interface to MATLAB's import functions, type uiimport.
%
%   For further information on importing data, see Import and Export Data
%   in the MATLAB Help Browser under the following headings:
%
%       MATLAB -> Programming Fundamentals
%       MATLAB -> External Interfaces -> Programming Interfaces
%
%   See also clear, load.

%   Copyright 1984-2023 The MathWorks, Inc.
%   Built-in function.
