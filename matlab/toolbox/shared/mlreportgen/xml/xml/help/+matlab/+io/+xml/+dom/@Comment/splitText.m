%splitText Splits this comment in two
%    newNode = splitText(thisComment,index) splits this comment into two
%    comments at the specified zero-based index and returns the new
%    comment. After the split, this comment contains the original text up
%    to the index. The new comment contains the original text from the
%    index. If the index equals the length of the original text, the new
%    comment is empty. If this comment has a parent, the new comment is
%    inserted in the parent following this comment.
%
%    See also matlab.io.xml.dom.Comment.setData

%    Copyright 2020 MathWorks, Inc.
%    Built-in function.