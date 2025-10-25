function generateCPP(headerFile, nameValuePairs)
%generateCPP Generate a C++ strongly typed interface to MATLAB code
%   generateCPP(headerFile, Namespaces=namespaceNames, Classes=classNames, Functions=functionNames, ...)
%      Generate a C++ header file with path, name, and extension used in
%      headerFile. If the file already exists, it is overwritten. The
%      header file contains a strongly typed interface to any combination
%      of supported MATLAB classes or functions. Supported MATLAB classes
%      are user-authored, and may only inherit from other supported
%      classes. For example, handle classes are not supported. Supported
%      MATLAB functions are user-authored as well. At least one MATLAB
%      class, function, or namespace (containing the same) must be specified
%      for generation by using the appropriate name-value argument.
%      Namespace, class, and function names must be valid and on the MATLAB
%      path. Argument and property size and type validation data are used
%      in the header file where possible. The number of generated class
%      and functions in the interface is printed to the MATLAB console.
%      Once the strongly typed interface is generated, it can then be built
%      and run in a C++ application which uses the C++ versions of the
%      MATLAB classes or functions. Calling or using the C++ versions will
%      result in a corresponding call into MATLAB, where implementation and
%      class instance data reside.
%
%        Name                                Value
%   -------------   -------------------------------------------------------
%   Namespaces      string vector - A list of MATLAB namespace names.
%                   All supported MATLAB classes and functions contained in
%                   the listed namespaces and their sub-namespaces are
%                   included in the interface. All namespaces names specified
%                   must be valid and present on the MATLAB path.
%
%   Classes         string vector - A list of MATLAB class names. All
%                   supported MATLAB classes specified are included in the
%                   interface. All class names specified must be valid and
%                   present on the MATLAB path.
%
%   Functions       string vector - A list of MATLAB function names. All
%                   supported MATLAB function names specified are included
%                   in the interface. All function names specified must be
%                   valid and present on the MATLAB path.
%
%   DisplayReport   logical scalar - If specified as true or 1, a report
%                   describing the generated interface is displayed in the
%                   MATLAB command window. Otherwise, the report is not
%                   displayed. The report contains, but is not limited to,
%                   detailed information about what was generated to, or
%                   omitted from, the strongly typed interface. Hints
%                   where MATLAB definitions could be more strongly typed,
%                   thereby making the generated interface more strongly
%                   typed, are provided as well.
%
%   SaveReport      string - A file. A path prefix and file extension may
%                   be included in the string. If specified, a report is
%                   written to the assigned file. If the file already
%                   exists, the report is appended. The report contains
%                   content identical to the report described in the
%                   DisplayReport name-value argument, although
%                   DisplayReport and SaveReport can be specified
%                   independently.
%
%   Examples:
%
%   % Create a C++ strongly typed interface to a MATLAB function called myFunc
%   matlab.engine.typedinterface.generateCPP("myHeader.hpp", Functions="myFunc")
%
%   % Create a C++ strongly typed interface to a MATLAB class inside the
%   % myNamespace MATLAB namespace. The full class name is myNamespace.myClass
%   matlab.engine.typedinterface.generateCPP("myHeader.hpp", Classes="myNamespace.myClass")
%
%   % Create a C++ strongly typed interface to two specific functions,
%   % two specific classes, and all the MATLAB classes and functions in
%   % a specific namespace
%   matlab.engine.typedinterface.generateCPP("myHeader.hpp", ...
%      Namespaces = "myNamespace", ...
%      Classes   = ["myClass1" "myClass2"], ...
%      Functions = ["myFunc1" "myFunc2"])

%   Copyright 2021-2023 The MathWorks, Inc.

    arguments
        headerFile (1,1) string {mustBeNonzeroLengthText}
        nameValuePairs.Namespaces (:,1) string = []
        nameValuePairs.Packages  (:,1) string = []
        nameValuePairs.Classes   (:,1) string = []
        nameValuePairs.Functions (:,1) string = []
        nameValuePairs.DisplayReport   (1,1) logical = 0
        nameValuePairs.SaveReport      {mustBeTextScalar} = ""
    end

    try
        % Call the MathWorks-internal implementation using forwarded
        % name-value pairs
        nvPairsCell = namedargs2cell(nameValuePairs);
        matlab.internal.engine.generateTypedInterfaceCPP(headerFile, nvPairsCell{:});
    catch exception
        % Simplify call stack if errors are encountered
        throwAsCaller(exception)
    end

end