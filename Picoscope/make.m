%
%  make.m
%
%  Created by Léa Strobino.
%  Copyright 2016 hepia. All rights reserved.
%

function make(varargin)

MEX = {};
switch computer('arch')
  case 'maci64'
    MEX = [MEX {'-largeArrayDims'}];
  case 'win32'
  case 'win64'
    MEX = [MEX {'-largeArrayDims'}];
end
MEX = [MEX {'-ISDK'}];
MEX = [MEX {'-LSDK'}];
MEX = [MEX {'-lPS2000'}];
MEX = [MEX {'-outdir','private'}];

if nargin == 0
  varargin = {'clean','all'};
end

warning('off','MATLAB:DELETE:FileNotFound');

if any(strcmpi(varargin,'clean'))
  m = mexext('all');
  for i = 1:length(m)
    delete(['*.' m(i).ext]);
    delete(['private/*.' m(i).ext]);
  end
  delete *.p
  delete private/*.p
end

if any(strcmpi(varargin,'all')) || any(strcmpi(varargin,'PicoScope'))
  mex('ps2000.c',MEX{:});
  switch computer('arch')
    case 'maci64'
      unix(['install_name_tool -change libps2000.2.dylib @loader_path/libps2000.dylib private/ps2000.' mexext]);
      copyfile('SDK/libps2000.dylib','private');
    case {'win32','win64'}
      copyfile('SDK\ps2000.dll','private');
  end
  pcode PicoScope.m
  pcode InterfacePicoScope.m
end
