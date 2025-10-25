function fullText = stripLineContinuations(fullText)
%

%   Copyright 2018-2020 The MathWorks, Inc.

    fullText = regexprep(fullText, "('[^'\n]*')|(""[^""\n]*"")|(%.*)|()\.{3}.*\n", '$1', 'dotexceptnewline');
end
