%
%  Tektronix_TDS.m
%
%  Created by Léa Strobino.
%  Copyright 2017 hepia. All rights reserved.
%

classdef Tektronix_TDS < handle
  
  properties (SetAccess = private)
    IDN
  end
  
  properties (Access = private)
    tty
    ths
    pcxdrle
    warnings
  end
  
  methods
    
    function this = Tektronix_TDS(tty)
      this.tty = serial(tty,...
        'BaudRate',9600,...
        'FlowControl','hardware',...
        'InputBufferSize',1048576,...
        'OutputBufferSize',1048576,...
        'Terminator','LF',...
        'Timeout',1);
      this.warnings = [warning('error','MATLAB:serial:fread:unsuccessfulRead'),...
        warning('error','MATLAB:serial:fscanf:unsuccessfulRead'),...
        warning('error','MATLAB:imagesci:pcxdrle:indexExceedsInputBufferLength')]; %#ok<*CTPCT>
      try
        fopen(this.tty);
        this.IDN = this.query('*IDN?');
      catch e
        delete(this.tty);
        e = addCause(MException('Tektronix_TDS:CommunicationError',...
          'Unable to open the serial port (%s).\nRS232 setup: 9600, Hard flagging, LF, None.',tty),e);
        throw(e);
      end
      s = regexp(this.IDN,'^TEKTRONIX,T(D|H)S \d+,','tokens','once');
      if isempty(s)
        delete(this.tty);
        error('Tektronix_TDS:InstrumentNotFound',...
          'The instrument connected to %s is not a supported Tektronix oscilloscope.',tty);
      end
      this.ths = (s{1} == 'H');
      d = which('-all','pcxdrle');
      d = cd(fileparts(d{1}));
      this.pcxdrle = @pcxdrle;
      cd(d);
    end
    
    function delete(this)
      try %#ok<TRYNC>
        fclose(this.tty);
        delete(this.tty);
      end
      warning(this.warnings);
    end
    
    function s = getScreen(this)
      this.clearDevice();
      this.query('HARDC:LAY PORTR;FORM PCX;INKS ON');
      t = tic();
      while toc(t) < .5, end
      this.query('HARDC:PORT RS232;:HARDC STAR');
      bytes = 0;
      t_ = tic();
      while ~bytes || this.tty.BytesAvailable ~= bytes
        if ~bytes && toc(t_) > 5
          error('Tektronix_TDS:Timeout','Bus timeout occurred.');
        end
        bytes = this.tty.BytesAvailable;
        t = tic();
        while toc(t) < .5, end
      end
      if ~this.ths
        this.query('HARDC:PORT CEN');
      end
      d = uint8(fread(this.tty,this.tty.BytesAvailable,'uint8'));
      if numel(d) < 128
        error('Tektronix_TDS:IndexExceedsInputBufferLength',...
          'PCX header too small; input appears to be truncated.');
      end
      bits = d(4);
      width = typecast(d(9:10),'uint16')-typecast(d(5:6),'uint16')+1;
      height = typecast(d(11:12),'uint16')-typecast(d(7:8),'uint16')+1;
      scanLineLength = uint16(d(66))*typecast(d(67:68),'uint16');
      s = this.pcxdrle(d(129:end),height,scanLineLength);
      if bits == 1
        s = s(:);
        s = [bitand(s,128) bitand(s,64) bitand(s,32) bitand(s,16) ...
          bitand(s,8) bitand(s,4) bitand(s,2) bitand(s,1)] ~= 0;
        s = reshape(s',[],height);
        s = s(1:width,:)';
      else
        m = reshape(d(end-767:end),3,256);
        d = double(s(1:width,:)')+1;
        c = zeros(height,width,'uint8');
        s = zeros(height,width,3,'uint8');
        for i = 1:3
          c(:) = m(i,d);
          s(:,:,i) = c;
        end
      end
    end
    
    function [x,A,B,info] = getTrace(this)
      this.clearDevice();
      CH = this.query('HEAD 0;DAT INIT;:SEL:CH1?;CH2?','%d;%d');
      if ~any(CH)
        error('Tektronix_TDS:NoActiveTrace','No active trace to transfer.');
      end
      s = '';
      x = NaN;
      this.tty.Timeout = 10;
      for i = 1:2
        if CH(i)
          if this.ths
            WFMP = sprintf('WFMP:CH%d:',i);
          else
            WFMP = 'WFMP:';
          end
          fprintf(this.tty,sprintf('DAT:SOU CH%d;ENC SRI;WID %d;:CURV?',i,1+this.ths));
          try
            fread(this.tty,6);
            if this.ths
              d = fread(this.tty,2500,'int16');
            else
              d = fread(this.tty,2500,'int8');
            end
            fread(this.tty,1);
          catch
            error('Tektronix_TDS:SerialException',...
              'Unable to read data from the serial connection.');
          end
          p = this.query([WFMP 'YOF?;YMU?;YZE?'],'%f;%f;%f');
          d = (d-p(1))*p(2)+p(3);
          p = this.query([WFMP 'WFI?']);
          p = textscan(p(2:end-1),'%s','Delimiter',',');
          if this.ths
            s = sprintf('%s; CH%d: %s, %s',s,i,p{1}{1}(5:end),p{1}{5});
          else
            s = sprintf('%s; CH%d: %s, %s',s,i,p{1}{2},p{1}{6});
          end
          if all(isnan(x))
            x = this.query([WFMP 'XIN?'],'%f')*(0:2499)';
            if this.ths
              x = x-x(end)*this.query('HOR:TRIG:POS?','%f')/100;
            else
              x = x+this.query([WFMP 'XZE?'],'%f');
            end
          end
        else
          d = NaN(2500,1);
        end
        if i == 1
          A = d;
        else
          B = d;
        end
      end
      this.tty.Timeout = 1;
      info.Measurement = s(3:end);
      info.XLabel = 'Time (s)';
      info.ALabel = 'CH1 (V)';
      info.BLabel = 'CH2 (V)';
    end
    
    function r = query(this,q,format)
      try
        fprintf(this.tty,q);
        if any(q == '?')
          if nargin < 3
            r = fscanf(this.tty);
            r = r(1:end-1);
          else
            r = fscanf(this.tty,format);
          end
        end
      catch
        error('Tektronix_TDS:SerialException',...
          'Unable to read data from the serial interface.');
      end
    end
    
    function clearDevice(this)
      flushinput(this.tty);
      serialbreak(this.tty);
      try
        fread(this.tty,5);
      catch
        error('Tektronix_TDS:Timeout','Bus timeout occurred.');
      end
    end
    
  end
  
end
