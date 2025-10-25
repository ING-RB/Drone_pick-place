function rX = addSystem(this,System,Name,Color,LineStyle,W1,W2)
%addSystem  Adds a response to the plot

%   Copyright 1986-2021 The MathWorks, Inc.
src = resppack.ltisource(System, 'Name', Name);
rX = this.addresponse(src);
% Define characteristics
chars = src.getCharacteristics('sectorplot');
rX.setCharacteristics(chars);
rX.DataFcn =  {'sectorresp' src rX [] [] W1 W2};
rX.setstyle('Color',Color,'LineStyle',LineStyle)
rX.draw;