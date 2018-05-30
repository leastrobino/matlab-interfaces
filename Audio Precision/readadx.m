%
%  readadx.m
%
%  Created by Léa Strobino.
%  Copyright 2018 hepia. All rights reserved.
%

function adx = readadx(filename)
[path,name,ext] = fileparts(filename);
if isempty(path)
  path = pwd();
end
if isempty(ext)
  ext = '.adx';
end
filename = fullfile(path,[name ext]);
h = fopen(filename,'r');
if h > 0
  d = textscan(fgets(h),'%s',2,'Delimiter',',');
  adx.TestFile = d{1}{1};
  try
    adx.Date = datetime(d{1}{2},'InputFormat','MM/dd/yy HH:mm:ss');
  catch
    adx.Date = datenum(d{1}{2},'mm/dd/yy HH:MM:SS');
  end
  d = textscan([fgets(h) fgets(h) fgets(h)],'%s','Delimiter',',');
  d = reshape(d{1},[],3)';
  v = find(~cellfun(@isempty,d(1,:)));
  adx.Name = d(1,v);
  adx.Tag = d(2,v);
  adx.Unit = d(3,v);
  try
    d = textscan(h,'',...
      'CollectOutput',1,...
      'Delimiter',',',...
      'EmptyValue',0,...
      'ReturnOnError',0);
    adx.Data = d{1}(:,v);
  catch e
    if strcmp(e.identifier,'MATLAB:textscan:EmptyFormatString')
      adx.Data = [];
    else
      rethrow(e);
    end
  end
  fclose(h);
else
  error('readadx:FileNotFound','"%s": no such file.',filename);
end
