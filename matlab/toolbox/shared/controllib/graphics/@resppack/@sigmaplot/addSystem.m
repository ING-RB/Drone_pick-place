function responses = addSystem(this,Systems,Name,Color,LineStyle)
%addSystem  Adds a response to the plot

%   Copyright 1986-2021 The MathWorks, Inc.
responses = [];
for ct = 1:numel(Systems)
   if ~isempty(Name)
      src = resppack.ltisource(Systems{ct}, 'Name', sprintf(strcat(Systems{ct}.Name,': %s'),Name));
   else
      src = resppack.ltisource(Systems{ct}, 'Name', Systems{ct}.Name);
   end
   r = this.addresponse(src);
   % Define characteristics
   chars = src.getCharacteristics('sigma');
   r.setCharacteristics(chars);
   r.DataFcn =  {'sigma' src r [] 0};
   r.setstyle('Color',Color{ct},'LineStyle',LineStyle);
   r.draw;
   responses = [responses;r]; %#ok<AGROW>
end