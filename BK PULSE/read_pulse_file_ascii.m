%
%  read_pulse_file_ascii.m
%
%  Created by Léa Strobino
%  Copyright 2018 hepia. All rights reserved.
%

function m = read_pulse_file_ascii(filename,matfile)
[path,name,ext] = fileparts(filename);
if isempty(path)
  path = cd();
end
if isempty(ext)
  ext = '.txt';
end
filename = fullfile(path,[name ext]);
h = fopen(filename,'r');
if h > 0
  headerSize = regexp(fgets(h),'^Header Size:\s*([\d]+)\s*$','tokens','once');
  if isempty(headerSize)
    fclose(h);
    error('read_pulse_file_ascii:BadFormat','"%s" is not a valid PULSE file ASCII.',filename);
  end
  headerSize = sscanf(headerSize{1},'%d');
  for i = 2:headerSize
    l = fgets(h);
    if strfind(l,':')
      [property,value] = getPropertyValue(l);
      if strcmpi(property,'DateFormat')
        dateFormat = value;
      elseif strcmpi(property,'TimeFormat')
        timeFormat = value;
      elseif ~strcmpi(property,'DecimalSymbol')
        try %#ok<TRYNC>
          m.(property) = value;
        end
      end
    end
  end
  tags = false;
  tagScales = false;
  m.Tags = {};
  m.TagScales = {};
  data = [];
  while ~feof(h)
    l = fgets(h);
    d = sscanf(l,'%f');
    if isempty(d) && ~isempty(strfind(l,':'))
      [property,value] = getPropertyValue(l);
      if tags
        if strcmpi(property,'TagsEnd')
          tags = false;
        elseif any(strcmpi(property,{'AverageNumber','OverLoad','OverLoadRatio','OverlapFailed','Overrun'}))
          m.(property) = value;
        else
          m.Tags{end+1} = strtrim(regexprep(l,'\s+',' '));
        end
      elseif tagScales
        if strcmpi(property,'TagScalesEnd')
          tagScales = false;
        else
          m.TagScales{end+1} = strtrim(regexprep(l,'\s+',' '));
        end
      else
        if strcmpi(property,'TagsBegin')
          tags = true;
        elseif strcmpi(property,'TagScalesBegin')
          tagScales = true;
        elseif strcmpi(property,'Date')
          date = textscan(value,'%s');
        elseif strcmpi(property,'Time')
          time = textscan(value,'%s');
          date = [char(date{1}) repmat(' ',length(date{1}),1) char(time{1})];
          try
            if ~isempty(which('datetime'))
              m.Date = datetime(date,'InputFormat',[dateFormat ' ' strrep(timeFormat,'mmm','SSS')]);
            else
              m.Date = datenum(date,[lower(dateFormat) ' ' strrep(upper(timeFormat),'MMM','FFF')]);
            end
          catch e
            switch e.identifier
              case {'MATLAB:datetime:ParseErr','MATLAB:datetime:ParseErrs','MATLAB:datenum:ConvertDateString'}
                m.Date = [];
              otherwise
                rethrow(e);
            end
          end
        else
          try %#ok<TRYNC>
            m.(property) = value;
          end
        end
      end
    else
      if strfind(l,'Undefined')
        d = sscanf(strrep(l,'Undefined','NaN'),'%f');
      end
      data = [data ; d ; fscanf(h,'%f')]; %#ok<AGROW>
    end
  end
  fclose(h);
  data = reshape(data,[],m.XAxisSize).';
  m.XAxis = data(:,2);
  m.Data = data(:,3:end);
  if strcmpi(m.DataType,'Complex')
    m.Data = m.Data(:,1:2:end)+1i*m.Data(:,2:2:end);
  end
  if m.Power && ~strcmpi(m.PowerUnit,'W')
    try %#ok<TRYNC>
      m.Data = sqrt(abs(m.Data)).*exp(1i*atan2(imag(m.Data),real(m.Data)));
      m.Power = 0;
      m.dBReference = sqrt(m.dBReference);
    end
  end
  [~,i] = sort(lower(fieldnames(m)));
  m = orderfields(m,i);
  if nargin > 1
    [path,name,ext] = fileparts(matfile);
    if isempty(path)
      path = cd();
    end
    if isempty(ext)
      ext = '.mat';
    end
    matfile = fullfile(path,[name ext]);
    save(matfile,'-struct','m');
  end
else
  error('read_pulse_file_ascii:FileNotFound','"%s": no such file.',filename);
end

function [property,value] = getPropertyValue(s)
i = find(s == ':',1);
property = [regexprep(s(1:i-1),'[^a-zA-Z0-9]','_') ' '];
u = find(property == '_');
property(u+1) = upper(property(u+1));
property(u) = [];
property = strtrim(property);
value = regexprep(strtrim(s(i+1:end)),'\''(.*)\''','$1');
value = strrep(value,'[]','');
if isempty(regexpi(property,'^((Date|Time)(Format)?|Title\d?)$|(Name|Signal)$','once'))
  value = strrep(value,'True','1');
  value = strrep(value,'False','0');
  value = strrep(value,'Undefined','NaN');
  [v,~,e] = sscanf(value,'%f');
  if isempty(e)
    value = v;
  end
end
