function tf = isNETSupported()
%NET.isNETSupported returns true if a supported version of .NET 6 or higher
%  or the Microsoft(R) .NET Framework is found on Microsoft(R) Windows
%  platform, otherwise returns false.
%
%  If MATLAB is configured to use .NET Core, NET.isNETSupported returns true
%  when the .NET 6.0 Runtime or higher is found. Otherwise, returns false.
%
%  If MATLAB is configured to use the Microsoft(R) .NET Framework,
%  NET.isNETSupported returns true when a supported version of the .NET 
%  Framework is found on Windows. Otherwise, returns false.
%
%  Example:
%  A = NET.isNETSupported;
%
%  See also DOTNETENV
 
% Copyright 2009-2024 The MathWorks, Inc.
try
    x = which("System.String");
    tf = ~isempty(x);
catch
    tf = false;
end
