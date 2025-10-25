function varargout = daserrordlg(ErrorStringIn,DlgName)
% daserrordlg is a (mostly) workalike for errordlg, but is capable of
% handling long errors by using the DAStudio.DialogProvider.errordlg 
% method instead.
%
%  Copyright 2014 The MathWorks, Inc.

NumArgIn = nargin;

if NumArgIn==0
   ErrorStringIn = getString(message('MATLAB:uistring:popupdialogs:ErrorDialogDefaultString'));
end

if NumArgIn<2
    DlgName = getString(message('MATLAB:uistring:popupdialogs:ErrorDialogTitle'));
end

dp = DAStudio.DialogProvider;
d = dp.errordlg( ErrorStringIn, DlgName, true ); %true is nonblocking; it's still modal, but we can't block or tests hang
varargout = {d};
