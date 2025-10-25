%mlreportgen.utils.makeSingleLineText converts its input to a single line of text.
%   singleLineText = mlreportgen.utils.makeSingleLineText(in, delim)
%   converts its input to a single line of text. The output depends on
%   its input.
%          Input                                Output
%       char array         - character array with line feeds and carriage returns removed
%       string             - string with line feeds and carriage returns removed
%       string array       - string with line feeds and carriage returns
%                            removed and every entry in the array is separated using the
%                            delimiter.
%       cell array of char - character array with with line feeds and carriage returns removed
%                            removed and every entry in the array is separated using the
%                            delimiter.
%       numeric array      - character array with line feeds and carriage returns removed
%
%   If the delimiter is specified each linefeed and carriage return is
%   replaced by the delimiter. If delimiter is not specified, it is treated with
%   a single space. Delimiter can be a scalar string or a char array. 
%
%   Example
%
%   mlreportgen.utils.makeSingleLineText(['Hello', newline, 'world']);
%   In the above example newline will be replaced with space that
%   generates the output as "Hello world".
%
%   mlreportgen.utils.makeSingleLineText(['Hello', newline, 'world'], ',');
%   In the above example newline will be replaced with comma that
%   generates the output as "Hello,world".

     
    %   Copyright 2017-2018 The MathWorks, Inc.

