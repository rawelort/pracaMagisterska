pointciki = [-4 -3 -2 -1 0 1 2 3 4];
sursik = [2 -2 3 4];
indi = quantiz(sursik, pointciki)
quant = zeros(1,length(indi));
for (i=indi)
    quant = pointciki(i+1)
end