function mask = refreshmask(this)
%REFRESHMASK  Builds visibility mask for REFRESH.
%
%  MASK = REFRESHMASK(RESPPLOT) constructs the visibility mask
%  used by REFRESH.  This mask is similar to the data visibility
%  mask (see DATAVIS) except that ungrouped I/Os are always 
%  considered visible (the effective visibility of their contents
%  being controlled by the ContentsVisible property of the 
%  corresponding axes). 
%
%  MASK is a boolean array of the same size as the axes grid 
%  (see GETAXES).  False entries flag I/Os that are both grouped
%  and hidden, and therefore require manual control of the 
%  visibility of their contents.

%  Copyright 2013-2014 The MathWorks, Inc.
mask = true(this.AxesGrid.Size);
s = this.IOSize;
if strcmp(this.Visible,'on')
   if strcmp(this.IOGrouping,'all')
      mask(s(1)+find(strcmp(this.InputVisible,'off')),:,:) = false;
      mask(strcmp(this.OutputVisible,'off'),:,:) = false;
   end
end
