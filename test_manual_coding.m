function summary = test_manual_coding()
rng(8301024,'twister');
assert(~isempty(which('lteTurboEncode')), 'Reference checks need LTE Toolbox.');
summary=struct('crc',0,'encoder',0,'rate_match',0,'rate_recover',0,'decoder_clean',0);
for n=[1 16 40 1000]
 for pattern=1:4
  if pattern==1,u=zeros(n,1);elseif pattern==2,u=ones(n,1);elseif pattern==3,u=mod((0:n-1).',2);else,u=randi([0 1],n,1);end
  c=crc24a_encode_manual(u);r=lteCRCEncode(int8(u),'24A');assert(isequal(c,r));
  [b,e]=crc24a_decode_manual(c);assert(~e&&isequal(b,int8(u)));
  c(1)=1-c(1);[~,e]=crc24a_decode_manual(c);assert(e);
  summary.crc=summary.crc+1;
 end
end
fprintf('CRC_PASS %d\n',summary.crc);
for K=[40 1024]
 [p,ip]=qpp_indices_manual(K);assert(isequal(sort(p),(1:K).'));assert(isequal(p(ip),(1:K).'));
 for pattern=1:12
  if pattern==1,u=zeros(K,1);elseif pattern==2,u=ones(K,1);elseif pattern==3,u=mod((0:K-1).',2);elseif pattern==4,u=zeros(K,1);u(end)=1;else,u=randi([0 1],K,1);end
  c=turbo_encode_manual(u);ref=lteTurboEncode(int8(u));assert(isequal(c,ref),'Encoder differs from Toolbox.');
  summary.encoder=summary.encoder+1;
  if pattern<=4
   for it=[3 4 6]
    d=turbo_decode_manual(20*(2*double(c)-1),it);assert(isequal(int8(d),int8(u)));
    summary.decoder_clean=summary.decoder_clean+1;
   end
  end
 end
 if K==40, gs=[40 80 120 132 200];else,gs=[1200 1500 1800 2100 3084 4000];end
 for G=gs
  for rv=0:3
   tags=(1:3*(K+4)).';expected=lteRateMatchTurbo(tags,G,rv);
   idx=turbo_rate_indices_manual(K,G,rv);assert(isequal(idx,expected),'Rate indices differ.');
   u=randi([0 1],K,1);c=turbo_encode_manual(u);
   a=turbo_rate_match_manual(c,G,rv);b=lteRateMatchTurbo(double(c),G,rv);assert(isequal(a,b));
   summary.rate_match=summary.rate_match+1;
   l=randn(G,1);a=turbo_rate_recover_manual(l,K-24,rv);b=lteRateRecoverTurbo(l,K-24,rv);
   assert(numel(a)==1&&numel(b)==1);assert(max(abs(a{1}-b{1}))<1e-10,'Rate recovery differs.');
   summary.rate_recover=summary.rate_recover+1;
  end
 end
end
fprintf('ENCODER_PASS %d RATE_MATCH_PASS %d RATE_RECOVER_PASS %d DECODER_CLEAN_PASS %d\n',summary.encoder,summary.rate_match,summary.rate_recover,summary.decoder_clean);
K=1024;G=1500;iters=[3 4 6];sigma2=0.9;packets=40;
errors=zeros(2,3);blocks=zeros(2,3);seconds=zeros(2,3);differences=zeros(1,3);
for packet=1:packets
 u=randi([0 1],1000,1);c=turbo_encode_manual(crc24a_encode_manual(u));rm=turbo_rate_match_manual(c,G,0);
 y=(2*rm-1)+sqrt(sigma2)*randn(G,1);rr=turbo_rate_recover_manual(2*y/sigma2,1000,0);
 for j=1:3
  tic;a=turbo_decode_manual(rr{1},iters(j));seconds(1,j)=seconds(1,j)+toc;
  tic;b=lteTurboDecode(rr{1},iters(j));seconds(2,j)=seconds(2,j)+toc;
  [ba,ca]=crc24a_decode_manual(a);[bb,cb]=lteCRCDecode(b,'24A');
  errors(1,j)=errors(1,j)+sum(ba~=int8(u));errors(2,j)=errors(2,j)+sum(bb~=int8(u));
  blocks(1,j)=blocks(1,j)+ca;blocks(2,j)=blocks(2,j)+(cb~=0);
  differences(j)=differences(j)+sum(int8(a)~=b);
 end
end
summary.noisy=struct('packets',packets,'sigma2',sigma2,'iterations',iters,'errors',errors,'crc_errors',blocks,'seconds',seconds,'decoder_bit_differences',differences);
assert(all(differences==0),'Noisy decoder decisions differ from the reference fixtures.');
fprintf('NOISY rows=manual,Toolbox columns=3,4,6 iterations\n');disp(summary.noisy);
fprintf('MANUAL_CODING_TEST_PASS\n');
end
