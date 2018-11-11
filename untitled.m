tic
parfor j=1:5
    a = rand(1e8,1);
    for i=a
        exp(i);
        sin(i);

    end
end
toc