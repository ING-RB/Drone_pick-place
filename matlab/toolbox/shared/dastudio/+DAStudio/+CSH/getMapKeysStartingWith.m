function keys = getMapKeysStartingWith(key)
	if isdeployed
		keys = string.empty;
	else
    	keys = matlab.internal.doc.csh.getTopicsForDialog(key);
	end
end 
