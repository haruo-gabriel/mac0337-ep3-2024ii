function fftrecursiva(x)

    -- partes real e imaginária da dft(x)
    local a=ofTable()
    local b=ofTable()

    -- base da recursão: se |x|=1 então X=x
    if #x==1 then
        a[1], b[1] = x[1], 0
        return a, b
    end

    -- partes par e ímpar do vetor x
    local xpar, ximpar=ofTable(), ofTable()
    -- lembre que a indexação começando em 1 embaralha um pouco as coisas...
    for n=1, #x/2 do
        xpar[n], ximpar[n]=x[2*n-1], x[2*n]
    end

    -- dfts das partes par e ímpar
    local apar, bpar = fftrecursiva(xpar)
    local aimpar, bimpar = fftrecursiva(ximpar)

    -- monta dft(x) a partir de dft(xpar) e dft(ximpar)
    -- componentes entre dc e "Nyquist-1":
    for f=1, #x/2 do
        local cos, sen=math.cos(-2*math.pi*(f-1)/#x), math.sin(-2*math.pi*(f-1)/#x)
        a[f] = apar[f]+cos*aimpar[f]-sen*bimpar[f]
        b[f] = bpar[f]+cos*bimpar[f]+sen*aimpar[f]
    end
    -- componente de Nyquist (a fórmula é a mesma, mas os vetores apar..bimpar têm tamanho N/2):
    a[#x/2+1], b[#x/2+1] = apar[1]-aimpar[1], bpar[1]-bimpar[1]
    -- transfere a segunda metade com simetria conjugada
    for f=#x/2+2, #x do
        a[f], b[f] = a[2+#x-f], -b[2+#x-f]
    end

    -- devolve dft(x)
    return a, b
end