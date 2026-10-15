function detail = demo_turbo_encoder()
    u=int8(mod((0:39).'+floor((0:39).'/3),2));
    [coded,detail]=turbo_encode_manual(u);
    p=detail.qpp_indices;
    fprintf('Two 8-state RSC encoders; QPP K=40, f1=3, f2=10\n');
    fprintf('i(0-based)  input  pi(i)  permuted  parity1  parity2\n');
    for k=1:12
        fprintf('%5d        %d    %3d       %d        %d        %d\n', ...
            k-1,u(k),p(k)-1,u(p(k)),detail.parity1(k),detail.parity2(k));
    end
    fprintf('RSC1 first 12 transitions: [u s1 s2 s3 v z next_s1 next_s2 next_s3]\n');
    disp(double(detail.state_trace1(1:12,:)));
    fprintf('RSC1 termination transitions (final state must be 000):\n');
    disp(double(detail.state_trace1(end-2:end,:)));
    assert(~any(detail.state_trace1(end,7:9))&&~any(detail.state_trace2(end,7:9)));
    fprintf('Last four rows of [d0 d1 d2] (12 termination bits):\n');
    disp(detail.streams(end-3:end,:));
    fprintf('Output: 3*40+12 = %d coded bits.\n',numel(coded));
end
