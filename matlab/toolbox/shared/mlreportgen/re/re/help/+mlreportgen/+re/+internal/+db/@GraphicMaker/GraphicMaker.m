%mlreportgen.re.internal.db.GraphicMaker Generate DocBook XML graphics
%    gm = GraphicMaker(doc,file) creates an object that generates the
%    DocBook graphics element for the specified image file.
%
%    GraphicMaker properties:
%      ParentDocument   - MAXP Document
%      File             - Graphics file
%      Title            - Graphics title
%      Caption          - Graphics caption
%      IsInline         - Whether graphics is inline
%      Width            - Graphics width
%      Height           - Graphics height
%      ContentWidth     - Graphics content width
%      ContentHeight    - Graphics content height
%      Align            - Graphics alignment
%      ScaleFit         - Whether graphics is scaled to fit
%
%    GraphicMaker methods:
%      getFile          - Get graphics file path
%      setFile          - Set graphics file path
%      getTitle         - Get graphics title
%      setTitle         - Set graphics title
%      getCaption       - Get graphics caption
%      setCaption       - Set graphics caption
%      getInline        - Whether graphics is inline
%      setInline        - Specify whether graphics is inline
%      getWidth         - Get graphics width
%      setWidth         - Set graphics width
%      getHeight        - Get graphics height
%      setHeight        - Set graphics height
%      getContentWidth  - Get graphics content width
%      setContentWidth  - Set graphics content width
%      getContentHeight - Get graphics content height
%      setContentHeight - Set graphics content height
%      getAlign         - Get graphics alignment
%      setAlign         - Set graphics alignment
%      getScaleFit      - Whether graphics scales to fit
%      setScaleFit      - Specify whether graphics scales to fit
%      addArea          - Add area region
%      addCallout       - Add callouts
%      createGraphic    - Create graphics
%
%    See also mlreportgen.re.internal.db.TableMaker,
%    mlreportgen.re.internal.db.ListMaker

% Copyright 2021 MathWorks, Inc.

%{
properties

     % ParentDocument MAXP document
     %   The value of this property is a matlab.io.xml.dom.Document object
     %   that is used to create the graphics.
     %
     %   See also matlab.io.xml.dom.Document
     ParentDocument;

     % File Graphics file
     %   Path of a graphics file, specified as a character vector or string
     %   scalar.
     File;

     % Title Graphics title
     %   Title of the graphics to be made, specified as a character vector,
     %   string scalar, or matlab.io.xml.dom.Node object.
     %
     %   See also matlab.io.xml.dom.Node
     Title;

     % Caption Graphics caption
     %   Caption of the graphics to be made, specified as a character
     %   vector or string scalar.
     Caption;

     % IsInline Whether graphics is inline
     %   The value of this property is a logical. False (default)
     %   specifies that the graphics is not inline.
     IsInline;

     % Width Graphics width
     %   Width of the graphics to be made, specified as a character vector,
     %   string scalar, or positive double value.
     %
     %   See also https://tdg.docbook.org/tdg/4.5/imagedata.html
     Width;

     % Height Graphics height
     %   Height (depth) of the graphics to be made, specified as a
     %   character vector, string scalar, or positive double value.
     %
     %   See also https://tdg.docbook.org/tdg/4.5/imagedata.html
     Height;

     % ContentWidth Graphics content width
     %   Content width of the graphics to be made, specified as a character
     %   vector, string scalar, or positive double value.
     %
     %   See also https://tdg.docbook.org/tdg/4.5/imagedata.html
     ContentWidth;

     % ContentHeight Graphics content height
     %   Content height (depth) of the graphics to be made, specified as a
     %   character vector, string scalar, or positive double value.
     %
     %   See also https://tdg.docbook.org/tdg/4.5/imagedata.html
     ContentHeight;

     % Align Graphics alignment
     %   Horizontal alignment of the graphics to be made, specified as a
     %   character vector or string scalar. Valid values are:
     %
     %     "Left"
     %     "Center"
     %     "Right"
     %     "Auto"
     %
     %   See also https://tdg.docbook.org/tdg/4.5/imagedata.html
     Align;

     % ScaleFit Whether to scale graphics to fit
     %   Value of this property is specified as a character vector or
     %   string scalar. The value of "1" indicates that the graphics is
     %   scaled to fit and the value of "0" indicates that the graphics is
     %   not scaled to fit.
     %
     %   See also https://tdg.docbook.org/tdg/4.5/imagedata.html
     ScaleFit;

end
%}
