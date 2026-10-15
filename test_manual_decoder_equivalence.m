function summary = test_manual_decoder_equivalence()
    saved=rng; restore=onCleanup(@()rng(saved));
    rng(5193, 'twister');
    count = 0; worst = 0;
    for K = [40 1024]
        N = 3*(K+4);
        for iterations = [1 4 6]
            inputs = {zeros(N,1), 50*ones(N,1), -50*ones(N,1), ...
                50*(-1).^(1:N)', 1e6*randn(N,1)};
            for scale = [.01 1 10 50]
                for rep = 1:4
                    inputs{end+1} = scale*randn(N,1);
                end
            end
            for c = 1:numel(inputs)
                difference = compare_decoders(inputs{c}, iterations);
                worst = max(worst, difference);
                count = count+1;
            end
            for rate = [1/3 1/2 2/3 3/4]
                for rv = 0:3
                    bits = randi([0 1], K, 1);
                    coded = turbo_encode_manual(bits);
                    G = ceil(K/rate);
                    matched = turbo_rate_match_manual(coded, G, rv);
                    channelLLR = 2*(2*matched-1) + 2*randn(G,1);
                    recovered = turbo_rate_recover_manual(channelLLR, K-24, rv);
                    difference = compare_decoders(recovered{1}, iterations);
                    worst = max(worst, difference);
                    count = count+1;
                end
            end
        end
    end
    fprintf('COMPARE_PASS cases=%d max_posterior_abs_difference=%.17g\n',count,worst);
    summary=struct('cases',count,'maxPosteriorDifference',worst);
end

function difference = compare_decoders(llr, iterations)
    [reference,rd] = turbo_decode_reference_manual(llr,iterations);
    [candidate,cd] = turbo_decode_manual(llr,iterations);
    assert(isequal(reference,candidate),'Decoded bits differ.');
    assert(all(isfinite(rd.posterior_llr)) && all(isfinite(cd.posterior_llr)), 'Non-finite posterior.');
    difference = max(abs(rd.posterior_llr-cd.posterior_llr));
    assert(difference <= 1e-10,'Posterior differs: %.17g',difference);
end
