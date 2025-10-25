%#codegen
function varargout = dispatch(f, varargin)
	num = coder.internal.nprimfuns(f);
	switch coder.internal.toIndex(f) 
	  case coder.internal.ordinal(f, 1) 
		fcn1 = coder.internal.primfun(f, 1);
		[varargout{1:nargout}] = fcn1(varargin{:});
	  case coder.internal.ordinal(f, 2) 
		fcn2 = coder.internal.primfun(f, 2);
		[varargout{1:nargout}] = fcn2(varargin{:});
	  case coder.internal.ordinal(f, 3)
		fcn3 = coder.internal.primfun(f, 3);
		[varargout{1:nargout}] = fcn3(varargin{:});
	  case coder.internal.ordinal(f, 4)
		fcn4 = coder.internal.primfun(f, 4);
		[varargout{1:nargout}] = fcn4(varargin{:});
	  case coder.internal.ordinal(f, 5)
		fcn5 = coder.internal.primfun(f, 5);
		[varargout{1:nargout}] = fcn5(varargin{:});
	  otherwise
		coder.unroll
		for i = 6:(num - 1)
		  if coder.internal.toIndex(f) == coder.internal.ordinal(f, i)
			fcn_i = coder.internal.primfun(f, i);
			[varargout{1:nargout}] = fcn_i(varargin{:});
			return
		  end
		end
		fcnLast = coder.internal.primfun(f, num);
		[varargout{1:nargout}] = fcnLast(varargin{:});
	end
end