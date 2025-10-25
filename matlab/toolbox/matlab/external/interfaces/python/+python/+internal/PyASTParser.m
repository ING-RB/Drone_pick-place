classdef PyASTParser
%PYASTPARSER Statically analyzes Python code.
%
%   FOR INTERNAL USE ONLY -- This function is intentionally undocumented
%   and is intended for use only within the scope of functions and classes
%   in the MATLAB external interface to Python. Its behavior may change, 
%   or the function itself may be removed in a future release.
%
% Description
% 
%    PyASTParser class is instantiated with a Python file or a string containing valid 
%    Python code. The object then can bu used for statically analyzing the underlying
%    Python script using the Python ast module.
%
% Methods
%
%    PyASTParser                  - constructor. Takes a filename or a
%                                   string containing Python code
%    getIOTypes                   - Returns a cell array of py.dict objects, each containing
%                                   the name of the functions/methods and the inputs and outputs in
%                                   provided file.
%    getImports                   - Returns a string array of imported modules in the provided file.
%    getImportsFromInitFile       - Returns a string array of imported modules in the provided file. The
%                                   file is expected to be __init__.py
%    getVars                      - Returns a struct containing the names of the undefined variables, possibly
%                                   used to pass MATLAB workspace variables (mlvars), and names of the 
%                                   Python varibles generated in the provided Python code.
% Example
%
%    p = python.internal.PyASTParser('somefile.py');
%    a = p.getIOTypes();

% Copyright 2023 The MathWorks, Inc.

    properties
        Filename
        Code
    end

    methods (Access = protected)
        function validatePyFilename(obj, filename)
            if (~exist(filename, "file"))
                error("MATLAB:Pyrunfile:FileNotFound", filename);
            end
        end
    end
    methods
        function obj = PyASTParser(pyscript, inputtype)
            arguments
                pyscript(1,:) string { mustBeText }
                inputtype(1,1) string { mustBeTextScalar } = "file"
            end
            
            if (strcmpi(inputtype, "file"))
                obj.validatePyFilename(pyscript);
            end

            if nargin == 1
                obj.Filename = pyscript;
            elseif nargin == 2
                if (inputtype == "code")
                    obj.Code = pyscript;
                elseif (inputtype == "file")
                    obj.Filename = pyscript;
                end
            end
        end

        function out = getIOTypes(obj)
            res = py.pyastparser.getIOTypes(obj.Filename);
            out = cell(res);
        end

        function out = getImports(obj)
            res = py.pyastparser.getImports(obj.Filename);
            out = string(res);
        end

        function out = getImportsFromInitFile(obj)
            res = py.pyastparser.getImportsFromInitFile(obj.Filename);
            out = string(res);
        end

        function out = getVars(obj)
            res = py.pyastparser.getVars(py.str(obj.Code));
            out = struct(res);
        end
    end
end