%
%  Agilent_34401A.m
%
%  Created by Léa Strobino.
%  Copyright 2015 hepia. All rights reserved.
%

classdef Agilent_34401A < handle
  
  properties (SetAccess = private)
    IDN
  end
  
  properties (Access = private)
    tty
    warnings
  end
  
  methods
    
    function this = Agilent_34401A(tty)
      this.tty = serial(tty,...
        'BaudRate',9600,...
        'DataBits',7,...
        'FlowControl','none',...
        'InputBufferSize',1048576,...
        'OutputBufferSize',1048576,...
        'Parity','even',...
        'StopBits',2,...
        'Terminator','LF',...
        'Timeout',1);
      this.warnings = warning('error','MATLAB:serial:fscanf:unsuccessfulRead'); %#ok<CTPCT>
      try
        fopen(this.tty);
        this.IDN = this.query('SYST:REM;*RST;*CLS;*IDN?');
        set(this.tty,'Timeout',60);
      catch e
        delete(this.tty);
        e = addCause(MException('Agilent_34401A:CommunicationError',...
          'Unable to open the serial port (%s).',tty),e);
        throw(e);
      end
      if isempty(regexp(this.IDN,'^HEWLETT-PACKARD,34401A,','once'))
        delete(this.tty);
        error('Agilent_34401A:InstrumentNotFound',...
          'The instrument connected to %s is not a supported Agilent multimeter.',tty);
      end
    end
    
    function delete(this)
      try %#ok<TRYNC>
        this.query('SYST:LOC;*RST;*CLS');
        fclose(this.tty);
        delete(this.tty);
      end
      warning(this.warnings);
    end
    
    function r = query(this,q,format)
      try
        fprintf(this.tty,q);
        if any(q == '?')
          if nargin < 3
            r = fscanf(this.tty);
            r = r(1:end-2);
          else
            r = sscanf(fscanf(this.tty),format);
          end
        end
      catch
        error('Agilent_34401A:SerialException',...
          'Unable to read data from the serial interface.');
      end
    end
    
    function clearDevice(this)
      fwrite(this.tty,3);
      flushinput(this.tty);
    end
    
    function goToLocal(this)
      this.query('SYST:LOC');
    end
    
  end
  
end
