%
%  Tektronix_AFG300.m
%
%  Created by Léa Strobino.
%  Copyright 2017 hepia. All rights reserved.
%

classdef Tektronix_AFG300 < handle
  
  properties (SetAccess = private)
    IDN
  end
  
  properties (Access = private)
    tty
  end
  
  methods
    
    function this = Tektronix_AFG300(address)
      this.tty = GPIBlpt(address);
      try
        this.IDN = this.query('*IDN?');
      catch e
        e = addCause(MException('Tektronix_AFG300:CommunicationError',...
          'Unable to open the GPIB connection.'),e);
        throw(e);
      end
      if isempty(regexp(this.IDN,'^SONY/TEK,AFG3\d0,','once'))
        error('Tektronix_AFG300:InstrumentNotFound',...
          'The instrument connected to %d is not a supported Tektronix generator.',address);
      end
    end
    
    function r = query(this,q,format)
      fprintf(this.tty,q);
      if any(q == '?')
        if nargin < 3
          r = fscanf(this.tty);
          r = r(1:end-1);
        else
          r = fscanf(this.tty,format);
        end
      end
    end
    
    function clearDevice(this)
      this.tty.clrdevice();
    end
    
  end
  
end
