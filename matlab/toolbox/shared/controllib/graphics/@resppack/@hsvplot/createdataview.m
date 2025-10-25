function [data, view, dataprops] = createdataview(this, Nresp)
%CREATEDATAVIEW  Abstract Factory method

%  Copyright 1986-2005 The MathWorks, Inc.
data= resppack.hsvdata;
view = resppack.hsvview;
view.AxesGrid = this.AxesGrid;
% Return list of data-related properties of data object
dataprops = data.findprop('HSV');


