function callback = getDefaultCallback
%

% Copyright 2009-2015 The MathWorks, Inc.
    callback = @DefaultCallback;
end

function DefaultCallback( cbinfo )
	% CallbackInfo is expected to contain a handle to a Studio
	% The default callback raises a menu event in C++
    tag = cbinfo.userdata;
    text = DAStudio.message('dastudio:dig:menu_item_not_yet_implemented', tag);
	if DAStudio.showNotImplementedDialog
        dp = DAStudio.DialogProvider;
        dp.msgbox( text, 'STUDIO', true );
    else
        warning off backtrace;
		warning( text );
	end
end	