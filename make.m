function make(varargin)
%MAKE Build dependent libraries.
  liblinear.make();
  libsvm.make();
  pose.compile();
  mr8.make();
  mexopencv.make();
  vl_make();
  bdb.make(varargin{:});
  GCO_BuildLib;
  pf.make();
end
