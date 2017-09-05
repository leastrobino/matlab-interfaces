%
%  TTi_TG2511.m
%
%  Created by Léa Strobino.
%  Copyright 2017 hepia. All rights reserved.
%

classdef TTi_TG2511 < handle
  
  properties (SetAccess = private)
    IDN
  end
  
  properties (Access = private)
    tty
    warnings
  end
  
  methods
    
    function this = TTi_TG2511(tty)
      this.tty = serial(tty,...
        'InputBufferSize',256,...
        'OutputBufferSize',256,...
        'Terminator','LF',...
        'Timeout',1);
      this.warnings = warning('error','MATLAB:serial:fscanf:unsuccessfulRead'); %#ok<*CTPCT>
      try
        fopen(this.tty);
        this.IDN = this.query('*IDN?');
      catch e
        delete(this.tty);
        e = addCause(MException('TTi_TG2511:CommunicationError',...
          'Unable to open the serial port.'),e);
        throw(e);
      end
      if isempty(regexp(this.IDN,'^THURLBY THANDAR, TG2511,','once'))
        delete(this.tty);
        error('TTi_TG2511:InstrumentNotFound',...
          'The instrument connected to %s is not a supported TTi function generator.',tty);
      end
    end
    
    function delete(this)
      try %#ok<TRYNC>
        this.goToLocal();
        fclose(this.tty);
        delete(this.tty);
      end
      warning(this.warnings);
    end
    
    function r = query(this,q,format)
      try
        for i = 1:numel(this)
          fprintf(this(i).tty,q);
        end
        if any(q == '?')
          if nargin < 3
            r = fscanf(this(1).tty);
            r = r(1:end-2);
          else
            r = fscanf(this(1).tty,format);
          end
        end
      catch
        error('TTi_TG2511:SerialException',...
          'Unable to read data from the serial interface.');
      end
    end
    
    function goToLocal(this)
      this.query('LOCAL');
    end
    
  end
  
end
