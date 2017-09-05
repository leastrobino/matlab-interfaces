%
%  LD_VideoCom.m
%
%  Created by Léa Strobino.
%  Copyright 2017 hepia. All rights reserved.
%

classdef LD_VideoCom < matlab.mixin.SetGet
  
  properties (SetAccess = private)
    IDN
  end
  
  properties
    BytesAvailableFcn
    Pixels
  end
  
  properties (Access = private) %#ok<*MCSUP>
    tty
    warnings
    slices
  end
  
  methods
    
    function this = LD_VideoCom(tty,bytesAvailableFcn)
      this.BytesAvailableFcn = bytesAvailableFcn;
      this.tty = serial(tty,...
        'BaudRate',19200,...
        'BytesAvailableFcnMode','terminator',...
        'InputBufferSize',1048576,...
        'OutputBufferSize',1048576,...
        'Terminator','CR/LF',...
        'Timeout',1);
      this.warnings = warning('error','MATLAB:serial:fscanf:unsuccessfulRead'); %#ok<CTPCT>
      try
        fopen(this.tty);
        fprintf(this.tty,':');
        s = fscanf(this.tty);
      catch e
        delete(this.tty);
        e = addCause(MException('LD_VideoCom:CommunicationError',...
          'Unable to open the serial port (%s).',tty),e);
        throw(e);
      end
      if isempty(regexp(s,'309\.50\.451 [B-D]\r\n','once'))
        fprintf(this.tty,':-(');
        delete(this.tty);
        error('LD_VideoCom:InstrumentNotFound',...
          'The instrument connected to %s is not a LD VideoCom.',tty);
      end
      fprintf(this.tty,':-)');
      fscanf(this.tty);
      fprintf(this.tty,'V');
      this.IDN = deblank(fscanf(this.tty));
      this.tty.BytesAvailableFcn = @this.bytesAvailableFcn;
      this.Pixels = 256;
    end
    
    function delete(this)
      try %#ok<TRYNC>
        fclose(this.tty);
        delete(this.tty);
      end
      warning(this.warnings);
    end
    
    function set.Pixels(this,n)
      n = min([max([ceil(log2(n/64)),0]),5]);
      fprintf(this.tty,'I1%d0\n',n);
    end
    
    function v = get.Pixels(this)
      v = 64*this.slices;
    end
    
  end
  
  methods (Access = private)
    
    function bytesAvailableFcn(this,~,~)
      persistent n_ d_
      d = fscanf(this.tty);
      if length(d) == 72 && d(1) == 'I'
        n = d(3)-48;
        s = sscanf(d(5:6),'%X');
        this.slices = 2^n;
        if isempty(n_) || n ~= n_
          n_ = n;
          d_ = zeros(64*this.slices,1,'uint8');
        end
        d_(64*s+1:64*(s+1)) = d(7:70);
        if s == this.slices-1
          try
            this.BytesAvailableFcn(d_);
          catch e
            warning(e.identifier,e.message);
          end
        end
      end
    end
    
  end
  
end
