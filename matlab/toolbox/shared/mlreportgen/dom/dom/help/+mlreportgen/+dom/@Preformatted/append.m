%append Append content to this preformatted paragraph
%     textObj = append(preObj, text) creates a DOM Text object 
%     containing the specified text string and appends it to this 
%     preformatted paragraph.
%
%     textObj = append(preObj, text, styleName) creates a DOM Text object
%     containing the specified text string and having the specified style 
%     and appends it to this preformatted paragraph.
%
%     obj = append(preObj, obj) appends any of the following types of 
%     objects to this preformatted paragraph:
%
%          • CustomElement
%          • ExternalLink
%          • Image
%          • InternalLink
%          • LinkTarget
%          • Text
%
%    Note: the custom element must be a valid HTML or DOCX child of this
%    preformatted paragraph, depending on whether the output type of the
%    document to which this preformatted paragraph is appended is HTML or
%    DOCX, respectively.

%    Copyright 2019 MathWorks, Inc.
%    Built-in function.
