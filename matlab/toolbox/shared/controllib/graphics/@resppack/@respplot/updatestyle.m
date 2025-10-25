function updatestyle(this,varargin)
%UPDATESTYLE  Updates response styles when style preferences change.

%  Copyright 1986-2004 The MathWorks, Inc.

% RE: PostSet listener for @stylemanager's list of styles (Styles property)
Styles = this.StyleManager.Styles;
Ns = length(Styles);
for ct=1:length(this.Responses)
   this.Responses(ct).Style = Styles(1+rem(ct-1,Ns));
end