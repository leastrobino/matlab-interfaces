%
%  BK_2977.m
%
%  Created by Léa Strobino.
%  Copyright 2017 hepia. All rights reserved.
%

classdef BK_2977 < handle
  
  properties (SetAccess = private)
    IDN
  end
  
  properties (Access = private)
    tty
  end
  
  methods
    
    function this = BK_2977(address)
      this.tty = GPIBlpt(address);
      this.tty.EOIMode = 'none';
      this.tty.EOSMode = 'read&write';
      this.tty.Timeout = .5;
      try
        this.IDN = this.query('*IDN?');
      catch e
        e = addCause(MException('BK_2977:CommunicationError',...
          'Unable to open the GPIB connection.'),e);
        throw(e);
      end
      if ~strcmp(this.IDN,'B&K 2977')
        error('BK_2977:InstrumentNotFound',...
          'The instrument at GPIB address %d is not a Brüel & Kjær 2977.',address);
      end
    end
    
    function delete(this)
      try %#ok<TRYNC>
        this.goToLocal();
      end
    end
    
    function r = read(this)
      r = fscanf(this.tty);
      r = sscanf(r(2:end-2),'%f');
    end
    
    function startContinuous(this)
      this.query('R_T C\nO?');
    end
    
    function stopContinuous(this)
      this.query('R_T SI');
    end
    
    function r = query(this,q,format)
      fprintf(this.tty,q);
      if any(q == '?')
        if nargin < 3
          r = fscanf(this.tty);
          r = r(1:end-2);
        else
          r = fscanf(this.tty,format);
        end
      end
    end
    
    function clearDevice(this)
      this.tty.clrdevice();
    end
    
    function goToLocal(this)
      this.tty.gotolocal();
    end
    
  end
  
end
