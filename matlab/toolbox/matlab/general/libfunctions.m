function out=libfunctions(libname,full)
%LIBFUNCTIONS Return information on functions in a shared library.
%   M = LIBFUNCTIONS('LIBNAME') returns the names of all functions 
%   defined in the external shared library LIBNAME that has been 
%   loaded into MATLAB with the LOADLIBRARY function.  The return 
%   value, M, is a cell array of strings.
%
%   M = LIBFUNCTIONS('LIBNAME', '-full') returns a full description 
%   of the functions in the library, including function signatures.
%   This includes duplicate function names with different signatures.
%   The return value, M, is a cell array of strings.
%
%   See also LOADLIBRARY, LIBFUNCTIONSVIEW, CALLLIB, UNLOADLIBRARY.

%   Copyright 2003-2025 The MathWorks, Inc. 
if nargin > 0
    libname = convertStringsToChars(libname);
    if ischar(libname)
        libname = strrep(libname,'"','');
    end
end

if nargin > 1
    full = convertStringsToChars(full);
    if ischar(full)
        full = strrep(full,'"','');
    end
end

narginchk(1,2);

fulllibname = libname;
if ischar(libname) && ~startsWith(libname, 'lib.')
    fulllibname=['lib.' libname];
end

newNameRegexpr=libname;
if ischar(libname)
    newNameRegexpr="x" + upper(libname(1)) + libname(2:end);
end
if nargout==0
    if nargin==1
        meth=evalc('methods(fulllibname)');
        if ~isempty(meth) && ischar(libname)
            meth=regexprep(meth,newNameRegexpr,libname);
        end
        meth=trimspaces(meth);
    else
        meth=evalc('methods(fulllibname,full)');
        if ~isempty(meth) && ischar(libname)
            meth=regexprep(meth,newNameRegexpr,libname);
        end
        meth=trimspaces(meth,true);
    end
    meth=strrep(meth,getString(message('MATLAB:libfunctions:str_methodsforclasslib')), ...
                     [getString(message('MATLAB:libfunctions:str_functionsinlib')) ' ']);
    meth=strrep(meth,getString(message("MATLAB:ClassText:STATIC_METHODS_LABEL")),"");
    meth=strrep(meth,[getString(message('MATLAB:libfunctions:str_staticqualifier')) ' '],"");
    meth=strrep(meth,[' ' getString(message('MATLAB:libfunctions:str_scalarinput'))],"");
    disp(meth);
else
    if nargin==1
        out=methods(fulllibname);
        if ~isempty(out)
            out=regexprep(out,newNameRegexpr,libname);
        end
        out=trimspaces(out);
    else
        out=methods(fulllibname,full);
        if ~isempty(out)
            out=regexprep(out,newNameRegexpr,libname);
        end
        out=trimspaces(out,true);
    end
    if ~isempty(out)
        out=cellfun(@(x) replace(x,getString(message('MATLAB:libfunctions:str_staticqualifier'))+" ",""), ...
            out,'UniformOutput',false);
        out=cellfun(@(x) replace(x," "+getString(message('MATLAB:libfunctions:str_scalarinput')),""), ...
            out,'UniformOutput',false);
    end
end
end
function outstr=trimspaces(str,isfull)
    arguments(Input)
        str
        isfull (1,1) logical = false
    end
    if isempty(str)
        outstr=str;
        return
    end
    outstr=str;
    symbols='],) ';
    numSyms=4;
    if ~isfull
        numSyms=3;
    end
    for symbol=1:numSyms
        expression=" "+symbols(symbol);
        pat=regexpPattern(expression);
        outstr=replace(outstr,pat,symbols(symbol));
    end
end
