%
%  readvci.m
%
%  Created by Léa Strobino.
%  Copyright 2017 hepia. All rights reserved.
%

function [I,x] = readvci(filename)
[path,name,ext] = fileparts(filename);
if isempty(path)
  path = pwd();
end
if isempty(ext)
  ext = '.vci';
end
filename = fullfile(path,[name ext]);
h = fopen(filename,'r');
if h > 0
  s = regexp([fgets(h) fgets(h)],'^VCINT2\r\n\d+ (\d+)\r\n','tokens','once');
  if isempty(s)
    fclose(h);
    error('readvci:BadFormat','"%s" is not a valid VCI file.',filename);
  end
  s = sscanf(s{1},'%d');
  try
    d = textscan(h,'%f%*[^\n]',s,...
      'Delimiter','\t',...
      'ReturnOnError',0);
    I = d{1}/100;
    I(isnan(I)) = [];
    x = (-.014:.028/(length(I)-1):.014)';
  catch e
    if strcmp(e.identifier,'MATLAB:textscan:EmptyFormatString')
      I = [];
      x = [];
    else
      rethrow(e);
    end
  end
  fclose(h);
else
  error('readvci:FileNotFound','"%s": no such file.',filename);
end
