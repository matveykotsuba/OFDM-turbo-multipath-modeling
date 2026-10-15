function s=test_manual_integration()
set(0,'DefaultFigureVisible','off');rng(831,'twister');
s=struct('waveforms',0,'roundtrips',0);
for mc={'QPSK','16QAM','64QAM'}
 for R=[1/3 1/2 2/3 3/4]
  state=rng;
  [x,b,p]=tx(mc{1},R,0,struct('backend','manual','turbo_num_iter',4));
  rng(state);[xr,br,pr]=tx(mc{1},R,0,struct('backend','toolbox','turbo_num_iter',4));
  assert(isequal(x,xr)&&isequal(b,br));assert(p.rate_matched_len==pr.rate_matched_len);
  s.waveforms=s.waveforms+1;
  for ch={'awgn','TDL-A','TDL-B','TDL-C'}
   if strcmp(ch{1},'awgn'),[y,h,~,np]=channel(x,60,'awgn',p);else,[y,h,~,np]=channel(x,60,'tdl',p,ch{1},300);end
   f=ofdmDemodulate(y,p);H=fftshift(fft(h(:),p.N,1));H=H(p.active_indices);hm=repmat(H.',p.num_symbols,1);f=f./(hm+1e-12);
   q=reshape(f.',[],1);hv=reshape(hm.',[],1);sigma=np./(abs(hv).^2+1e-12);
   l=llr_maxlog(q(1:p.mod_symbol_len),p,sigma(1:p.mod_symbol_len));
   [bh,c]=decode_transport_block(l,p);assert(~c&&isequal(b,bh));
   [bh2,c2]=decode_transport_block(l,pr);assert(~c2&&isequal(b,bh2));
   s.roundtrips=s.roundtrips+1;
  end
 end
end
fprintf('WAVEFORM_PASS %d ROUNDTRIP_PASS %d\n',s.waveforms,s.roundtrips);
check_project_consistency;
opts=struct('backend','manual','turbo_num_iter',3);
if ~exist('manual-scenario-results','dir'),mkdir('manual-scenario-results');end
saved_dir=pwd;cleanup=onCleanup(@()cd(saved_dir));
cd('manual-scenario-results');
a=berRun(380,1,opts);assert(a.ofdm_params.turbo_num_iter==3&&strcmp(a.coding.backend,'manual'));assert(all(a.packets_total_tdl(:)==1));
b=rx_report_bler_graphs(1,opts);assert(b.ofdm_params.turbo_num_iter==3);assert(all(b.packets_total_mcs(:)==1));
c=rx_report_mcs_separate(300,1,opts);assert(c.ofdm_params.turbo_num_iter==3);assert(all(c.packets_total_tdl(:)==1));
s.scenarios=3;s.config=coding_config();save('integration-results.mat','a','b','c','s');
fprintf('MANUAL_INTEGRATION_PASS\n');
end
