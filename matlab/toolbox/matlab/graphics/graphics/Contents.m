% Handle Graphics.
% 
% Figure window creation and control.
%   figure     	- Create figure window.
%   gcf        	- Get handle to current figure.
%   clf        	- Clear current figure.
%   shg        	- Show graph window.
%   close      	- Close figure.
%   refresh    	- Refresh figure.
%   refreshdata - Refresh data in plot
%   openfig     - Open new copy or raise existing copy of saved figure.
% 
% Axis creation and control.
%   subplot    	- Create axes in tiled positions.
%   axes       	- Create axes in arbitrary positions.
%   gca        	- Get handle to current axis.
%   cla        	- Clear current axis.
%   axis       	- Control axis scaling and appearance.
%   box        	- Axis box.
%   caxis      	- Control pseudocolor axis scaling.
%   hold       	- Hold current graph
%   ishold     	- Return hold state.
%
% Colormaps.
%   parula     - Blue-green-orange-yellow colormap
%   hsv        - Hue-saturation-value colormap.
%   hot        - Black-red-yellow-white colormap.
%   gray       - Linear gray-scale colormap.
%   bone       - Gray-scale with tinge of blue colormap.
%   copper     - Linear copper-tone colormap.
%   pink       - Pastel shades of pink colormap.
%   white      - All white colormap.
%   flag       - Alternating red, white, blue, and black colormap.
%   lines      - Colormap with the line colors.
%   colorcube  - Enhanced color-cube colormap.
%   jet        - Variant of HSV.
%   prism      - Prism colormap.
%   cool       - Shades of cyan and magenta colormap.
%   autumn     - Shades of red and yellow colormap.
%   spring     - Shades of magenta and yellow colormap.
%   winter     - Shades of blue and green colormap.
%   summer     - Shades of green and yellow colormap.
%
% Graphics objects.
%   figure     	  - Create figure window.
%   axes       	  - Create axes in arbitrary positions.
%   line       	  - Create line.
%   text       	  - Create text.
%   patch      	  - Create patch.
%   rectangle     - Create rectangle, rounded-rectangle, or ellipse.
%   surface    	  - Create surface.
%   image      	  - Create image.
%   light      	  - Create light.
%
% Graphics operations.
%   set        	  - Set object properties.
%   get        	  - Get object properties.
%   reset      	  - Reset graphics object properties to their defaults.
%   delete     	  - Delete object.
%   gco        	  - Get handle to current object.
%   gcbo       	  - Get handle to current callback object.
%   gcbf       	  - Get handle to current callback figure.
%   drawnow    	  - Flush pending graphics events.
%   findobj    	  - Find objects with specified property values.
%   copyobj    	  - Make copy of graphics object and its children.
%   isappdata     - True if application-defined data exists.
%   getappdata    - Get value of application-defined data.
%   setappdata    - Set application-defined data.
%   rmappdata     - Remove application-defined data.
%
% Hardcopy and printing.
%   print      	    - Print figure or model. Save to disk as image or MATLAB file.
%   printopt   	    - Printer defaults.
%   orient     	    - Set paper orientation for printing. 
%   printdlg		- Print dialog box.
%   printpreview	- Display preview of figure to be printed
%   figureheaderdlg	- Show figure header dialog
%   copyoptionsfcn  - brings up the preferences dialog with Copy Options selected.
%   exportsetupdlg  - Figure style editor
%
% Utilities.
%   closereq   	- Figure close request function.
%   newplot    	- Prepares figure, axes for graphics according to NextPlot.
%   ishandle   	- True for graphics handles.
%   findall		- find all objects.
%
% ActiveX Client Functions (PC Only).
%   actxcontrol   - Create an ActiveX control.
%   actxserver    - Create an ActiveX server.
%
% See also GRAPH2D, GRAPH3D, SPECGRAPH, WINFUN.

% Printing utilities.
%   bwcontr       - Contrasting black or white color.
%   hardcopy      - Save figure window to file.
%   nodither      - Modify figure to avoid dithered lines.
%   savtoner      - Modify figure to save printer toner.
%   noanimate     - Modify figure to make all objects have normal erasemode.
%
% Other utilities.
%   parseparams    - Finds first string argument.
%   datachildren   - Handles to figure children that contain data.
%   opengl         - Change automatic selection mode of OpenGL rendering.
%   ancestor	   - Get object ancestor.
%   axescheck	   - Process leading Axes object from input list
%   colornone	   - Modify figure to have transparent background
%   datacursormode - Interactively create data cursors on plot

%   Copyright 1984-2024 The MathWorks, Inc. 
