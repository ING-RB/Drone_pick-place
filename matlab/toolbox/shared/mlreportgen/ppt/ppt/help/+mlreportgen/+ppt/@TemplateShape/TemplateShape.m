%mlreportgen.ppt.TemplateShape Shape from the template presentation
%    Specifies a shape parsed from the template presentation. In the PPT
%    API, when the template presentation slide contains a table or a
%    picture, the API creates the corresponding template shape object of
%    type TemplateTable or TemplatePicture.
%
%    TemplateShape properties:
%        XMLMarkup  - XML markup of template shape
%        Name       - Template shape name
%        X          - Upper-left x-coordinate position of template shape
%        Y          - Upper-left y-coordinate position of template shape
%        Width      - Width of template shape
%        Height     - Height of template shape
%        Style      - Template shape formatting
%        Children   - Children of this PPT API object
%        Parent     - Parent of this PPT API object
%        Id         - ID for this PPT API object
%        Tag        - Tag for this PPT API object
%
%    See also mlreportgen.ppt.TemplateTable,
%    mlreportgen.ppt.TemplatePicture

%    Copyright 2019 The MathWorks, Inc.
%    Built-in class

%{
properties
     %XMLMarkup XML markup of template shape
     %     Specifies the XML markup of this shape read from the template
     %     presentation. If you update the XML markup, the updated markup
     %     is written out to the generated presentation. If the other
     %     properties such as Name, X, Y, Height, or Width are also set,
     %     the corresponding attributes in the XML markup are updated
     %     before the markup is written out to the generated presentation.
     XMLMarkup;
end
%}