%
%  Hitachi_VC6023.m
%
%  Created by Léa Strobino.
%  Copyright 2018. All rights reserved.
%
%  DIP switches configuration: 11000010
%   - screen mode     : 1
%   - pen replacement : yes
%   - baud rate       : 9600
%   - data format     : 1 start bit + 8 bits + 1 stop bit
%   - delimiter       : CR
%

classdef Hitachi_VC6023 < handle
  
  properties (Access = private)
    asyncPlotFcn = [];
    plot = [];
    pngwritec
    rtifc
    tty
    warnings
  end
  
  methods
    
    function this = Hitachi_VC6023(tty,asyncPlotFcn)
      this.tty = serial(tty,...
        'BaudRate',9600,...
        'BytesAvailableFcnCount',1,...
        'BytesAvailableFcnMode','byte',...
        'DataBits',8,...
        'FlowControl','hardware',...
        'InputBufferSize',1048576,...
        'OutputBufferSize',1048576,...
        'Parity','none',...
        'RequestToSend','on',...
        'Terminator','CR',...
        'Timeout',3,...
        'StopBits',1);
      this.warnings = [warning('error','MATLAB:serial:fread:unsuccessfulRead'),...
        warning('error','MATLAB:serial:fscanf:unsuccessfulRead')]; %#ok<*CTPCT>
      try
        fopen(this.tty);
        this.query('R0(1)');
      catch e
        if ~strcmp(e.identifier,'Hitachi_VC6023:ProtocolError')
          delete(this.tty);
          e = addCause(MException('Hitachi_VC6023:CommunicationError',...
            'Unable to open the serial port (%s).',tty),e);
          throw(e);
        end
      end
      if nargin > 1
        this.asyncPlotFcn = asyncPlotFcn;
        this.tty.BytesAvailableFcn = @this.bytesAvailableFcn;
      end
      d = which('-all','rtifc');
      d = cd(fileparts(d{1}));
      this.pngwritec = @pngwritec;
      this.rtifc = @rtifc;
      cd(d);
    end
    
    function delete(this)
      try %#ok<TRYNC>
        fclose(this.tty);
        delete(this.tty);
      end
      warning(this.warnings);
    end
    
    function s = getScreen(this,stored,outfile)
      if nargin > 2
        [~,~,ext] = fileparts(outfile);
        if ~any(strcmpi(ext,{'.hpgl','.eps','.pdf','.png'}))
          error('Hitachi_VC6023:getScreen:BadFormat',...
            'Unsupported export format.\nValid formats are: HPGL, EPS, PDF, PNG.');
        end
      end
      if nargin < 2 || ~stored
        this.tty.BytesAvailableFcn = '';
        flushinput(this.tty);
        t_ = tic();
        while ~this.tty.BytesAvailable
          if toc(t_) > 5
            this.error('Hitachi_VC6023:getScreen:Timeout','Bus timeout occurred.');
          end
          t = tic();
          while toc(t) < .5, end
        end
        this.capturePlot();
        if ~isempty(this.asyncPlotFcn)
          this.tty.BytesAvailableFcn = @this.bytesAvailableFcn;
        end
      elseif isempty(this.plot)
        error('Hitachi_VC6023:getScreen:NoData',...
          'No stored data to export.');
      end
      tmpfile = tempname();
      h = fopen(tmpfile,'w');
      fwrite(h,this.plot);
      fclose(h);
      if nargin > 2 && strcmpi(ext,'.hpgl')
        movefile(tmpfile,outfile);
        return
      end
      d = fileparts(mfilename('fullpath'));
      if ispc
        [s,d] = system(['"' d '\hp2xx\hp2xx.exe" "' tmpfile '" -m eps -f - 2> nul']);
      else
        [s,d] = system(['"' d '/hp2xx/hp2xx" "' tmpfile '" -m eps -f - 2> /dev/null']);
      end
      if s
        error('Hitachi_VC6023:getScreen:hp2xxError','Conversion error.');
      end
      software = regexp(d,'%%Creator: (hp2xx [^ ]*) ','tokens','once');
      software = ['MATLAB ' version() ', ' software{1}];
      n = find(d == 10,7);
      d = d(n(end)+1:end);
      d = regexprep(d,' 0.000  0.000  0.000 C','0.75 0.75 0.75 C 0.35 W','once');  % Grid
      d = regexprep(d,' [01].000  0.000  0.000 C','0 0 0 C 0.35 W');               % Cursors
      p = ' 0.000  1.000  0.000 C';
      d = regexprep(d,p,'0 0 0 C 0.7 W',numel(regexp(d,p)));                       % CH1 trace
      d = regexprep(d,p,'0 0 0 C 0.35 W');                                         % CH1 scale
      p = ' 0.000  0.000  1.000 C';
      d = regexprep(d,p,'1 0 0 C 0.7 W',numel(regexp(d,p)));                       % CH2 trace
      d = regexprep(d,p,'1 0 0 C 0.35 W');                                         % CH2 scale
      p = ' 0.000  1.000  1.000 C';
      d = regexprep(d,p,'1 0.5 0 C 0.7 W',numel(regexp(d,p)));                     % S_A trace
      d = regexprep(d,p,'1 0.5 0 C 0.35 W');                                       % S_A scale
      p = ' 1.000  0.000  1.000 C';
      d = regexprep(d,p,'0.565 0.753 0.251 C 0.7 W',numel(regexp(d,p)));           % S_B trace
      d = regexprep(d,p,'0.565 0.753 0.251 C 0.35 W');                             % S_B scale
      d = ['%!PS-Adobe-2.0 EPSF-2.0' 10 ...
        '%%Creator: ' software 10 ...
        '%%BoundingBox: -6 -6 580 466' 10 ...
        '%%EndComments' 10 d];
      h = fopen(tmpfile,'w');
      fwrite(h,d);
      fclose(h);
      if nargin > 2 && strcmpi(ext,'.eps')
        movefile(tmpfile,outfile);
        return
      end
      cmd = '-q -dBATCH -dNOPAUSE -dEPSCrop -dFIXEDMEDIA -dDEVICEWIDTHPOINTS=580 -dDEVICEHEIGHTPOINTS=466 ';
      if nargin > 2 && strcmpi(ext,'.pdf')
        this.gs([cmd '-sDEVICE=pdfwrite -dPDFSETTINGS=/prepress'],tmpfile,outfile);
      else
        this.gs([cmd '-sDEVICE=tiff24nc -sCompression=pack -r72'],tmpfile,[tmpfile '.tif']);
        s = this.rtifc(struct('filename',[tmpfile '.tif'],'index',1,'pixelregion',[]));
        delete([tmpfile '.tif']);
        if nargin > 2
          this.pngwritec(s,[],outfile,2,8,[],[],'none',[],[],[],[],[],[],[],{'Software',software},[]);
        end
      end
      delete(tmpfile);
    end
    
    function [x,A,B,info] = getTrace(this)
      this.tty.BytesAvailableFcn = '';
      flushinput(this.tty);
      R0 = [textscan(this.query('R0(1)'),'%s','Delimiter',','),textscan(this.query('R0(2)'),'%s','Delimiter',',')];
      s = '';
      for i = 1:2
        VM = R0{i}{2};
        AT = R0{i}{4};
        VC = R0{i}{6};
        PF = R0{i}{7};
        VD = R0{i}{8};
        NS = sscanf(R0{i}{10},'%d');
        VU = 'V';
        if strcmp(VM,sprintf('CH%d',i)) || strcmp(VM,'DUAL') || (i == 1 && strcmp(VM,'ADD'))
          fprintf(this.tty,'R%d(0000,1000,B)\n',i+4);
          d = fread(this.tty,1016,'uint8');
          d = (d(15:1014)-128)/25;
          if strcmp(VC,'CAL') && ~strcmp(VD,'ADD')
            VD = textscan(VD,'%f %s');
            d = VD{1}*d;
            if strcmp(VD{2}{1},'MV')
              d = 1E-3*d;
            end
          else
            VU = 'DIV';
          end
          if strcmp(VM,'ADD')
            s = sprintf('%s; CH1 + CH2: %s %s + %s %s',s,PF,VC,R0{2}{7},R0{2}{6});
          else
            s = sprintf('%s; CH%d: %s %s',s,i,PF,VC);
          end
        else
          d = NaN(1000,1);
        end
        if i == 1
          AT = textscan(AT,'%f %s');
          x = AT{1}*(0:.01:9.99);
          switch AT{2}{1}
            case 'MS'
              x = 1E-3*x;
            case 'MICS'
              x = 1E-6*x;
          end
          info.XLabel = 'Time (s)';
          A = d;
          info.ALabel = ['CH1 (' VU ')'];
        else
          B = d;
          info.BLabel = ['CH2 (' VU ')'];
        end
      end
      if NS > 1
        info.Measurement = sprintf('%s; %d averages',s(3:end),NS);
      else
        info.Measurement = sprintf('%s; No average',s(3:end));
      end
      if ~isempty(this.asyncPlotFcn)
        this.tty.BytesAvailableFcn = @this.bytesAvailableFcn;
      end
    end
    
    function trig(this)
      this.tty.BytesAvailableFcn = '';
      flushinput(this.tty);
      this.query('S1');
      if ~isempty(this.asyncPlotFcn)
        this.tty.BytesAvailableFcn = @this.bytesAvailableFcn;
      end
    end
    
  end
  
  methods (Access = private)
    
    function bytesAvailableFcn(this,~,~)
      if this.tty.BytesAvailable
        this.tty.BytesAvailableFcn = '';
        b = jwaitbar(0,'','Hitachi VC-6023 plot capture');
        this.capturePlot(b);
        this.asyncPlotFcn(this);
        this.tty.BytesAvailableFcn = @this.bytesAvailableFcn;
      end
    end
    
    function capturePlot(this,b)
      bytes = 0;
      while this.tty.BytesAvailable ~= bytes
        bytes = this.tty.BytesAvailable;
        if nargin > 1
          try %#ok<TRYNC>
            jwaitbar(bytes/81920,b,sprintf('Received %.1f kB...',bytes/1024));
          end
        end
        t = tic();
        while toc(t) < .5, end
      end
      if nargin > 1
        try %#ok<TRYNC>
          jwaitbar(1,b,'Done.');
          t = tic();
          while toc(t) < .5, end
          close(b);
        end
      end
      this.plot = uint8(fread(this.tty,this.tty.BytesAvailable,'uint8'));
    end
    
    function error(this,varargin)
      if ~isempty(this.asyncPlotFcn)
        this.tty.BytesAvailableFcn = @this.bytesAvailableFcn;
      end
      throwAsCaller(MException(varargin{:}));
    end
    
    function s = gs(this,cmd,infile,outfile)
      persistent gs
      if isempty(gs)
        if ispc
          p = 'C:\Program Files\gs\';
          d = dir([p 'gs*.*\']);
          if isempty(d)
            p = 'C:\Program Files (x86)\gs\';
            d = dir([p 'gs*.*\']);
          end
          if ~isempty(d)
            for e = {'\bin\gswin64c.exe','\bin\gswin32c.exe'}
              gs = [p d(end).name e{1}];
              if exist(gs,'file')
                [s,~] = system(['"' gs '" -v']);
                if s == 0
                  s = this.gs(cmd,infile,outfile);
                  return;
                end
              end
            end
          end
        else
          for p = {'/usr/bin/gs','/usr/local/bin/gs'}
            gs = p{1};
            if exist(gs,'file')
              [s,~] = system(['"' gs '" -v']);
              if s == 0
                s = this.gs(cmd,infile,outfile);
                return;
              end
            end
          end
        end
        gs = [];
        error('Hitachi_VC6023:gsNotFound','Ghostscript not found.');
      end
      [s,~] = system(['"' gs '" ' cmd ' -sOutputFile="' outfile '" "' infile '"']);
    end
    
    function r = query(this,q)
      try
        fprintf(this.tty,q);
        r = fscanf(this.tty);
        r = r(1:end-1);
      catch
        this.error('Hitachi_VC6023:SerialException',...
          'Unable to read data from the serial interface.');
      end
      if numel(r) == 1
        r = uint8(r);
        switch r
          case 97
            this.error('Hitachi_VC6023:CommandError','Command error.');
          case 98
            this.error('Hitachi_VC6023:DataError','Data error.');
          case 99
            this.error('Hitachi_VC6023:DataContentError','Data content error.');
          case 100
            this.error('Hitachi_VC6023:ExcessiveDataNumber','Excessive data number.');
          case 101
            this.error('Hitachi_VC6023:InsufficientDataNumber','Insufficient data number.');
          case 103
            this.error('Hitachi_VC6023:ProtocolError',['Protocol error. Check that the ',...
              'STORAGE mode setting\nswitch LED and the HOLD LED on the front panel are lit.']);
          otherwise
            if r ~= 65
              this.error('Hitachi_VC6023:ProcessingError','Processing error.');
            end
        end
      end
    end
    
  end
  
end
