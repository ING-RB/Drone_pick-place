%append Append MATLAB or DOM objects to a document
%    domObj = append(docObj,domObj) appends a DOM object to the document 
%    and returns the appended object. The appended object can be any of 
%    the following mlreportgen.dom types:
%
%         * Container
%         * CustomElement
%         * DOCXPageLayout
%         * FormalTable
%         * Group
%         * HorizontalRule
%         * HTML
%         * HTMLFile
%         * HTMLPage (only for Document of output type HTML-MULTIPAGE)
%         * ExternalLink
%         * Image
%         * InternalLink
%         * LineBreak
%         * LinkTarget
%         * MATLABTable
%         * NumPages
%         * OrderedList
%         * Page
%         * PageBreak
%         * PageRef
%         * Paragraph
%         * PDFPageLayout
%         * RawText
%         * StyleRef
%         * Table
%         * Text
%         * UnorderedList
%
%    Note: If the object to be appended is an inline object, such as text,
%    image, or hyperlinks, and the document output type is HTML, this
%    method appends the inline object to the document. If the output type
%    is Word or PDF, this method wraps the inline object in a paragraph
%    object and appends the paragraph to the document. This is done because
%    Word and HTML permit inline objects only in paragraph objects.
%
%    partObj = append(docObj,partObj) appends a DocumentPart object to 
%    this object. If the part is still open, the append method closes it.
%    This means that you cannot continue to add content to a part once it 
%    has been appended to a document.
%
%    textObj = append(docObj,'text') creates a Text object from the
%    specified text string. If the document output type is HTML, this
%    method appends the text object to the list. If the output type is Word
%    or PDF, this method wraps the text object in a paragraph object and
%    appends the paragraph object to the document. This is done because
%    text objects can occur only in paragraphs in Word and PDF documents.
%
%    textObj = append(docObj,'text','styleName') creates a Text object
%    having the style 'styleName'. If the document output type is HTML,
%    this method appends the text object to the document. If the output
%    type is Word or PDF, this method wraps the text object in a paragraph
%    object and appends the paragraph object to the document. This is done
%    because text objects can occur only in paragraphs in Word and PDF
%    documents.
%
%    olObj = append(docObj,olObj,styleName) appends an OrderedList object
%    having the style styleName.
%
%    ulObj = append(docObj,unorderedList,styleName) appends an object of
%    type UnorderedList having the style named by styleName.
%
%    ulObj = append(docObj,array) creates an UnorderedList object from a 
%    1D horizontal array of double values, 1D array of strings or a 
%    1D categorical array, appends it to the document, and returns the 
%    appended unorderedList.
%
%    ulObj  = append(docObj,array,styleName) creates an UnorderedList object 
%    having the style styleName from a 1D horizontal array of double values,  
%    1D cell array of strings or 1D categorical array and appends the 
%    unorderedList to the document.
%
%    tableObj = append(docObj,array) creates a Table object from a 
%    2D array of double values, 2D array of strings or a 2D categorical array,
%    appends it to the document, and returns the appended table.
%
%    tableObj  = append(docObj,array,styleName) creates a Table object 
%    having the style styleName from a 2D array of double values,  
%    2D cell array of strings or 2D categorical array and appends the table
%    to the document.
%
%    tableObj = append(docObj,header,body) creates a FormalTable object 
%    from header, a cell array of strings constituting the table's header, 
%    and body, a numeric array of doubles, a cell array of strings or a 
%    categorical array constituting the table's body, and appends the 
%    resulting table to the document.
%
%    tableObj = append(docObj,header,body,styleName) creates and appends a  
%    FormalTable having the style styleName.
%
%    paraObj = append(docObj,paraObj,pageLayoutObj) appends a 
%    paragraph to a document and starts a new page layout section
%    whose properties are specified by a PageLayout object.
%
%    Note: The append method of the DOM API accepts any MATLAB object. If
%    the object is not a type that can be formatted, the append method
%    converts it to a text string containing the object's class name,
%    e.g., rptgen.crg_comment. This behavior allows a client to include any
%    MATLAB object in a report if only as the name of its class.

%    Copyright 2013-2024 The MathWorks, Inc.
%    Built-in function.
