function str = num2str(numbers)
%This function is for internal use only. It may be removed in the future.

%num2str
%   numbers is an N-by-1 or 1-by-N vector
%   str is 1XM string containing integer numbers and white spaces between them. 
%   str can be a string with maximum of 10000 characters. This function is 
%   used in PoseGraphBase class. num2str doesn't support codegeneration. 
%   To support codegeneration of PoseGraphBase class this function is required. 
%   This function can be used as codegenable variant of num2str in robotics.

%   Copyright 2018-2019 The MathWorks, Inc.

%#codegen

% num2str doesn't support codegen. So using sprintf for
% creating string from num arrary.
if ~isempty(numbers)
    coder.varsize('numstring', [1, inf], [0, 1]);
    % charArray is a char array containing numbers and white spaces between them
    charArray = blanks(10000);
    count = 1;
    %Number of white spaces between numbers
    whiteSpaces = '  ';
    %Number of white spaces
    numSpaces = length(whiteSpaces);
    %sprintf conversion command (stringnum + whitespaces + stringnum + whitespaces ...)
    cmd = ['%d',whiteSpaces];
    % sprintf doesn't support codegen for vector input.
    % Using a for loop to create invaliIds string required
    % for creating the error message.
    for k = 1:length(numbers)
        numstring = sprintf(cmd,int16(numbers(k)));
        charArray(count:(count+length(numstring)-1)) = numstring;
        count = count + length(numstring);
    end
    %count points to the next character index. We only need till the current
    %character index. We don't need white spaces at the end. So only
    %giving required segment as output.
    str = charArray(1:(count-(numSpaces+1)));
else
    % if the input is an empty matrix then outputs a white space string
    str = blanks(1);
end
end
