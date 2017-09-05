/*
 *  ps2000.c
 *
 *  Created by Léa Strobino.
 *  Copyright 2016 hepia. All rights reserved.
 *
 */

#include <mex.h>
#include <string.h>
#include "ps2000.h"

#define VERSION "1.0"

#define ps2000_error_out_of_range() mexErrMsgIdAndTxt("ps2000:OutOfRange","Parameter out of range.");

mxArray *buffer[7];

inline void nargchk(int nlhs, int required_nlhs, int nrhs, int required_nrhs) {
  if (nlhs < required_nlhs) mexErrMsgTxt("Not enough output arguments.");
  if (nlhs > required_nlhs) mexErrMsgTxt("Too many output arguments.");
  if (nrhs < required_nrhs) mexErrMsgTxt("Not enough input arguments.");
  if (nrhs > required_nrhs) mexErrMsgTxt("Too many input arguments.");
}

void ps2000_get_overview_buffers(int16_t **overview_buffer, int16_t overflow, uint32_t triggered_at, int16_t triggered, int16_t auto_stop, uint32_t n) {
  buffer[0] = mxCreateNumericMatrix(n,1,mxINT16_CLASS,mxREAL);
  if (overview_buffer[0]) memcpy(mxGetData(buffer[0]),overview_buffer[0],n*sizeof(int16_t));
  buffer[1] = mxCreateNumericMatrix(n,1,mxINT16_CLASS,mxREAL);
  if (overview_buffer[2]) memcpy(mxGetData(buffer[1]),overview_buffer[2],n*sizeof(int16_t));
  buffer[2] = mxCreateLogicalScalar(auto_stop);
  buffer[3] = mxCreateLogicalScalar(triggered);
  buffer[4] = mxCreateNumericMatrix(1,1,mxUINT32_CLASS,mxREAL);
  *((uint32_t*)mxGetData(buffer[4])) = triggered_at;
  buffer[5] = mxCreateLogicalScalar(overflow & 0b01);
  buffer[6] = mxCreateLogicalScalar(overflow & 0b10);
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  
  /* check function name */
  if ((nrhs < 1) || !mxIsChar(prhs[0])) mexErrMsgTxt("Missing function.");
  char *f = mxArrayToString(prhs[0]);
  
  /* ps2000_open_unit */
  if (strcmp(f,"open_unit") == 0) {
    
    nargchk(nlhs,1,nrhs,1);
    
    /* set the pointer */
    plhs[0] = mxCreateNumericMatrix(1,1,mxINT16_CLASS,mxREAL);
    int16_t *handle = mxGetData(plhs[0]);
    
    *handle = ps2000_open_unit();
    
    /* lock the function */
    mexLock();
    
  } else {
    
    /* get the pointer */
    if ((nrhs < 2) || !mxIsInt16(prhs[1])) mexErrMsgTxt("Invalid pointer.");
    int16_t *handle = mxGetData(prhs[1]);
    
    /* ps2000_close_unit */
    if (strcmp(f,"close_unit") == 0) {
      
      nargchk(nlhs,0,nrhs,2);
      
      ps2000_close_unit(*handle);
      
    /* ps2000_get_unit_info */
    } else if (strcmp(f,"get_unit_info") == 0) {
      
      nargchk(nlhs,7,nrhs,2);
      
      plhs[6] = mxCreateNumericMatrix(1,1,mxINT32_CLASS,mxREAL);
      int32_t *time_interval = mxGetData(plhs[6]);
      
      char *s;
      uint8_t i;
      
      s = mxCalloc(80,sizeof(char));
      for (i=0; i<5; i++) {
        ps2000_get_unit_info(*handle,s,80*sizeof(char),i);
        plhs[i] = mxCreateString(s);
      }
      mxFree(s);
      plhs[5] = mxCreateString(VERSION);
      ps2000_get_timebase(*handle,1,0,time_interval,NULL,1,NULL);
      *time_interval /= 2;
      
    /* ps2000_set_ets, ps2000_set_trigger, ps2000_set_channel */
    } else if (strcmp(f,"set_defaults") == 0) {
      
      nargchk(nlhs,0,nrhs,2);
      
      ps2000_set_ets(*handle,PS2000_ETS_OFF,0,0);
      ps2000_set_trigger(*handle,PS2000_NONE,0,PS2000_RISING,0,0);
      ps2000_set_channel(*handle,PS2000_CHANNEL_A,0,1,PS2000_10V);
      ps2000_set_channel(*handle,PS2000_CHANNEL_B,0,1,PS2000_10V);
      
    /* ps2000_set_channel */
    } else if (strcmp(f,"set_channel") == 0) {
      
      nargchk(nlhs,0,nrhs,5);
      
      uint8_t channel = mxGetScalar(prhs[2]);
      uint8_t range = mxGetScalar(prhs[3]);
      int8_t dc = mxGetScalar(prhs[4]);
      
      if (dc == -1) {
        ps2000_set_channel(*handle,channel,0,1,PS2000_10V);
      } else if (!ps2000_set_channel(*handle,channel,1,dc,range)) {
        ps2000_error_out_of_range();
      }
      
    /* ps2000_set_trigger */
    } else if (strcmp(f,"set_trigger") == 0) {
      
      nargchk(nlhs,0,nrhs,6);
      
      uint8_t channel = mxGetScalar(prhs[2]);
      int16_t threshold = mxGetScalar(prhs[3]);
      uint8_t edge = mxGetScalar(prhs[4]);
      double delay = mxGetScalar(prhs[5]);
      
      if (!ps2000_set_trigger2(*handle,channel,threshold,edge,delay,0)) {
        ps2000_error_out_of_range();
      }
      
    /* ps2000_run_block */
    } else if (strcmp(f,"run_block") == 0) {
      
      nargchk(nlhs,0,nrhs,5);
      
      uint32_t n = mxGetScalar(prhs[2]);
      uint16_t timebase = mxGetScalar(prhs[3]);
      uint8_t oversample = mxGetScalar(prhs[4]);
      
      if (!ps2000_run_block(*handle,n,timebase,oversample,NULL)) {
        ps2000_error_out_of_range();
      }
      
    /* ps2000_run_streaming_ns */
    } else if (strcmp(f,"run_streaming_ns") == 0) {
      
      nargchk(nlhs,0,nrhs,4);
      
      uint32_t n = mxGetScalar(prhs[2]);
      uint32_t sample_interval_us = mxGetScalar(prhs[3]);
      
      if (!ps2000_run_streaming_ns(*handle,sample_interval_us,PS2000_US,n-4,1,1,1E5)) {
        ps2000_error_out_of_range();
      }
      
    /* ps2000_ready */
    } else if (strcmp(f,"ready") == 0) {
      
      nargchk(nlhs,1,nrhs,2);
      
      plhs[0] = mxCreateLogicalScalar(ps2000_ready(*handle));
      
    /* ps2000_stop */
    } else if (strcmp(f,"stop") == 0) {
      
      nargchk(nlhs,0,nrhs,2);
      
      ps2000_stop(*handle);
      
    /* ps2000_get_values */
    } else if (strcmp(f,"get_values") == 0) {
      
      nargchk(nlhs,4,nrhs,3);
      
      uint32_t n = mxGetScalar(prhs[2]);
      
      int16_t overflow;
      
      plhs[0] = mxCreateNumericMatrix(n,1,mxINT16_CLASS,mxREAL);
      int16_t *a = mxGetData(plhs[0]);
      plhs[1] = mxCreateNumericMatrix(n,1,mxINT16_CLASS,mxREAL);
      int16_t *b = mxGetData(plhs[1]);
      
      n = ps2000_get_values(*handle,a,b,NULL,NULL,&overflow,n);
      mxSetM(plhs[0],n);
      mxSetM(plhs[1],n);
      plhs[2] = mxCreateLogicalScalar(overflow & 0b01);
      plhs[3] = mxCreateLogicalScalar(overflow & 0b10);
      
    /* ps2000_get_streaming_last_values */
    } else if (strcmp(f,"get_streaming_last_values") == 0) {
      
      nargchk(nlhs,7,nrhs,2);
      
      uint8_t i;
      
      if (!ps2000_get_streaming_last_values(*handle,ps2000_get_overview_buffers)) {
        mexErrMsgIdAndTxt("ps2000:NoSamples","No samples available.");
      }
      
      for (i=0; i<7; i++) plhs[i] = buffer[i];
      
    } else mexErrMsgTxt("Invalid function.");
    
  }
  
}
