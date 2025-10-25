%mlreportgen.dom.EmbeddedObject Embed a file into a document
%    obj = EmbeddedObject() creates an empty EmbeddedObject element.
%
%    obj = EmbeddedObject(path) creates a DOM object that embeds an
%    external (non-DOM) object, such as an Excel spreadsheet, in a DOM
%    document. The path argument specifies a file that defines the external
%    object. The EmbeddedObject can be appended to the following types of
%    DOM objects:
%  
%    * Document
%    * DocumentPart
%    * Paragraph
%    * TableEntry
%    * TableHeaderEntry
%    * ListItem
%
%    The effect of appending the EmbeddedObjectobject to a DOM object
%    depends on the document output type and the external object type:
%
%    ---------------------------------------------------------------
%   | Document    | External    |                                  |
%   | Output Type | Object Type | Action                           |
%   |---------------------------------------------------------------
%   | DOCX        | XLSX, PPTX, | Embed external object file in    |
%   |             | DOCX        | document and insert Object       |
%   |             |             | Linking and Embedding (OLE) link |
%   |             |             | to embedded file. This causes    |
%   |             |             | Word to replace the OLE link     | 
%   |             |             | with the embedded content, e.g., |
%   |             |             | an Excel spreadsheet.            |
%   |--------------------------------------------------------------|
%   | DOCX        | Any except  | Insert a hyperlink to the        |
%   |             | XLSX, PPTX, | external object path.            |
%   |             | DOCX        |                                  |
%   |--------------------------------------------------------------|
%   | HTML        | Any         | Embed external object file in    |
%   |             |             | the document and insert a        |
%   |             |             | hyperlink to the embedded file.  |
%   |--------------------------------------------------------------|
%   | PDF         | Any         | Embed external object file in    |
%   |             |             | the document and insert an       |
%   |             |             | annotation with a paperclip      |
%   |             |             | icon. Double click the icon to   |
%   |             |             | open the embedded file.          |
%   |--------------------------------------------------------------|
%   | single-file | Any         | Insert hyperlink to file at path |
%   | HTML        |             |                                  |
%   |--------------------------------------------------------------|
%
%    obj = EmbeddedObject(target, linkText) creates an EmbeddedObject
%    component that uses the specified linkText character vector or string
%    as text for the link inserted into the document.
%
%    obj = EmbeddedObject(target, linkText, styleName) creates an
%    EmbeddedObject component that uses the specified linkText and
%    styleName to create a Text object that is used as text for the link
%    inserted into the document.
%
%    obj = EmbeddedObject(target, linkTextObj) creates an EmbeddedObject
%    component that uses the specified linkTextObj as text for the link
%    inserted into the document.
%
%    Note: Opening a document in Word without using the rptview function
%    causes OLE objects to display a placeholder image rather than the
%    contents of the file. To replace the image with the content
%    double-click the placeholder image, or open the document with the
%    rptview function.
%
%
%    EmbeddedObject methods:
%        append         - Append text and images to this document reference
%        clone          - Clone this document reference
%
%    EmbeddedObject properties:
%        Target             - Path of document targeted by this reference
%        StyleName          - Name of element's stylesheet-defined style
%        Style              - Formats that define this element's style
%        CustomAttributes   - Custom element attributes
%        Parent             - Parent of this element
%        Children           - Children of this element
%        Tag                - Tag of this element
%        Id                 - Id of this element
%
%    Example:
%
%    import mlreportgen.dom.*
%    
%    info = Document('CompanyInfo', 'docx');
%    append(info, 'XYZ, Inc., makes widgets.');
%    close(info);
%    
%    infoPath = info.OutputPath;
%    
%    rpt = Document('Report', 'docx');
%    open(rpt);
%    
%    para = append(rpt, Paragraph('About XYZ, Inc.'));
%    
%    append(rpt, EmbeddedObject(infoPath));
%    
%    close(rpt);
%    rptview(rpt);

%    Copyright 2019-2020 Mathworks, Inc.
%    Built-in class